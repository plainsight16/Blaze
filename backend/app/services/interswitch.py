"""
Interswitch API Integration Service.

Handles all communication with Interswitch APIs:
- OAuth2 authentication with token caching
- Merchant Wallet provisioning
- Wallet balance queries
- Wallet-to-wallet transactions
- Transaction reversals

Reference: https://docs.interswitchgroup.com/docs/merchant-wallets
"""
import logging
from datetime import datetime, timedelta
from typing import Any, Optional
from dataclasses import dataclass
from enum import Enum

import httpx

from app.config import (
    ISW_CLIENT_ID,
    ISW_CLIENT_SECRET,
    ISW_IDENTITY_BASE_URL,
    ISW_MERCHANT_CODE,
    ISW_PASSPORT_URL,
    ISW_WALLET_BASE_URL,
    ISW_QA_MERCHANT_CODE,
    ISW_QA_URL,
    ISW_QA_CLIENT_ID,
    ISW_QA_CLIENT_SECRET,
    ENVIRONMENT,
)


logger = logging.getLogger(__name__)

# Exceptions
class InterswitchError(Exception):
    """Base exception for Interswitch API errors."""

    def __init__(self, message: str, response_code: Optional[str] = None):
        self.message = message
        self.response_code = response_code
        super().__init__(message)


class InterswitchAuthError(InterswitchError):
    """Authentication failed with Interswitch."""
    pass


class InterswitchWalletError(InterswitchError):
    """Wallet operation failed."""
    pass


class InterswitchVerificationError(InterswitchError):
    """Identity verification failed."""
    pass


class InterswitchTransactionError(InterswitchError):
    """Transaction failed."""
    pass


class InterswitchInsufficientFundsError(InterswitchTransactionError):
    """Insufficient balance for transaction."""
    pass

# Response Codes
class ISWResponseCode(str, Enum):
    """Common Interswitch response codes."""
    SUCCESS = "00"
    INSUFFICIENT_FUNDS = "51"
    INVALID_ACCOUNT = "25"
    INVALID_PIN = "55"
    TRANSACTION_NOT_FOUND = "25"
    DUPLICATE_TRANSACTION = "94"
    SYSTEM_ERROR = "96"

# Data Classes
@dataclass
class ISWToken:
    """OAuth2 access token with expiry."""
    access_token: str
    token_type: str
    expires_at: datetime


@dataclass
class ISWWallet:
    """Wallet details returned from ISW."""
    wallet_id: str
    merchant_code: str
    customer_id: str
    account_number: str
    account_name: str
    bank_name: str
    bank_code: str


@dataclass
class ISWBalance:
    """Wallet balance from ISW."""
    available_balance: float
    ledger_balance: float
    currency: str


@dataclass
class ISWTransactionResult:
    """Result of a wallet transaction."""
    success: bool
    response_code: str
    response_message: str
    transaction_reference: str
    external_reference: Optional[str] = None


@dataclass
class ISWBVNVerificationResult:
    """Result of the BVN boolean-match verification."""
    matched: bool
    response_code: Optional[str]
    response_message: str
    raw_response: dict[str, Any]

# Token Cache (Thread-safe singleton)
class TokenCache:
    """
    In-memory OAuth2 token cache with automatic refresh.

    The token is refreshed 60 seconds before actual expiry to prevent
    edge cases where token expires during a request.
    """

    def __init__(self):
        self._token: Optional[ISWToken] = None

    def get(self) -> Optional[str]:
        """Get cached token if still valid."""
        if self._token and datetime.utcnow() < self._token.expires_at:
            return self._token.access_token
        return None

    def set(self, access_token: str, token_type: str, expires_in: int):
        """Cache token with calculated expiry."""
        # Refresh 60 seconds early to avoid edge cases
        expires_at = datetime.utcnow() + timedelta(seconds=expires_in - 60)
        self._token = ISWToken(
            access_token=access_token,
            token_type=token_type,
            expires_at=expires_at
        )

    def clear(self):
        """Clear cached token (force re-authentication)."""
        self._token = None


_token_cache = TokenCache()
_qa_token_cache = TokenCache()

# Authentication
async def _fetch_access_token(
    client_id: str,
    client_secret: str,
    cache: TokenCache,
    integration_name: str,
) -> str:
    """Fetch and cache an OAuth2 access token for a specific integration."""
    cached = cache.get()
    if cached:
        return cached

    logger.info("Fetching new Interswitch OAuth2 token for %s", integration_name)

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{ISW_PASSPORT_URL}/oauth/token",
                data={
                    "grant_type": "client_credentials",
                    "scope": "profile",
                },
                auth=(client_id, client_secret),
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )

            if response.status_code != 200:
                logger.error("ISW auth failed for %s: %s - %s", integration_name, response.status_code, response.text)
                raise InterswitchAuthError(
                    f"Authentication failed: {response.status_code}"
                )

            data = response.json()
            access_token = data["access_token"]
            token_type = data.get("token_type", "bearer")
            expires_in = data.get("expires_in", 3600)

            cache.set(access_token, token_type, expires_in)
            logger.info("Successfully obtained ISW access token for %s", integration_name)

            return access_token

    except httpx.RequestError as e:
        logger.error("ISW auth request failed for %s: %s", integration_name, e)
        raise InterswitchAuthError(f"Network error during authentication: {e}")


async def get_access_token() -> str:
    """Get cached OAuth token for the identity and merchant-wallet APIs."""
    return await _fetch_access_token(
        client_id=ISW_CLIENT_ID,
        client_secret=ISW_CLIENT_SECRET,
        cache=_token_cache,
        integration_name="identity",
    )


async def get_qa_access_token() -> str:
    """Get cached OAuth token for the static virtual-account API."""
    return await _fetch_access_token(
        client_id=ISW_QA_CLIENT_ID,
        client_secret=ISW_QA_CLIENT_SECRET,
        cache=_qa_token_cache,
        integration_name="static_virtual_account",
    )


async def _get_auth_headers() -> dict:
    """Build headers with Bearer token for ISW API calls."""
    token = await get_access_token()
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

async def _get_qa_auth_headers() -> dict:
    """Build headers with Bearer token for ISW API calls."""
    token = await get_qa_access_token()
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

# Response Parsing Helpers
def _find_first_value(payload: Any, keys: set[str]) -> Any | None:
    """Recursively search a payload for the first matching key."""
    if isinstance(payload, dict):
        for key, value in payload.items():
            if key in keys and value is not None:
                return value
        for value in payload.values():
            found = _find_first_value(value, keys)
            if found is not None:
                return found

    if isinstance(payload, list):
        for item in payload:
            found = _find_first_value(item, keys)
            if found is not None:
                return found

    return None


def _get_nested_value(payload: Any, path: tuple[str, ...]) -> Any | None:
    """Safely traverse a nested dict path."""
    current = payload
    for key in path:
        if not isinstance(current, dict) or key not in current:
            return None
        current = current[key]
    return current


def _normalize_bool(value: Any) -> Optional[bool]:
    """Normalize common boolean representations from third-party APIs."""
    if isinstance(value, bool):
        return value

    if isinstance(value, (int, float)) and value in (0, 1):
        return bool(value)

    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized in {"true", "yes", "y", "1", "matched"}:
            return True
        if normalized in {"false", "no", "n", "0", "mismatch", "not_matched"}:
            return False

    return None


def _infer_match_from_message(message: str) -> Optional[bool]:
    """Use response text as a last-resort signal for boolean match results."""
    normalized = message.strip().lower()

    negative_markers = (
        "does not match",
        "do not match",
        "not match",
        "no match",
        "mismatch",
    )
    if any(marker in normalized for marker in negative_markers):
        return False

    positive_markers = (
        "matched",
        "match successful",
        "match found",
        "verified successfully",
    )
    if any(marker in normalized for marker in positive_markers):
        return True

    return None


def _extract_response_code(payload: dict[str, Any]) -> Optional[str]:
    value = _find_first_value(payload, {"responseCode", "response_code", "code"})
    return str(value) if value is not None else None


def _extract_response_message(payload: dict[str, Any]) -> Optional[str]:
    value = _find_first_value(
        payload,
        {"responseMessage", "response_message", "message", "description"},
    )
    return str(value) if value is not None else None


def _extract_bvn_match(payload: dict[str, Any]) -> Optional[bool]:
    # Prefer explicit BVN name-match signals over generic `match` keys.
    # Interswitch returns `metadata.match=false` even when the BVN field
    # matches succeed, so recursive lookup on `match` is too broad.
    field_match_paths = (
        ("data", "summary", "bvn_match_check", "fieldMatches"),
        ("summary", "bvn_match_check", "fieldMatches"),
        ("data", "bvn_match", "fieldMatches"),
        ("bvn_match", "fieldMatches"),
    )
    for path in field_match_paths:
        field_matches = _get_nested_value(payload, path)
        if not isinstance(field_matches, dict):
            continue

        relevant_values = []
        for key in ("firstname", "lastname", "firstName", "lastName"):
            normalized = _normalize_bool(field_matches.get(key))
            if normalized is not None:
                relevant_values.append(normalized)

        if relevant_values:
            return all(relevant_values)

    status_paths = (
        ("data", "summary", "bvn_match_check", "status"),
        ("summary", "bvn_match_check", "status"),
    )
    for path in status_paths:
        status_value = _get_nested_value(payload, path)
        if not isinstance(status_value, str):
            continue

        normalized_status = status_value.strip().lower()
        if normalized_status in {"exact_match", "matched", "match_successful"}:
            return True
        if normalized_status in {"no_match", "mismatch", "not_matched"}:
            return False

    value = _find_first_value(
        payload,
        {
            "matched",
            "isMatch",
            "isMatched",
            "bvnMatch",
            "bvnMatched",
            "isBvnMatch",
        },
    )
    normalized = _normalize_bool(value)
    if normalized is not None:
        return normalized

    for path in (("match",), ("data", "match"), ("result", "match")):
        normalized = _normalize_bool(_get_nested_value(payload, path))
        if normalized is not None:
            return normalized

    return None

# Identity Verification
async def verify_bvn_boolean_match(
    first_name: str,
    last_name: str,
    bvn: str,
) -> ISWBVNVerificationResult:
    """
    Verify that a BVN belongs to the supplied first and last name.

    Endpoint:
    POST /api/v1/verify/identity/bvn
    """
    headers = await _get_auth_headers()
    payload = {
        "firstName": first_name,
        "lastName": last_name,
        "bvn": bvn,
    }

    logger.info("Calling Interswitch BVN boolean-match verification")

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{ISW_IDENTITY_BASE_URL}/api/v1/verify/identity/bvn",
                json=payload,
                headers=headers,
            )
    except httpx.RequestError as e:
        logger.error(f"BVN verification request failed: {e}")
        raise InterswitchVerificationError(f"Network error during BVN verification: {e}")

    try:
        data = response.json()
        if not isinstance(data, dict):
            data = {"data": data}
    except ValueError:
        data = {"message": response.text.strip() or "Invalid response from BVN verification"}

    response_code = _extract_response_code(data)
    response_message = _extract_response_message(data) or "BVN verification failed"
    matched = _extract_bvn_match(data)
    if matched is None:
        matched = _infer_match_from_message(response_message)

    if response.status_code in (401, 403):
        logger.error(
            "BVN verification auth failed: status=%s response_code=%s",
            response.status_code,
            response_code,
        )
        raise InterswitchAuthError(response_message, response_code)

    if response.status_code >= 500:
        logger.error(
            "BVN verification upstream error: status=%s response_code=%s",
            response.status_code,
            response_code,
        )
        raise InterswitchVerificationError(response_message, response_code)

    if matched is None and response.status_code >= 400:
        logger.error(
            "BVN verification failed: status=%s response_code=%s",
            response.status_code,
            response_code,
        )
        raise InterswitchVerificationError(response_message, response_code)

    if matched is None:
        logger.error(
            "Unable to determine BVN match result: status=%s response_code=%s",
            response.status_code,
            response_code,
        )
        raise InterswitchVerificationError(
            "Unable to determine BVN verification result from Interswitch response",
            response_code,
        )

    return ISWBVNVerificationResult(
        matched=matched,
        response_code=response_code,
        response_message=response_message,
        raw_response=data,
    )

# Wallet Provisioning
async def create_wallet(
    account_name: str,
    customer_id: str,
) -> ISWWallet:
    """
    Create a static virtual account for a customer.

    Endpoint:
    POST /api/v1/payable/virtualaccount

    Args:
        account_name: Name attached to the generated account
        customer_id: Unique customer identifier (user.id or group.id)

    Returns:
        ISWWallet with static virtual-account details

    Raises:
        InterswitchWalletError: If account creation fails
    """
    headers = await _get_qa_auth_headers()
    normalized_account_name = " ".join(account_name.split()).strip()
    if not normalized_account_name:
        raise InterswitchWalletError("Account name is required for virtual account creation")

    payload = {
        "accountName": normalized_account_name,
        "merchantCode": ISW_QA_MERCHANT_CODE,
    }

    logger.info("Creating static virtual account for customer: %s", customer_id)

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{ISW_QA_URL}/api/v1/payable/virtualaccount",
                json=payload,
                headers=headers,
            )

            data = response.json()
            if not isinstance(data, dict):
                raise InterswitchWalletError("Invalid response from virtual account API")

            if response.status_code not in (200, 201):
                logger.error("Virtual account creation failed: %s", data)
                raise InterswitchWalletError(
                    _extract_response_message(data) or "Virtual account creation failed",
                    _extract_response_code(data),
                )

            payable_code = data.get("payableCode")
            account_number = data.get("accountNumber")
            if not payable_code or not account_number:
                logger.error("Virtual account creation returned incomplete payload: %s", data)
                raise InterswitchWalletError("Virtual account response missing account details")

            logger.info("Static virtual account created successfully: %s", payable_code)

            return ISWWallet(
                wallet_id=str(payable_code),
                merchant_code=str(data.get("merchantCode", ISW_QA_MERCHANT_CODE)),
                customer_id=data.get("customerId", customer_id),
                account_number=str(account_number),
                account_name=str(data.get("accountName", normalized_account_name)),
                bank_name=data.get("bankName", "Wema Bank"),
                bank_code=data.get("bankCode", "WEMA"),
            )

    except httpx.RequestError as e:
        logger.error("Virtual account creation request failed: %s", e)
        raise InterswitchWalletError(f"Network error: {e}")

# Balance Query
async def get_wallet_balance(wallet_id: str) -> ISWBalance:
    """
    Query wallet balance from Interswitch.

    This is the authoritative source of truth for balances.
    Do NOT cache this value.

    Args:
        wallet_id: The ISW wallet ID

    Returns:
        ISWBalance with available and ledger balances

    Raises:
        InterswitchWalletError: If balance query fails
    """
    headers = await _get_auth_headers()

    logger.debug(f"Querying balance for wallet: {wallet_id}")

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.get(
                f"{ISW_WALLET_BASE_URL}/api/v1/wallet/balance/{ISW_MERCHANT_CODE}",
                params={"walletId": wallet_id},
                headers=headers,
            )

            data = response.json()

            if response.status_code != 200:
                logger.error(f"Balance query failed: {data}")
                raise InterswitchWalletError(
                    data.get("responseMessage", "Balance query failed"),
                    data.get("responseCode")
                )

            # ISW returns amounts in kobo (minor units), convert to naira
            available = float(data.get("availableBalance", 0)) / 100
            ledger = float(data.get("ledgerBalance", 0)) / 100

            return ISWBalance(
                available_balance=available,
                ledger_balance=ledger,
                currency=data.get("currency", "NGN"),
            )

    except httpx.RequestError as e:
        logger.error(f"Balance query request failed: {e}")
        raise InterswitchWalletError(f"Network error: {e}")

# Wallet Transactions
async def debit_wallet(
    wallet_id: str,
    amount: float,
    pin: str,
    transaction_ref: str,
    narration: str,
) -> ISWTransactionResult:
    """
    Debit (withdraw from) a wallet.

    This requires the wallet PIN for authorization.

    Args:
        wallet_id: The ISW wallet ID to debit
        amount: Amount in Naira (will be converted to kobo)
        pin: Wallet PIN for authorization
        transaction_ref: Unique reference for this transaction
        narration: Description of the transaction

    Returns:
        ISWTransactionResult with success status and references

    Raises:
        InterswitchTransactionError: If debit fails
        InterswitchInsufficientFundsError: If balance is insufficient
    """
    headers = await _get_auth_headers()

    # Convert to kobo (ISW minor units)
    amount_kobo = int(amount * 100)

    payload = {
        "merchantCode": ISW_MERCHANT_CODE,
        "walletId": wallet_id,
        "amount": amount_kobo,
        "pin": pin,
        "transactionRef": transaction_ref,
        "narration": narration,
        "transactionType": "DEBIT",
    }

    logger.info(f"Debiting wallet {wallet_id}: {amount} NGN, ref: {transaction_ref}")

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{ISW_WALLET_BASE_URL}/api/v1/transaction/transact",
                json=payload,
                headers=headers,
            )

            data = response.json()
            response_code = data.get("responseCode", "")
            response_message = data.get("responseMessage", "Unknown error")

            result = ISWTransactionResult(
                success=response_code == ISWResponseCode.SUCCESS,
                response_code=response_code,
                response_message=response_message,
                transaction_reference=transaction_ref,
                external_reference=data.get("externalReference"),
            )

            if response_code == ISWResponseCode.INSUFFICIENT_FUNDS:
                logger.warning(f"Insufficient funds for debit: {wallet_id}")
                raise InterswitchInsufficientFundsError(
                    "Insufficient wallet balance",
                    response_code
                )

            if not result.success:
                logger.error(f"Debit failed: {response_code} - {response_message}")
                raise InterswitchTransactionError(response_message, response_code)

            logger.info(f"Debit successful: {transaction_ref}")
            return result

    except httpx.RequestError as e:
        logger.error(f"Debit request failed: {e}")
        raise InterswitchTransactionError(f"Network error: {e}")


async def credit_wallet(
    wallet_id: str,
    amount: float,
    transaction_ref: str,
    narration: str,
) -> ISWTransactionResult:
    """
    Credit (deposit to) a wallet.

    Credits typically don't require PIN authorization.

    Args:
        wallet_id: The ISW wallet ID to credit
        amount: Amount in Naira (will be converted to kobo)
        transaction_ref: Unique reference for this transaction
        narration: Description of the transaction

    Returns:
        ISWTransactionResult with success status and references

    Raises:
        InterswitchTransactionError: If credit fails
    """
    headers = await _get_auth_headers()

    # Convert to kobo (ISW minor units)
    amount_kobo = int(amount * 100)

    payload = {
        "merchantCode": ISW_MERCHANT_CODE,
        "walletId": wallet_id,
        "amount": amount_kobo,
        "transactionRef": transaction_ref,
        "narration": narration,
        "transactionType": "CREDIT",
    }

    logger.info(f"Crediting wallet {wallet_id}: {amount} NGN, ref: {transaction_ref}")

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{ISW_WALLET_BASE_URL}/api/v1/transaction/transact",
                json=payload,
                headers=headers,
            )

            data = response.json()
            response_code = data.get("responseCode", "")
            response_message = data.get("responseMessage", "Unknown error")

            result = ISWTransactionResult(
                success=response_code == ISWResponseCode.SUCCESS,
                response_code=response_code,
                response_message=response_message,
                transaction_reference=transaction_ref,
                external_reference=data.get("externalReference"),
            )

            if not result.success:
                logger.error(f"Credit failed: {response_code} - {response_message}")
                raise InterswitchTransactionError(response_message, response_code)

            logger.info(f"Credit successful: {transaction_ref}")
            return result

    except httpx.RequestError as e:
        logger.error(f"Credit request failed: {e}")
        raise InterswitchTransactionError(f"Network error: {e}")

# Transaction Reversal
async def reverse_transaction(
    original_reference: str,
    reversal_reference: str,
) -> ISWTransactionResult:
    """
    Reverse a previously completed transaction.

    Use this to undo a transaction that should not have happened,
    such as when a credit fails after a debit succeeds.

    Args:
        original_reference: Reference of the transaction to reverse
        reversal_reference: Unique reference for this reversal

    Returns:
        ISWTransactionResult with success status

    Raises:
        InterswitchTransactionError: If reversal fails
    """
    headers = await _get_auth_headers()

    payload = {
        "merchantCode": ISW_MERCHANT_CODE,
        "originalTransactionRef": original_reference,
        "reversalTransactionRef": reversal_reference,
    }

    logger.info(f"Reversing transaction: {original_reference}")

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{ISW_WALLET_BASE_URL}/api/v1/transaction/reverse",
                json=payload,
                headers=headers,
            )

            data = response.json()
            response_code = data.get("responseCode", "")
            response_message = data.get("responseMessage", "Unknown error")

            result = ISWTransactionResult(
                success=response_code == ISWResponseCode.SUCCESS,
                response_code=response_code,
                response_message=response_message,
                transaction_reference=reversal_reference,
            )

            if not result.success:
                logger.error(f"Reversal failed: {response_code} - {response_message}")
                raise InterswitchTransactionError(
                    f"Reversal failed: {response_message}",
                    response_code
                )

            logger.info(f"Reversal successful: {reversal_reference}")
            return result

    except httpx.RequestError as e:
        logger.error(f"Reversal request failed: {e}")
        raise InterswitchTransactionError(f"Network error: {e}")

# Transaction Status Query
async def get_transaction_status(reference: str) -> ISWTransactionResult:
    """
    Query the status of a transaction.

    Use this to verify transaction status before retrying,
    to avoid duplicate transactions.

    Args:
        reference: Transaction reference to query

    Returns:
        ISWTransactionResult with current status

    Raises:
        InterswitchTransactionError: If query fails
    """
    headers = await _get_auth_headers()

    logger.debug(f"Querying transaction status: {reference}")

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.get(
                f"{ISW_WALLET_BASE_URL}/api/v1/transaction/",
                params={
                    "merchantCode": ISW_MERCHANT_CODE,
                    "reference": reference,
                },
                headers=headers,
            )

            data = response.json()
            response_code = data.get("responseCode", "")
            response_message = data.get("responseMessage", "Unknown")

            return ISWTransactionResult(
                success=response_code == ISWResponseCode.SUCCESS,
                response_code=response_code,
                response_message=response_message,
                transaction_reference=reference,
                external_reference=data.get("externalReference"),
            )

    except httpx.RequestError as e:
        logger.error(f"Transaction status query failed: {e}")
        raise InterswitchTransactionError(f"Network error: {e}")

# Health Check
async def health_check() -> bool:
    """
    Check if Interswitch API is accessible.

    Returns:
        True if ISW is reachable and authentication works
    """
    try:
        await get_access_token()
        return True
    except InterswitchError:
        return False
