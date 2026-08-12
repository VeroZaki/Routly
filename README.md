# Routly

Rails API that shortens URLs. Send a long URL and get a short one back; send the short one and get the original. Data lives in Postgres so it survives restarts.

Endpoints: **POST /encode** and **POST /decode** (JSON). Encoding the same URL twice returns the same short link. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how it’s built.

## How to start

1. Start Docker (Colima on macOS):

```bash
colima start
```

2. Build and run:

```bash
docker compose up --build
```

The API is at **http://localhost:3000**.

### Try it

```bash
curl -X POST http://localhost:3000/encode \
  -H "Content-Type: application/json" \
  -d '{"url":"https://codesubmit.io/library/react"}'

curl -X POST http://localhost:3000/decode \
  -H "Content-Type: application/json" \
  -d '{"short_url":"http://localhost:3000/GeAi9K"}'
```

## Local setup (without Docker)

```bash
cp .env.example .env
bundle install
bundle exec rake db:create db:migrate
bundle exec puma config.ru -p 3000
```

## Tests

```bash
docker compose run --rm --entrypoint "" -v "$PWD:/app" \
  -e RAILS_ENV=test -e PGHOST=db -e PGUSER=postgres -e PGPASSWORD=postgres \
  app bin/test
```

## API

### Encode

`POST /encode` with `{ "url": "https://example.com" }` → `201` `{ "short_url", "original_url" }`

### Decode

`POST /decode` with `{ "short_url": "http://localhost:3000/Ab12Cd" }` → `200` `{ "original_url" }`
