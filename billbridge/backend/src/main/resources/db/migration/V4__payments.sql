CREATE TABLE donations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id         UUID          NOT NULL REFERENCES bills (id),
    donor_id        UUID          NOT NULL REFERENCES users (id),
    organization_id UUID REFERENCES organizations (id),
    campaign_id     UUID REFERENCES campaigns (id),
    amount          NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    currency        VARCHAR(3)    NOT NULL,
    anonymous       BOOLEAN       NOT NULL DEFAULT FALSE,
    status          VARCHAR(30)   NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','CONFIRMED','FAILED','EXPIRED','REFUNDED','PARTIALLY_REFUNDED')),
    gateway         VARCHAR(30),
    idempotency_key VARCHAR(80)   NOT NULL,
    expires_at      TIMESTAMPTZ,
    version         BIGINT        NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    -- Scoped per donor so one user's key can never collide with (or probe) another's.
    CONSTRAINT uq_donations_donor_idempotency UNIQUE (donor_id, idempotency_key)
);
CREATE INDEX idx_donations_bill_status ON donations (bill_id, status);
CREATE INDEX idx_donations_donor ON donations (donor_id, created_at DESC);

CREATE TABLE transactions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donation_id  UUID          NOT NULL REFERENCES donations (id),
    gateway      VARCHAR(30)   NOT NULL,
    gateway_ref  VARCHAR(120),
    amount       NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    currency     VARCHAR(3)    NOT NULL,
    status       VARCHAR(20)   NOT NULL DEFAULT 'INITIATED'
                 CHECK (status IN ('INITIATED','PENDING','SUCCEEDED','FAILED','REFUNDED')),
    raw_response JSONB,
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT uq_transactions_gateway_ref UNIQUE (gateway, gateway_ref)
);
CREATE INDEX idx_transactions_donation ON transactions (donation_id);

CREATE TABLE refunds (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID          NOT NULL REFERENCES transactions (id),
    amount         NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    reason         VARCHAR(500)  NOT NULL,
    status         VARCHAR(20)   NOT NULL DEFAULT 'REQUESTED'
                   CHECK (status IN ('REQUESTED','APPROVED','REJECTED','COMPLETED','FAILED')),
    requested_by   UUID          NOT NULL REFERENCES users (id),
    approved_by    UUID REFERENCES users (id),
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    -- Dual control: whoever requests a refund cannot also approve it.
    CONSTRAINT chk_refund_dual_control CHECK (approved_by IS NULL OR approved_by <> requested_by)
);

CREATE TABLE ledger_entries (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id        UUID          NOT NULL REFERENCES bills (id),
    donation_id    UUID REFERENCES donations (id),
    transaction_id UUID REFERENCES transactions (id),
    entry_type     VARCHAR(20)   NOT NULL CHECK (entry_type IN ('CONTRIBUTION','REFUND','PAYOUT')),
    amount         NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    currency       VARCHAR(3)    NOT NULL,
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX idx_ledger_bill ON ledger_entries (bill_id);

CREATE TABLE webhook_events (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gateway          VARCHAR(30)  NOT NULL,
    gateway_event_id VARCHAR(120) NOT NULL,
    signature_valid  BOOLEAN      NOT NULL,
    payload          JSONB        NOT NULL,
    processed_at     TIMESTAMPTZ,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_webhook_gateway_event UNIQUE (gateway, gateway_event_id)
);

CREATE TABLE campaign_contributions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID          NOT NULL REFERENCES campaigns (id),
    donation_id UUID          NOT NULL UNIQUE REFERENCES donations (id),
    amount      NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- Append-only guard shared by the ledger and the audit log.
CREATE FUNCTION forbid_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION '% on % is not allowed: table is append-only', TG_OP, TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ledger_append_only BEFORE UPDATE OR DELETE ON ledger_entries
    FOR EACH ROW EXECUTE FUNCTION forbid_mutation();
