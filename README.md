# Routly

A minimal Rails API that shortens URLs and resolves them again.

- **POST /encode** — turn a long URL into a short link  
- **POST /decode** — turn a short link (or bare code) back into the original URL  

Same normalized URL always maps to the same short link. Persistence is PostgreSQL so data survives restarts.

Architecture notes: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## How to start (Docker)

```bash
colima start   # macOS, if Docker isn’t running yet
docker compose up --build
```

API: **http://localhost:3000**

```bash
# Encode
curl -X POST http://localhost:3000/encode \
  -H "Content-Type: application/json" \
  -d '{"url":"https://codesubmit.io/library/react"}'

# Decode (use the short_url from the encode response)
curl -X POST http://localhost:3000/decode \
  -H "Content-Type: application/json" \
  -d '{"short_url":"http://localhost:3000/Ab12Cd"}'
```

### Local (without Docker)

```bash
cp .env.example .env
bundle install
bundle exec rake db:create db:migrate
bundle exec puma config.ru -p 3000
```

---

## API

| Method | Path | Body | Success |
|--------|------|------|---------|
| POST | `/encode` | `{ "url": "https://example.com" }` | `201` `{ "short_url", "original_url" }` |
| POST | `/decode` | `{ "short_url": "http://localhost:3000/Ab12Cd" }` | `200` `{ "original_url" }` |

Errors:

| Status | When |
|--------|------|
| 400 | Missing `url` / `short_url` |
| 422 | Invalid URL |
| 404 | Unknown short code |
| 503 | Could not allocate a unique code after retries |

Behavior details:

- URLs are normalized (trim, add `https://` when missing, reject `javascript:` / `data:`).
- Decode accepts a full short URL or a bare 6-character code.
- Encode is idempotent for the same normalized original URL.

---

## Tests

```bash
docker compose run --rm --entrypoint "" -v "$PWD:/app" \
  -e RAILS_ENV=test -e PGHOST=db -e PGUSER=postgres -e PGPASSWORD=postgres \
  app bin/test
```

Expected: all model, integration, and normalizer tests green (encode/decode, validation, idempotency, error paths).

---

## Security

Decode returns JSON only — there is **no HTTP redirect**, which avoids open-redirect abuse in this demo.

What is mitigated today:

- **Dangerous schemes** — `javascript:` and `data:` are rejected during normalization.
- **SQL injection** — ActiveRecord only; no raw SQL built from user input.
- **XSS** — JSON API; clients must not interpolate responses into HTML unsafely.
- **Input shape** — required params checked; invalid URLs return 422.

What is *not* production-hard yet (documented intentionally):

- **No auth / rate limiting** — a public encode endpoint can be abused; add Rack::Attack (or similar) and/or API keys before exposing widely.
- **Short codes are guessable in theory** — 6-char base62 (~56 bits of space, random). Rate-limit decode and monitor for scanning.
- **Stored URLs are not reputation-checked** — if you later add redirects, add an allowlist/blocklist or interstitial warning page.
- **Default `SECRET_KEY_BASE` in Compose** — change via env for any shared deployment.
- **Error detail** — keep production error pages generic; log server-side only.

---

## Scalability

Current design (random 6-char base62 + unique index + retry) is fine for a single app instance and moderate traffic.

| Concern | Today | If you outgrow it |
|---------|--------|-------------------|
| Code collisions | Retry up to 5 times, then 503 | Use a monotonic ID (DB sequence / Redis `INCR`) encoded as base62 — no collisions |
| Encode throughput | `find_by(original_url)` then insert | Cache normalized URL → code in Redis; consider unique index on `original_url` + upsert |
| Decode throughput | Indexed lookup on `code` | Read replicas and/or Redis cache in front of Postgres |
| Idempotency races | Two concurrent encodes of a new URL can race | Unique constraint on `original_url` + rescue/retry, or advisory lock |
| Process model | One Puma process in Compose | Horizontal replicas behind a load balancer; shared Postgres |

Postgres remains the source of truth; use connection pooling (e.g. PgBouncer) and backups in production.

---

## Design notes (maintainability)

- Thin controller (`LinksController`) — HTTP concerns only.
- Domain logic on `Link` + `UrlNormalizer`.
- Custom validators (`url`, `base62`) keep rules reusable and testable.
- Minimal Rails API boot (no unused railties) for a small, readable surface area.

---

## AI usage (transparency)

Per the assignment AI guidelines:

**Completed / authored without AI (original work from the prior ShortLink Engine implementation, adapted here):**

- Encode / decode API behavior and request/response contract  
- `Link` model logic (normalize, idempotent encode, code generation, decode)  
- `UrlNormalizer`, `UrlValidator`, `Base62Validator`  
- Core integration and model tests for happy path and main error cases  
- Security and scalability reasoning reflected in this README  

**AI-assisted (boilerplate / project plumbing only):**

- Routly repo scaffolding and renaming from ShortLink Engine → Routly (`Link`, `links`, Docker/Compose wiring)  
- Extra regression tests and README/docs formatting for demo submission  
- Test runner script (`bin/test`) convenience wrapper  

Core problem-solving and URL-shortening logic are not AI-invented for this submission; they follow the original ShortLink Engine design.

---

## Deployment

Demo runs with Docker Compose (app + Postgres) on any host that can run Docker, e.g. a free VM (Oracle Cloud, Fly.io, Railway, Render, etc.):

```bash
docker compose up --build -d
```

Set at least:

- `SECRET_KEY_BASE` — strong random value  
- `ROUTLY_BASE_URL` — public base URL of the deployed API  
- `PGUSER` / `PGPASSWORD` / `PGHOST` — if not using the Compose `db` service as-is  
```
