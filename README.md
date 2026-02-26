# OpenCTI — Custom Docker Deployment

[![Lint](https://github.com/Vilnius-Cyber-Grid/opencti/actions/workflows/lint.yml/badge.svg)](https://github.com/Vilnius-Cyber-Grid/opencti/actions/workflows/lint.yml)

A production Docker Compose deployment of the [OpenCTI](https://opencti.io) Cyber Threat Intelligence platform, extended with a custom connector set and LDAP authentication.

Based on:

- [OpenCTI-Platform/opencti](https://github.com/OpenCTI-Platform/opencti) — core platform (Apache 2.0)
- [OpenCTI-Platform/docker](https://github.com/OpenCTI-Platform/docker) — reference Docker deployment

---

## Stack

| Service | Description |
|---|---|
| `opencti` | OpenCTI platform (`opencti/platform:6.8.12`) |
| `worker` | 3× OpenCTI workers |
| `elasticsearch` | Search & storage backend |
| `redis` | Cache |
| `minio` | S3-compatible object storage |
| `rabbitmq` | Message broker |

### Connectors

| Connector | Type | Source |
|---|---|---|
| MITRE ATT&CK | External Import | Docker Hub |
| MISP | External Import | Docker Hub |
| Shodan | External Import | Docker Hub |
| ThreatFox | External Import | Docker Hub |
| URLHaus | External Import | Docker Hub |
| CISA KEV | External Import | Docker Hub |
| AlienVault OTX | External Import | Docker Hub |
| AbuseIPDB | External Import | Docker Hub |
| MalwareBazaar | External Import | Docker Hub |
| Export File STIX/CSV/TXT | Internal Export | Docker Hub |
| Import File STIX / Document | Internal Import | Docker Hub |

---

## Getting Started

### Prerequisites

- Docker & Docker Compose v2
- A `.env` file (copy from `.env.example`)

### Setup

```bash
cp .env.example .env
# Fill in all required values in .env
docker compose up -d
```

The platform will be available at `http://localhost:8080` (or the `OPENCTI_BASE_URL` you configured).

### Environment Variables

All configuration is driven by `.env`. Key variables:

| Variable | Description |
|---|---|
| `OPENCTI_ADMIN_EMAIL` | Break-glass admin email |
| `OPENCTI_ADMIN_PASSWORD` | Break-glass admin password |
| `OPENCTI_ADMIN_TOKEN` | Shared token used by all connectors |
| `OPENCTI_BASE_URL` | Public URL of the platform |
| `ELASTIC_MEMORY_SIZE` | JVM heap for Elasticsearch (e.g. `4g`) |
| `AUTH_LDAP_SERVER_URL` | LDAP server URL for SSO |
| `AUTH_LDAP_BIND_DN` | LDAP bind DN |
| `AUTH_LDAP_BIND_PASSWORD` | LDAP bind password |
| `AUTH_LDAP_BASE_DN` | LDAP search base |

See `.env.example` for the full list.

### Stopping

```bash
docker compose down
```

To also remove volumes (wipes all data):

```bash
docker compose down -v
```

---

## Authentication

The platform is configured with two providers:

- **Local** — break-glass admin account defined in `.env`
- **LDAP** — Active Directory SSO via `LdapStrategy`

---

## Static Checks & Linting

This repository uses [pre-commit](https://pre-commit.com) to enforce code quality on every commit. All linter configurations live in the `linters/` directory.

| Tool | Target | Config |
|---|---|---|
| [yamllint](https://github.com/adrienverge/yamllint) | YAML files (`*.yml`, `*.yaml`) | [`linters/.yamllint.yml`](linters/.yamllint.yml) |
| [markdownlint](https://github.com/igorshubovych/markdownlint-cli) | Markdown files (`*.md`) | [`linters/.markdownlint.yml`](linters/.markdownlint.yml) |
| [dotenv-linter](https://github.com/wemake-services/dotenv-linter) | `.env*` files | — |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Entire repo (secret detection) | [`linters/.gitleaks.toml`](linters/.gitleaks.toml) |
| `docker compose config` | `docker-compose.yml` | — |

### Local Setup

```bash
pip install pre-commit
pre-commit install
```

Hooks will now run automatically on every `git commit`. To run all checks manually:

```bash
pre-commit run --all-files
```

Checks are also enforced in CI via GitHub Actions (see `.github/workflows/lint.yml`).

---

## License

This project is licensed under the [Apache License 2.0](LICENSE).

The upstream OpenCTI platform (Community Edition) is copyright [Filigran](https://filigran.io) and also licensed under Apache 2.0.
