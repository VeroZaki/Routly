# Routly

A Ruby gem project.

## How to start

1. Start Docker (Colima on macOS):

```bash
colima start
```

2. Build and run:

```bash
docker compose up --build
```

You should see `Routly 0.1.0`.

### Other useful commands

```bash
docker compose run --rm routly bundle exec rspec  # tests
docker compose run --rm routly bash               # shell
```

## Local setup (without Docker)

```bash
bin/setup
bundle exec routly
```

## Development

```bash
bundle exec rspec   # run tests
bundle exec rubocop # lint
bin/console         # interactive prompt
```
