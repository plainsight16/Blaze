"""
Interswitch identity-verification client.

PR 1 uses only the OAuth token endpoint plus the BVN boolean-match endpoint.
Wallet provisioning uses a different credential set and will land in a later PR.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any

import httpx

from app.config import (
    ISW_BVN_VERIFY_URL,
    ISW_CLIENT_ID,
    ISW_CLIENT_SECRET,
    ISW_TIMEOUT_SECONDS,
    ISW_TOKEN_URL,
)


class InterswitchError(RuntimeError):
    """Raised when an upstream Interswitch call fails or returns an unusable payload."""


@dataclass
class _CachedToken:
    value: str
    expires_at: datetime


_IDENTITY_TOKEN_CACHE: _CachedToken | None = None


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _token_is_live(token: _CachedToken | None) -> bool:
    if token is None:
        return False
    return token.expires_at > (_utcnow() + timedelta(seconds=30))


def _build_client() -> httpx.Client:
    timeout = httpx.Timeout(ISW_TIMEOUT_SECONDS, connect=min(ISW_TIMEOUT_SECONDS, 5.0))
    return httpx.Client(timeout=timeout, headers={"Accept": "application/json"})


def _extract_access_token(payload: dict[str, Any]) -> tuple[str, int]:
    raw_token = payload.get("access_token") or payload.get("accessToken")
    if not isinstance(raw_token, str) or not raw_token.strip():
        raise InterswitchError("Interswitch token response did not include an access token.")

    raw_expires_in = payload.get("expires_in", 300)
    try:
        expires_in = int(raw_expires_in)
    except (TypeError, ValueError):
        expires_in = 300

    return raw_token.strip(), max(expires_in, 60)


def _extract_boolean_match(payload: Any) -> bool:
    if isinstance(payload, bool):
        return payload

    if isinstance(payload, dict):
        summary = payload.get("summary")
        if isinstance(summary, dict):
            bvn_match_check = summary.get("bvn_match_check")
            if isinstance(bvn_match_check, dict):
                status_value = bvn_match_check.get("status")
                if isinstance(status_value, str):
                    normalized = status_value.strip().lower()
                    if normalized in {"exact_match", "match", "matched", "verified"}:
                        return True
                    if normalized in {"no_match", "mismatch", "failed", "unverified"}:
                        return False

                field_matches = bvn_match_check.get("fieldMatches")
                if isinstance(field_matches, dict) and field_matches:
                    bool_values = [value for value in field_matches.values() if isinstance(value, bool)]
                    if bool_values and len(bool_values) == len(field_matches):
                        return all(bool_values)

        bvn_match = payload.get("bvn_match")
        if isinstance(bvn_match, dict):
            field_matches = bvn_match.get("fieldMatches")
            if isinstance(field_matches, dict) and field_matches:
                bool_values = [value for value in field_matches.values() if isinstance(value, bool)]
                if bool_values and len(bool_values) == len(field_matches):
                    return all(bool_values)

        for key in ("matched", "isMatched", "match", "valid", "result"):
            value = payload.get(key)
            if isinstance(value, bool):
                return value
            if isinstance(value, str):
                normalized = value.strip().lower()
                if normalized in {"true", "yes", "matched"}:
                    return True
                if normalized in {"false", "no", "unmatched"}:
                    return False

        if "data" in payload:
            return _extract_boolean_match(payload["data"])

    raise InterswitchError("Unexpected BVN verification response format from Interswitch.")


def invalidate_identity_token_cache() -> None:
    global _IDENTITY_TOKEN_CACHE
    _IDENTITY_TOKEN_CACHE = None


def get_identity_access_token(*, client: httpx.Client | None = None, force_refresh: bool = False) -> str:
    global _IDENTITY_TOKEN_CACHE

    if not force_refresh and _token_is_live(_IDENTITY_TOKEN_CACHE):
        return _IDENTITY_TOKEN_CACHE.value

    owns_client = client is None
    client = client or _build_client()

    try:
        response = client.post(
            ISW_TOKEN_URL,
            auth=(ISW_CLIENT_ID, ISW_CLIENT_SECRET),
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={"grant_type": "client_credentials", "scope": "profile"},
        )
        response.raise_for_status()
        token, expires_in = _extract_access_token(response.json())
        _IDENTITY_TOKEN_CACHE = _CachedToken(
            value=token,
            expires_at=_utcnow() + timedelta(seconds=expires_in),
        )
        return token
    except httpx.TimeoutException as exc:
        raise InterswitchError("Timed out while requesting an Interswitch access token.") from exc
    except httpx.HTTPStatusError as exc:
        raise InterswitchError(
            f"Interswitch token request failed with HTTP {exc.response.status_code}."
        ) from exc
    except httpx.RequestError as exc:
        raise InterswitchError("Could not reach Interswitch token endpoint.") from exc
    finally:
        if owns_client:
            client.close()


def verify_bvn_boolean_match(first_name: str, last_name: str, bvn: str) -> bool:
    """
    Return True if Interswitch confirms the BVN belongs to the supplied names.
    """
    with _build_client() as client:
        token = get_identity_access_token(client=client)
        payload = {
            "firstName": first_name,
            "lastName": last_name,
            "bvn": bvn,
        }

        for attempt in range(2):
            try:
                response = client.post(
                    ISW_BVN_VERIFY_URL,
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Content-Type": "application/json",
                    },
                    json=payload,
                )

                if response.status_code == 401 and attempt == 0:
                    invalidate_identity_token_cache()
                    token = get_identity_access_token(client=client, force_refresh=True)
                    continue

                response.raise_for_status()
                return _extract_boolean_match(response.json())
            except httpx.TimeoutException as exc:
                raise InterswitchError("Timed out while verifying BVN with Interswitch.") from exc
            except httpx.HTTPStatusError as exc:
                raise InterswitchError(
                    f"Interswitch BVN verification failed with HTTP {exc.response.status_code}."
                ) from exc
            except httpx.RequestError as exc:
                raise InterswitchError("Could not reach Interswitch BVN verification endpoint.") from exc

    raise InterswitchError("BVN verification did not complete successfully.")
