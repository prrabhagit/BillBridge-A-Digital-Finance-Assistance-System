-- Identity, access and regional model. VARCHAR (not CHAR) is used deliberately so Hibernate schema validation passes.

CREATE TABLE roles (
    id   SMALLINT PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO roles (id, name) VALUES (1,'APPLICANT'),(2,'DONOR'),(3,'ORGANIZATION'),(4,'ADMIN');

CREATE TABLE regions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code VARCHAR(2)   NOT NULL,
    code         VARCHAR(20)  NOT NULL,
    name         VARCHAR(120) NOT NULL,
    active       BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_regions_country_code UNIQUE (country_code, code)
);
-- Seed: Nepal's seven provinces. Other countries are added by admins via POST /api/v1/admin/regions.
INSERT INTO regions (country_code, code, name) VALUES
 ('NP','P1','Koshi'),('NP','P2','Madhesh'),('NP','P3','Bagmati'),('NP','P4','Gandaki'),
 ('NP','P5','Lumbini'),('NP','P6','Karnali'),('NP','P7','Sudurpashchim');

CREATE TABLE users (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email                 VARCHAR(254) NOT NULL,
    password_hash         VARCHAR(100) NOT NULL,
    display_name          VARCHAR(80)  NOT NULL,
    country_code          VARCHAR(2)   NOT NULL,
    currency_code         VARCHAR(3)   NOT NULL,
    region_id             UUID REFERENCES regions (id),
    status                VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE'
                          CHECK (status IN ('ACTIVE','SUSPENDED')),
    email_verified        BOOLEAN      NOT NULL DEFAULT FALSE,
    identity_status       VARCHAR(20)  NOT NULL DEFAULT 'UNVERIFIED'
                          CHECK (identity_status IN ('UNVERIFIED','PENDING','VERIFIED','REJECTED')),
    failed_login_attempts INT          NOT NULL DEFAULT 0,
    locked_until          TIMESTAMPTZ,
    version               BIGINT       NOT NULL DEFAULT 0,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_users_email_lower ON users (lower(email));
CREATE INDEX idx_users_country_region ON users (country_code, region_id);

CREATE TABLE user_roles (
    user_id UUID     NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role_id SMALLINT NOT NULL REFERENCES roles (id),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE applicant_profiles (
    user_id              UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    share_story_consent  BOOLEAN     NOT NULL DEFAULT FALSE,
    public_region_visible BOOLEAN    NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE donor_profiles (
    user_id            UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    anonymous_by_default BOOLEAN     NOT NULL DEFAULT FALSE,
    avatar_url         VARCHAR(500),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    family_id  UUID         NOT NULL,
    token_hash VARCHAR(64)  NOT NULL UNIQUE,
    user_agent VARCHAR(255),
    expires_at TIMESTAMPTZ  NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_family ON refresh_tokens (family_id);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id);

CREATE TABLE email_verification_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- National ID verification. The raw ID number is NEVER stored: only a keyed HMAC (for duplicate detection) and the last 4 characters.
CREATE TABLE identity_verifications (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID         NOT NULL REFERENCES users (id),
    country_code         VARCHAR(2)   NOT NULL,
    id_type              VARCHAR(30)  NOT NULL
                         CHECK (id_type IN ('NATIONAL_ID','CITIZENSHIP_CERTIFICATE','PASSPORT','DRIVING_LICENSE')),
    id_number_hmac       VARCHAR(64)  NOT NULL,
    id_number_last4      VARCHAR(8)   NOT NULL,
    full_name_on_id      VARCHAR(160) NOT NULL,
    document_storage_key VARCHAR(255) NOT NULL,
    status               VARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                         CHECK (status IN ('PENDING','APPROVED','REJECTED')),
    provider             VARCHAR(40)  NOT NULL DEFAULT 'MANUAL_REVIEW',
    reviewed_by          UUID REFERENCES users (id),
    reviewed_at          TIMESTAMPTZ,
    rejection_reason     VARCHAR(500),
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT now()
);
-- One approved account per real-world ID, enforced by the database (race-proof).
CREATE UNIQUE INDEX uq_identity_one_approved_per_id
    ON identity_verifications (country_code, id_type, id_number_hmac) WHERE status = 'APPROVED';
CREATE UNIQUE INDEX uq_identity_one_pending_per_user
    ON identity_verifications (user_id) WHERE status = 'PENDING';
CREATE INDEX idx_identity_status_created ON identity_verifications (status, created_at);
