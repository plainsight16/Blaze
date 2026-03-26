import os
import unittest


for key, value in {
    "DATABASE_URL": "sqlite://",
    "SECRET_KEY": "test-secret",
    "BVN_SALT": "test-bvn-salt",
    "SMTP_HOST": "smtp.example.com",
    "SMTP_PORT": "587",
    "SMTP_USER": "user@example.com",
    "SMTP_PASS": "password",
    "ISW_CLIENT_ID": "client-id",
    "ISW_CLIENT_SECRET": "client-secret",
}.items():
    os.environ.setdefault(key, value)


from app.services.interswitch import (  # noqa: E402
    _extract_access_token,
    _extract_boolean_match,
    _extract_virtual_account,
)


class InterswitchServiceTests(unittest.TestCase):
    def test_extract_access_token_supports_oauth_shape(self) -> None:
        token, expires_in = _extract_access_token(
            {
                "access_token": "abc123",
                "expires_in": 3600,
            }
        )
        self.assertEqual(token, "abc123")
        self.assertEqual(expires_in, 3600)

    def test_extract_boolean_match_supports_nested_data_boolean(self) -> None:
        self.assertTrue(_extract_boolean_match({"data": True}))

    def test_extract_boolean_match_supports_named_fields(self) -> None:
        self.assertFalse(_extract_boolean_match({"matched": False}))
        self.assertTrue(_extract_boolean_match({"data": {"isMatched": True}}))

    def test_extract_boolean_match_supports_live_interswitch_shape(self) -> None:
        payload = {
            "success": True,
            "code": "200",
            "message": "request processed successfully",
            "data": {
                "summary": {
                    "bvn_match_check": {
                        "status": "EXACT_MATCH",
                        "fieldMatches": {
                            "firstname": True,
                            "lastname": True,
                        },
                    }
                },
                "status": {
                    "state": "complete",
                    "status": "verified",
                },
            },
        }
        self.assertTrue(_extract_boolean_match(payload))

    def test_extract_virtual_account_supports_live_interswitch_shape(self) -> None:
        payload = {
            "id": 404102,
            "merchantCode": "MX276203",
            "payableCode": "VIRTUAL_ACCOUNTMX2762031774566874219",
            "accountName": "Codex Smoke be0bb15a",
            "accountNumber": "7620601622",
            "payableExpressionId": 404102,
            "bankName": "Wema Bank",
            "bankCode": "WEMA",
        }
        account = _extract_virtual_account(payload)
        self.assertEqual(account.provider_wallet_id, "404102")
        self.assertEqual(account.provider_reference, "VIRTUAL_ACCOUNTMX2762031774566874219")
        self.assertEqual(account.account_number, "7620601622")
        self.assertEqual(account.bank_code, "WEMA")


if __name__ == "__main__":
    unittest.main()
