CREATE TABLE categories (
    id     SMALLINT PRIMARY KEY,
    code   VARCHAR(40) NOT NULL UNIQUE,
    name   VARCHAR(80) NOT NULL,
    active BOOLEAN     NOT NULL DEFAULT TRUE
);
INSERT INTO categories (id, code, name) VALUES
 (1,'ELECTRICITY','Electricity'),(2,'WATER','Water'),(3,'MEDICAL','Medical expenses'),
 (4,'EDUCATION','Education fees'),(5,'INTERNET','Internet bills'),(6,'HOUSING','Housing and rent'),
 (7,'HOUSEHOLD_SERVICES','Essential household services'),(8,'OTHER_ESSENTIAL','Other essential expenses');

CREATE TABLE payment_destinations (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type                  VARCHAR(40)  NOT NULL
                          CHECK (type IN ('BILLER_API','BILLER_ACCOUNT_VERIFIED','PLATFORM_ESCROW_PAYOUT')),
    biller_name           VARCHAR(160) NOT NULL,
    country_code          VARCHAR(2)   NOT NULL,
    account_ref_encrypted TEXT         NOT NULL,
    disclosure_text       TEXT         NOT NULL,
    status                VARCHAR(20)  NOT NULL DEFAULT 'UNVERIFIED'
                          CHECK (status IN ('UNVERIFIED','VERIFIED','REJECTED','DISABLED')),
    submitted_by          UUID REFERENCES users (id),
    verified_by           UUID REFERENCES users (id),
    verified_at           TIMESTAMPTZ,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE bills (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    applicant_id           UUID          NOT NULL REFERENCES users (id),
    category_id            SMALLINT      NOT NULL REFERENCES categories (id),
    title                  VARCHAR(160)  NOT NULL,
    description            TEXT,
    story_public           BOOLEAN       NOT NULL DEFAULT FALSE,
    amount_requested       NUMERIC(19,4) NOT NULL CHECK (amount_requested > 0),
    amount_funded          NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (amount_funded >= 0),
    currency               VARCHAR(3)    NOT NULL,
    due_date               DATE          NOT NULL,
    country_code           VARCHAR(2)    NOT NULL,
    region_id              UUID REFERENCES regions (id),
    payment_destination_id UUID REFERENCES payment_destinations (id),
    status                 VARCHAR(30)   NOT NULL DEFAULT 'PENDING_VERIFICATION'
        CHECK (status IN ('PENDING_VERIFICATION','APPROVED','REJECTED','PARTIALLY_FUNDED','FULLY_FUNDED',
                          'PAYMENT_PROCESSING','PAID','EXPIRED','CANCELLED')),
    priority_score         NUMERIC(8,5)  NOT NULL DEFAULT 0,
    version                BIGINT        NOT NULL DEFAULT 0,
    created_at             TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT chk_bills_funded_le_requested CHECK (amount_funded <= amount_requested)
);
CREATE INDEX idx_bills_status_due ON bills (status, due_date);
CREATE INDEX idx_bills_applicant ON bills (applicant_id);
CREATE INDEX idx_bills_category_status ON bills (category_id, status);
CREATE INDEX idx_bills_region_status ON bills (country_code, region_id, status);
CREATE INDEX idx_bills_open_priority ON bills (priority_score DESC) WHERE status IN ('APPROVED','PARTIALLY_FUNDED');

CREATE TABLE bill_documents (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id      UUID         NOT NULL REFERENCES bills (id) ON DELETE CASCADE,
    kind         VARCHAR(30)  NOT NULL CHECK (kind IN ('BILL','SUPPORTING','QR_EVIDENCE')),
    storage_key  VARCHAR(255) NOT NULL,
    content_type VARCHAR(80)  NOT NULL,
    size_bytes   BIGINT       NOT NULL,
    sha256       VARCHAR(64)  NOT NULL,
    phash        VARCHAR(32),
    ocr_json     JSONB,
    uploaded_by  UUID         NOT NULL REFERENCES users (id),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);
-- Deliberately NOT unique: duplicates are flagged for admin review, not rejected by a database error.
CREATE INDEX idx_bill_documents_sha256 ON bill_documents (sha256);
CREATE INDEX idx_bill_documents_phash ON bill_documents (phash);
CREATE INDEX idx_bill_documents_bill ON bill_documents (bill_id);

CREATE TABLE bill_verifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id     UUID        NOT NULL REFERENCES bills (id) ON DELETE CASCADE,
    reviewer_id UUID        NOT NULL REFERENCES users (id),
    decision    VARCHAR(20) NOT NULL CHECK (decision IN ('APPROVED','REJECTED','NEEDS_INFO')),
    checks      JSONB,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_bill_verifications_bill ON bill_verifications (bill_id);
