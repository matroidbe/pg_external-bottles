# pg_external-bottles

Prebuilt [pgx](https://github.com/matroidbe/pgbrew) bottles of **third-party**
PostgreSQL extensions, for platforms where no package exists. matroidbe's own
extensions are bottled in
[pg_extensions-releases](https://github.com/matroidbe/pg_extensions-releases).

These are unmodified upstream sources at a pinned tag (`bottles.tsv`), built
with `pgx bottle`. Each extension keeps its upstream license (`licenses/`).

## Install

```bash
REL=https://github.com/matroidbe/pg_external-bottles/releases/download/v0.1.0
for b in vector-0.8.7 http-1.7 pg_cron-1.6; do
  pgx install --configure --bottle "$REL/$b-pg18-darwin-arm64.tar.gz"
done
```

`pg_cron` must be preloaded and carries no pgbrew declaration, so add it to
`shared_preload_libraries` and set `cron.database_name` yourself.

## What is published

| Extension | Upstream | Tag | Targets |
|---|---|---|---|
| `vector` 0.8.7 | pgvector/pgvector | v0.8.7 | pg18-darwin-arm64 |
| `http` 1.7 | pramsey/pgsql-http | v1.7.2 | pg18-darwin-arm64 |
| `pg_cron` 1.6 | citusdata/pg_cron | v1.6.8 | pg18-darwin-arm64 |

A bottle's version is the extension version from its control file, not the
upstream release tag (pgsql-http v1.7.2 installs extension `http` 1.7).

darwin-arm64 bottles are built against Homebrew's `postgresql@18` with
`MACOSX_DEPLOYMENT_TARGET=14.0`. `vector` and `http` link only system libraries
(`http` uses macOS's `/usr/lib/libcurl`). `pg_cron` also links Homebrew's
`gettext` and PostgreSQL's `libpq`, both of which `brew install postgresql@18`
provides.

## Build

```bash
PG_CONFIG=/opt/homebrew/opt/postgresql@18/bin/pg_config scripts/build.sh dist
gh release create vX.Y.Z dist/* licenses/*
```

Bump the release when a pin changes. Never replace an asset of a published
release.
