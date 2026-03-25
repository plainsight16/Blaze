from sqlalchemy import Boolean, Column, DateTime, String
from sqlalchemy.orm import relationship
from app.database import Base


class User(Base):
    """
    User account model.

    Lifecycle:
    1. Register (email unverified)
    2. Verify email (verified_at set)
    3. Complete KYC (bvn_verified=True, wallet provisioned)
    4. Ready for groups/contributions
    """
    __tablename__ = "users"

    # Identity
    id            = Column(String, primary_key=True)
    email         = Column(String, unique=True, nullable=False, index=True)
    username      = Column(String, unique=True, nullable=False)
    first_name    = Column(String, nullable=False)
    last_name     = Column(String, nullable=False)
    password_hash = Column(String, nullable=False)

    # Contact
    phone_number  = Column(String(20), unique=True, nullable=True, index=True)

    # Account Status
    is_active     = Column(Boolean, nullable=False, default=True)
    verified_at   = Column(DateTime(timezone=True), nullable=True)  # Email verified
    created_at    = Column(DateTime(timezone=True), nullable=False)

    # KYC (Know Your Customer)
    bvn_verified     = Column(Boolean, nullable=False, default=False)
    bvn_hash         = Column(String(64), nullable=True)  # SHA-256 hash, never store raw BVN
    kyc_completed_at = Column(DateTime(timezone=True), nullable=True)

    # Interswitch Wallet
    isw_wallet_id         = Column(String(50), nullable=True, index=True)
    isw_merchant_code     = Column(String(20), nullable=True)
    isw_virtual_acct_no   = Column(String(20), nullable=True)  # Wema Bank virtual account
    isw_virtual_acct_bank = Column(String(50), nullable=True)
    wallet_pin_encrypted  = Column(String(255), nullable=True)  # AES-256 encrypted

    # Relationships
    wallet_transactions = relationship(
        "WalletTransaction",
        primaryjoin="and_(User.id == foreign(WalletTransaction.wallet_owner_id), "
                    "WalletTransaction.wallet_owner_type == 'user')",
        viewonly=True
    )

    # Helper Properties
    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"

    @property
    def has_wallet(self) -> bool:
        return self.isw_wallet_id is not None

    @property
    def kyc_complete(self) -> bool:
        return self.bvn_verified and self.has_wallet
