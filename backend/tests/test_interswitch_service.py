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


from app.services.interswitch import _extract_access_token, _extract_boolean_match  # noqa: E402


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


if __name__ == "__main__":
    unittest.main()
