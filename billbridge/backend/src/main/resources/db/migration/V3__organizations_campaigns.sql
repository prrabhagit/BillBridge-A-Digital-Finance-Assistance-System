CREATE TABLE organizations (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(160) NOT NULL,
    legal_name   VARCHAR(200),
    country_code VARCHAR(2)   NOT NULL,
    website      VARCHAR(300),
    status       VARCHAR(20)  NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','VERIFIED','SUSPENDED')),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE TABLE organization_members (
    organization_id UUID        NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    member_role     VARCHAR(20) NOT NULL DEFAULT 'MEMBER' CHECK (member_role IN ('OWNER','MEMBER')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (organization_id, user_id)
);

CREATE TABLE campaigns (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id         UUID          NOT NULL REFERENCES users (id),
    organization_id    UUID REFERENCES organizations (id),
    category_id        SMALLINT REFERENCES categories (id),
    title              VARCHAR(200)  NOT NULL,
    description        TEXT          NOT NULL,
    target_amount      NUMERIC(19,4) NOT NULL CHECK (target_amount > 0),
    current_amount     NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    currency           VARCHAR(3)    NOT NULL,
    beneficiary_target INT           NOT NULL DEFAULT 0 CHECK (beneficiary_target >= 0),
    deadline           DATE,
    status             VARCHAR(20)   NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','ACTIVE','COMPLETED','CANCELLED')),
    matching_enabled   BOOLEAN       NOT NULL DEFAULT FALSE,
    matching_ratio     NUMERIC(4,2),
    matching_cap       NUMERIC(19,4),
    version            BIGINT        NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX idx_campaigns_status_deadline ON campaigns (status, deadline);

CREATE TABLE campaign_bills (
    campaign_id UUID NOT NULL REFERENCES campaigns (id) ON DELETE CASCADE,
    bill_id     UUID NOT NULL REFERENCES bills (id),
    PRIMARY KEY (campaign_id, bill_id)
);
