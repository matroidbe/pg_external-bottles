# pg_external-bottles

Prebuilt [pgx](https://github.com/matroidbe/pgbrew) bottles of **third-party**
PostgreSQL extensions, for platforms where no package exists. matroidbe's own
extensions are bottled in
[pg_extensions-releases](https://github.com/matroidbe/pg_extensions-releases).

**These are not our extensions.** Each bottle is an unmodified build of the
upstream source at a pinned tag (`bottles.tsv`), redistributed under the
upstream license. Report bugs in an extension upstream; report a broken bottle
here.

## Upstream projects and licenses

| Bottle | Upstream project | Built from | Copyright | License |
|---|---|---|---|---|
| `vector` 0.8.7 | [pgvector/pgvector](https://github.com/pgvector/pgvector) | tag `v0.8.7` | PostgreSQL Global Development Group, The Regents of the University of California | [PostgreSQL License](licenses/vector/LICENSE) |
| `http` 1.7 | [pramsey/pgsql-http](https://github.com/pramsey/pgsql-http) | tag `v1.7.2` | Paul Ramsey | [MIT](licenses/http/LICENSE) |
| `pg_cron` 1.6 | [citusdata/pg_cron](https://github.com/citusdata/pg_cron) | tag `v1.6.8` | Citus Data | [PostgreSQL License](licenses/pg_cron/LICENSE) |
| `age` 1.8.0 | [apache/age](https://github.com/apache/age) | tag `PG18/v1.8.0-rc0` | The Apache Software Foundation | [Apache-2.0](licenses/age/LICENSE), [NOTICE](licenses/age/NOTICE) |
| `postgis` 3.6.4 | [postgis.net](https://postgis.net) ([postgis/postgis](https://github.com/postgis/postgis)) | release tarball `postgis-3.6.4.tar.gz` (sha256 pinned) | The PostGIS Project Steering Committee and contributors | [GPL-2.0-or-later](licenses/postgis/COPYING), [component licenses](licenses/postgis/LICENSE) |
| `plpython3u` 1.0 | [PostgreSQL](https://www.postgresql.org) (`src/pl/plpython`) | release tarball `postgresql-18.6.tar.bz2` (sha256 pinned), built as a PGXS module (`overlays/plpython3u/`) | The PostgreSQL Global Development Group | [PostgreSQL License](licenses/plpython3u/LICENSE) |
| `timescaledb` 2.30.2 | [timescale/timescaledb](https://github.com/timescale/timescaledb) | tag `2.30.2` | Timescale, Inc. | [Apache-2.0](licenses/timescaledb/LICENSE-APACHE) and the [Timescale License](licenses/timescaledb/LICENSE-TIMESCALE), [NOTICE](licenses/timescaledb/NOTICE) |

Every release attaches these license and NOTICE files beside the bottles, as
`<extension>-LICENSE…` / `<extension>-NOTICE`. See also [NOTICE](NOTICE).

**PostGIS** is GPL-2.0-or-later. Every release carrying its bottle also
attaches the exact source tarball it was built from (`postgis-3.6.4.tar.gz`,
also listed in SHA256SUMS), as the GPL asks of a binary distribution. It links
Homebrew's GEOS (LGPL), PROJ, json-c and protobuf-c (MIT/BSD) dynamically; the
bottle records them, and `pgx install` refuses until they are installed
(`brew install geos proj json-c protobuf-c`, or `pgx install --install-deps`).

**TimescaleDB** is built in full, including the `tsl/` features (compression,
continuous aggregates) that eidos's `timeseries` uses. Those are under the
Timescale License, which permits redistributing the binaries "solely in
unmodified standalone form" (§2.1(c)) and keeps its restrictions on use, for
example offering TimescaleDB as a hosted database service (§2.2). Using this
bottle means accepting that license. The `timescaledb-tsl-*` library is the
TSL part; everything else is Apache-2.0.

## Install

```bash
REL=https://github.com/matroidbe/pg_external-bottles/releases/download/v0.4.0
for b in vector-0.8.7 http-1.7 pg_cron-1.6 age-1.8.0 timescaledb-2.30.2 postgis-3.6.4 plpython3u-1.0; do
  pgx install --configure --bottle "$REL/$b-pg18-darwin-arm64.tar.gz"
done
```

`pg_cron`, `age` and `timescaledb` carry a pgbrew manifest (`manifests/`), so
`--configure` preloads them and writes their settings. Point pg_cron at your
database with `--set cron.database_name=<db>`. AGE's preloaded hooks run in every
database: create the extension in each one, `template1` included.

## Platform notes

**Since v0.4.0 these bottles link the pinned kegs of the `matroidbe/eidos`
Homebrew tap** (`eidos-postgresql@18`, `eidos-gettext@1.0`, `eidos-geos@3.15`,
`eidos-proj@9.9`, `eidos-json-c@0.19`, `eidos-protobuf-c@1.5`,
`eidos-python@3.11`), never homebrew/core's, so a `brew upgrade` cannot break
them. Build and install them against `eidos-postgresql@18`; `eidos setup`
installs the tap and these bottles together. v0.3.0 and earlier link
homebrew/core.

**plpython3u** is PostgreSQL's own PL/Python, built from the 18.6 source tree
against the installed server headers with a PGXS Makefile (the in-tree one
needs the whole tree configured). It embeds `eidos-python@3.11`, which carries
numpy for it.

darwin-arm64 bottles are built against Homebrew's `postgresql@18` with
`MACOSX_DEPLOYMENT_TARGET=14.0`, and also load into a PostgreSQL 18 built from
source. `vector`, `http`, `age` and `timescaledb` link only system libraries
(`http` uses macOS's `/usr/lib/libcurl`). `pg_cron` also links Homebrew's
`gettext` and `postgresql@18`'s `libpq` by absolute path, so it needs
`brew install postgresql@18` present even when another PostgreSQL runs it.

A bottle's version is the extension version from its control file, not the
upstream tag (pgsql-http v1.7.2 installs extension `http` 1.7).

## Build

Needs pgx >= v0.4.0 (`--build-var`, the CMake and autotools builders, recorded
library requirements), plus `brew install bison cmake openssl` for AGE and
TimescaleDB and `brew install geos proj gdal json-c protobuf-c` for PostGIS.

```bash
PG_CONFIG=/opt/homebrew/opt/postgresql@18/bin/pg_config scripts/build.sh dist
```

`bottles.tsv` pins each upstream git tag (or a release tarball's sha256) and the
build variables it needs;
`manifests/<name>.pgbrew.toml` is copied into the source before bottling. Bump the
release when a pin changes, and never replace an asset of a published release.
