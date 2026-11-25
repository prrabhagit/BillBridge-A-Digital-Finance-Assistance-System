# BillBridge — Stage 2: Backend foundation & authentication

> Someone's burden. Your opportunity to make a difference.

## Status (read this first)
| Item | State |
|---|---|
| Plain-Java utilities (country→currency, file sniffing, token hashing) | Compiled and executed in the authoring sandbox |
| Spring Boot code, SQL migrations, JUnit/Mockito/Testcontainers tests | **Written but NOT compiled or run by the author** (no Maven Central or Docker access there). Expect to fix small compile/startup errors on first build; paste them back and they get fixed before Stage 3. |
| Email delivery | **Not implemented.** Dev profile logs the verification token. Prod profile refuses to start until a real sender exists (Stage 6). |
| National ID verification | Manual admin review only. No government/KYC API is called. |
| Payments, bills, leaderboard, frontend | Not started (Stages 3–6). Tables exist in the migrations; no code uses them yet. |

## Run it
```bash
docker compose up -d                       # PostgreSQL 16
export JWT_SECRET=$(openssl rand -base64 48)
export IDENTITY_HMAC_KEY=$(openssl rand -base64 48)
export BOOTSTRAP_ADMIN_EMAIL=admin@example.com
export BOOTSTRAP_ADMIN_PASSWORD='change-me-please-123'
export REQUIRE_EMAIL_VERIFICATION=false    # dev convenience; default is true
cd backend && mvn spring-boot:run          # Swagger UI: http://localhost:8080/swagger-ui.html
mvn test                                   # integration test needs Docker (Testcontainers)
```

## What Stage 2 delivers
- Flyway migrations **V1–V5**: the complete schema from Stage 1 (bills, payments, ledger, campaigns, audit…). Only identity/auth tables have Java code so far.
- JWT access tokens (15 min) + rotating refresh tokens with **reuse detection** (replay revokes the whole session family).
- RBAC (APPLICANT, DONOR, ORGANIZATION, ADMIN). Admin cannot be self-registered; first admin comes from env vars.
- **Currency follows the user's country** (derived server-side from ISO 3166 → ISO 4217; the client cannot choose it). **Region is user-selectable** from `/regions?country=XX` (Nepal's 7 provinces seeded; admins add others).
- **National ID verification**: upload + admin review. ID number stored only as keyed HMAC + last 4; one approved account per ID (DB-enforced); file type checked by magic bytes; every admin document view is audited; admins can't review themselves.
- Account lockout (5 failures / 15 min), per-IP rate limit on `/auth/**`, generic login errors, timing equalisation, RFC 7807 errors, append-only audit log (DB trigger).

## Endpoints (`/api/v1`)
| Method & path | Access |
|---|---|
| `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/verify-email` | public |
| `GET /countries`, `GET /regions?country=NP` | public |
| `GET/PATCH /users/me` | authenticated |
| `POST /identity-verifications` (multipart: `data` JSON + `document`), `GET /identity-verifications/mine` | authenticated |
| `GET /admin/identity-verifications?status=PENDING`, `GET …/{id}/document`, `POST …/{id}/approve`, `POST …/{id}/reject` | admin |
| `POST /admin/regions` | admin |

## Changes from the Stage 1 plan
- `verify-email` is **POST**, not GET (prefetchers/email scanners must not trigger state changes).
- Donation idempotency key is unique **per donor**, not globally.
- `bill_documents.sha256` index is **non-unique**: duplicates are flagged for admins, not rejected by a DB error.
- `audit_logs` has a single `details` JSONB column instead of before/after.

## Known limitations / next
- Local-disk document storage → MinIO/S3 with 5-minute signed URLs in Stage 3.
- In-memory rate limiter → Redis-backed in Stage 7.
- Cross-currency donations (donor in one country, bill in another) are a Stage 5 decision: the schema stores amounts in the bill's currency.
- Stage 3 will require `identity_status = VERIFIED` before an applicant can submit a bill.
