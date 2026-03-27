-- Blaze Database Schema
-- Generated from SQLAlchemy models in backend/app/models/
-- PostgreSQL-compatible DDL

-- ============================================================================
-- DROP TABLES (reverse dependency order for clean re-runs)
-- ============================================================================

DROP TABLE IF EXISTS insurance_wallets CASCADE;
DROP TABLE IF EXISTS cycle_contributions CASCADE;
DROP TABLE IF EXISTS cycle_slots CASCADE;
DROP TABLE IF EXISTS cycles CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;
DROP TABLE IF EXISTS refresh_tokens CASCADE;
DROP TABLE IF EXISTS otp_codes CASCADE;
DROP TABLE IF EXISTS bank_statements CASCADE;
DROP TABLE IF EXISTS kyc CASCADE;
DROP TABLE IF EXISTS group_requests CASCADE;
DROP TABLE IF EXISTS user_groups CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS users CASCADE;

DROP TYPE IF EXISTS otp_purpose CASCADE;

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

CREATE TYPE otp_purpose AS ENUM ('email_verification', 'password_reset');

-- ============================================================================
-- TABLE: users
-- ============================================================================

CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX ix_users_email ON users(email);

-- ============================================================================
-- TABLE: groups
-- ============================================================================

CREATE TABLE groups (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(1000),
    type VARCHAR(50) NOT NULL DEFAULT 'public',
    owner_id VARCHAR(36) REFERENCES users(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    monthly_con INTEGER NOT NULL DEFAULT 1000
);

CREATE INDEX ix_groups_name ON groups(name);
CREATE INDEX ix_groups_owner_id ON groups(owner_id);

-- ============================================================================
-- TABLE: user_groups (join table)
-- Note: frozen_until_cycle_id FK added after cycles table is created
-- ============================================================================

CREATE TABLE user_groups (
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id VARCHAR(36) NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_frozen BOOLEAN NOT NULL DEFAULT FALSE,
    frozen_until_cycle_id VARCHAR(36),
    PRIMARY KEY (user_id, group_id)
);

-- ============================================================================
-- TABLE: group_requests
-- ============================================================================

CREATE TABLE group_requests (
    id VARCHAR(36) PRIMARY KEY,
    group_id VARCHAR(36) NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    initiated_by VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    direction VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_group_request_pair UNIQUE (group_id, user_id)
);

CREATE INDEX ix_group_requests_group_id ON group_requests(group_id);
CREATE INDEX ix_group_requests_user_id ON group_requests(user_id);

-- ============================================================================
-- TABLE: kyc
-- ============================================================================

CREATE TABLE kyc (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    bvn_hash VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending'
);

CREATE INDEX ix_kyc_user_id ON kyc(user_id);

-- ============================================================================
-- TABLE: bank_statements
-- ============================================================================

CREATE TABLE bank_statements (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    kyc_id VARCHAR(36) NOT NULL UNIQUE REFERENCES kyc(id) ON DELETE CASCADE,
    average_balance FLOAT NOT NULL,
    total_credit FLOAT NOT NULL,
    total_debit FLOAT NOT NULL,
    raw_data JSONB NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX ix_bank_statements_user_id ON bank_statements(user_id);

-- ============================================================================
-- TABLE: otp_codes
-- ============================================================================

CREATE TABLE otp_codes (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    purpose otp_purpose NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX ix_otp_codes_user_id ON otp_codes(user_id);

-- ============================================================================
-- TABLE: refresh_tokens
-- ============================================================================

CREATE TABLE refresh_tokens (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX ix_refresh_tokens_user_id ON refresh_tokens(user_id);

-- ============================================================================
-- TABLE: wallets
-- ============================================================================

CREATE TABLE wallets (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    group_id VARCHAR(36) UNIQUE REFERENCES groups(id) ON DELETE CASCADE,
    provider VARCHAR(100) NOT NULL DEFAULT 'interswitch',
    provider_wallet_id VARCHAR(255) UNIQUE,
    provider_reference VARCHAR(255) UNIQUE,
    account_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(50) UNIQUE,
    bank_name VARCHAR(255),
    bank_code VARCHAR(50),
    amount FLOAT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    failure_reason VARCHAR(500),
    provisioned_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX ix_wallets_user_id ON wallets(user_id);
CREATE INDEX ix_wallets_group_id ON wallets(group_id);

-- ============================================================================
-- TABLE: transactions
-- ============================================================================

CREATE TABLE transactions (
    id VARCHAR(36) PRIMARY KEY,
    wallet_id VARCHAR(36) NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    amount FLOAT NOT NULL,
    reference VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(500),
    status VARCHAR(50) NOT NULL DEFAULT 'success',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX ix_transactions_wallet_id ON transactions(wallet_id);

-- ============================================================================
-- TABLE: cycles
-- ============================================================================

CREATE TABLE cycles (
    id VARCHAR(36) PRIMARY KEY,
    group_id VARCHAR(36) NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    frequency VARCHAR(50) NOT NULL,
    max_reduction_pct FLOAT NOT NULL DEFAULT 25.0,
    contribution_amount FLOAT NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX ix_cycles_group_id ON cycles(group_id);

-- ============================================================================
-- TABLE: cycle_slots
-- ============================================================================

CREATE TABLE cycle_slots (
    id VARCHAR(36) PRIMARY KEY,
    cycle_id VARCHAR(36) NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    reduction_pct FLOAT NOT NULL,
    insurance_amount FLOAT NOT NULL DEFAULT 0.0,
    payout_amount FLOAT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_cycle_slot_user UNIQUE (cycle_id, user_id),
    CONSTRAINT uq_cycle_slot_position UNIQUE (cycle_id, position)
);

CREATE INDEX ix_cycle_slots_cycle_id ON cycle_slots(cycle_id);

-- ============================================================================
-- TABLE: cycle_contributions
-- ============================================================================

CREATE TABLE cycle_contributions (
    id VARCHAR(36) PRIMARY KEY,
    slot_id VARCHAR(36) NOT NULL REFERENCES cycle_slots(id) ON DELETE CASCADE,
    contributor_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount FLOAT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'collected',
    collected_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_contribution_slot_member UNIQUE (slot_id, contributor_id)
);

CREATE INDEX ix_cycle_contributions_slot_id ON cycle_contributions(slot_id);

-- ============================================================================
-- TABLE: insurance_wallets
-- ============================================================================

CREATE TABLE insurance_wallets (
    id VARCHAR(36) PRIMARY KEY,
    cycle_id VARCHAR(36) NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance FLOAT NOT NULL DEFAULT 0.0,
    status VARCHAR(50) NOT NULL DEFAULT 'holding',
    CONSTRAINT uq_insurance_cycle_user UNIQUE (cycle_id, user_id)
);

CREATE INDEX ix_insurance_wallets_cycle_id ON insurance_wallets(cycle_id);

-- ============================================================================
-- DEFERRED FOREIGN KEY: user_groups.frozen_until_cycle_id -> cycles.id
-- (Added after cycles table exists to resolve circular dependency)
-- ============================================================================

ALTER TABLE user_groups
    ADD CONSTRAINT fk_user_groups_frozen_until_cycle
    FOREIGN KEY (frozen_until_cycle_id) REFERENCES cycles(id) ON DELETE SET NULL;
