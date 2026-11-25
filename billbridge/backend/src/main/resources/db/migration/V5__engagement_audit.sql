CREATE TABLE notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    type       VARCHAR(50)  NOT NULL,
    title      VARCHAR(200) NOT NULL,
    body       TEXT,
    data       JSONB,
    read_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user ON notifications (user_id, read_at, created_at DESC);

CREATE TABLE reports (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id    UUID        NOT NULL REFERENCES users (id),
    bill_id        UUID REFERENCES bills (id),
    target_user_id UUID REFERENCES users (id),
    reason         VARCHAR(40) NOT NULL,
    details        TEXT,
    status         VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','UNDER_REVIEW','RESOLVED','DISMISSED')),
    resolved_by    UUID REFERENCES users (id),
    resolved_at    TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_report_has_target CHECK (bill_id IS NOT NULL OR target_user_id IS NOT NULL)
);
CREATE INDEX idx_reports_status ON reports (status, created_at);

CREATE TABLE achievements (
    id          SMALLINT PRIMARY KEY,
    code        VARCHAR(40)  NOT NULL UNIQUE,
    name        VARCHAR(80)  NOT NULL,
    description VARCHAR(300) NOT NULL
);
INSERT INTO achievements (id, code, name, description) VALUES
 (1,'FIRST_TIME_HERO','First-Time Hero','Funded a first bill'),
 (2,'MOST_BILLS_HELPED','Most Bills Helped','Helped the most distinct bills in a period'),
 (3,'COMMUNITY_CHAMPION','Community Champion','Supported bills across many categories and regions'),
 (4,'CONSISTENT_CONTRIBUTOR','Consistent Contributor','Contributed in many consecutive months');

CREATE TABLE user_achievements (
    user_id        UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    achievement_id SMALLINT    NOT NULL REFERENCES achievements (id),
    awarded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, achievement_id)
);

CREATE TABLE audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id    UUID REFERENCES users (id),
    action      VARCHAR(80)  NOT NULL,
    entity_type VARCHAR(60)  NOT NULL,
    entity_id   VARCHAR(80),
    details     JSONB,
    ip          VARCHAR(64),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_entity ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_actor ON audit_logs (actor_id, created_at DESC);
CREATE INDEX idx_audit_created ON audit_logs (created_at DESC);

CREATE TRIGGER trg_audit_append_only BEFORE UPDATE OR DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION forbid_mutation();
