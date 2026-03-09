# GitHub Copilot Instructions

## Project Overview

This is a **production Docker Compose deployment** of the [OpenCTI](https://opencti.io) Cyber Threat Intelligence platform fork, maintained by the Vilnius Cyber Grid organisation. It extends the upstream reference deployment with a curated connector set, LDAP/Active Directory authentication, and IaC tooling for automated provisioning.

All OpenCTI images are pinned to **`6.8.12`**. When suggesting image bumps, update every `image:` tag in `docker-compose.yml` that references `opencti/*` to the same version simultaneously.

---

## Repository Layout

```
.
├── docker-compose.yml          # Single Compose file — all services and connectors
├── .env.example                # Template for required environment variables
├── rabbitmq.conf               # RabbitMQ tuning config (bind-mounted)
├── connectors/
│   └── threatfox/
│       └── config.yml          # ThreatFox-specific runtime config (bind-mounted into the container)
├── hooks/
│   └── pre-commit              # Linting gate (yamllint, markdownlint, dotenv-linter)
├── iac/
│   ├── ansible/                # Docker + Docker Compose installation playbooks
│   │   ├── inventory           # Host inventory
│   │   ├── install_docker.yml
│   │   ├── install_docker_compose.yml
│   │   └── add_docker_group.yml
│   └── terraform/
│       └── vsphere/            # vSphere VM provisioning (main.tf, variables.tf, providers.tf)
└── .github/
    └── workflows/
        ├── lint.yml            # Static analysis on push/PR to main
        ├── deploy.yml          # Deployment pipeline
        └── prepare-environment.yml
```

---

## Stack Architecture

### Core Infrastructure Services

| Service | Image | Purpose |
|---|---|---|
| `rsa-key-generator` | `alpine/openssl:3.5.2` | One-shot RSA-4096 key generation on first boot |
| `redis` | `redis:8.2.2` | Platform cache |
| `elasticsearch` | `docker.elastic.co/elasticsearch/elasticsearch:8.19.2` | Search and storage backend (single-node, security disabled) |
| `minio` | `minio/minio:RELEASE.2025-06-13T11-33-47Z` | S3-compatible object storage (port 9000) |
| `rabbitmq` | `rabbitmq:4.1-management` | Message broker — config from `rabbitmq.conf` |
| `opencti` | `opencti/platform:6.8.12` | Core platform (port 8080) |
| `worker` | `opencti/worker:6.8.12` | 3× replicated ingestion workers |

### Connectors

All connectors `depends_on: opencti: condition: service_healthy`.

| Service name | Image | Type | Scope |
|---|---|---|---|
| `connector-export-file-stix` | `opencti/connector-export-file-stix` | `INTERNAL_EXPORT_FILE` | `application/json` |
| `connector-export-file-csv` | `opencti/connector-export-file-csv` | `INTERNAL_EXPORT_FILE` | `text/csv` |
| `connector-export-file-txt` | `opencti/connector-export-file-txt` | `INTERNAL_EXPORT_FILE` | `text/plain` |
| `connector-import-file-stix` | `opencti/connector-import-file-stix` | `INTERNAL_IMPORT_FILE` | `application/json,text/xml` |
| `connector-import-document` | `opencti/connector-import-document` | `INTERNAL_IMPORT_FILE` | `application/pdf,text/plain,text/html` |
| `connector-analysis` | `opencti/connector-import-document` | `INTERNAL_ANALYSIS` | `application/pdf,text/plain,text/html` |
| `mitre` | `opencti/connector-mitre` | `EXTERNAL_IMPORT` | ATT&CK Enterprise/Mobile/ICS/PRE |
| `connector-misp` | `opencti/connector-misp` | `EXTERNAL_IMPORT` | indicators, malware, reports |
| `opencti-connector-shodan` | `opencti/connector-shodan` | `EXTERNAL_IMPORT` | `shodan` |
| `threatfox-connector` | `opencti/connector-threatfox` | `EXTERNAL_IMPORT` | `indicator` |
| `opencti-connector-urlhaus` | `opencti/connector-urlhaus` | `EXTERNAL_IMPORT` | `indicator,url,domain-name,ipv4-addr` |
| `cisa-kev` | `opencti/connector-cisa-known-exploited-vulnerabilities` | `EXTERNAL_IMPORT` | `vulnerability` |
| `connector-alienvault` | `opencti/connector-alienvault` | `EXTERNAL_IMPORT` | `indicator,ipv4-addr,domain-name,hash` |
| `opencti-connector-abuseipdb` | `opencti/connector-abuseipdb` | `EXTERNAL_IMPORT` | `ipv4-addr,indicator` |
| `malwarebazaar` | `opencti/connector-malwarebazaar` | `EXTERNAL_IMPORT` | `malware,indicator` |

---

## Configuration & Secrets

All runtime secrets are injected via `.env` (copy from `.env.example`, never commit `.env`). Variables group by concern:

- **OpenCTI core** — `OPENCTI_ADMIN_*`, `OPENCTI_BASE_URL`, `OPENCTI_SECRET`, `OPENCTI_ENCRYPTION_KEY`, `OPENCTI_HEALTHCHECK_ACCESS_KEY`
- **Infrastructure** — `ELASTIC_MEMORY_SIZE`, `MINIO_ROOT_USER/PASSWORD`, `RABBITMQ_DEFAULT_USER/PASS`, `SMTP_HOSTNAME`
- **LDAP/AD** — `AUTH_LDAP_SERVER_URL`, `AUTH_LDAP_BIND_DN`, `AUTH_LDAP_BIND_PASSWORD`, `AUTH_LDAP_BASE_DN`
- **Connector IDs** — one UUID per connector (`CONNECTOR_<NAME>_ID`); stored in `.env` so they persist across recreates
- **Connector secrets** — `MISP_API_KEY`, `SHODAN_API_KEY`, `ALIENVAULT_API_KEY`, `ABUSEIPDB_API_KEY`, `NVD_API_KEY`

When adding a new connector that requires a unique ID, add `CONNECTOR_<NAME>_ID=` to `.env.example`.

The `OPENCTI_ADMIN_TOKEN` doubles as `OPENCTI_TOKEN` — all connectors use it via `OPENCTI_TOKEN=${OPENCTI_ADMIN_TOKEN}`.

---

## LDAP / Active Directory Integration

The OpenCTI platform is configured for dual auth: `LocalStrategy` (break-glass) and `LdapStrategy`. The LDAP search filter restricts access to members of the `OpenCTI_Users` AD group under the Vilnius municipality LDAP tree. When modifying LDAP config, edit the `PROVIDERS__LDAP__CONFIG__*` env vars in `docker-compose.yml` under the `opencti` service.

---

## IaC

### Ansible (`iac/ansible/`)
Three playbooks for target host bootstrap:
1. `install_docker.yml` — installs Docker Engine
2. `install_docker_compose.yml` — installs Docker Compose v2 plugin
3. `add_docker_group.yml` — adds the deploy user to the `docker` group

Edit `inventory` to target a different host.

### Terraform (`iac/terraform/vsphere/`)
Provisions the VM on vSphere. `terraform.tfvars.example` must be copied to `terraform.tfvars` and filled in before `terraform apply`. Do not commit `terraform.tfvars` or `.terraform/`.

---

## CI/CD (GitHub Actions)

| Workflow | Trigger | What it does |
|---|---|---|
| `lint.yml` | push/PR → `main` | Runs `hooks/pre-commit` (yamllint, markdownlint, dotenv-linter) |
| `prepare-environment.yml` | called by deploy | Prepares the deployment environment |
| `deploy.yml` | manual or on merge | Deploys to the target host |

The pre-commit hook is the single source of truth for linting rules. Always keep it in sync with `hooks/pre-commit`.

---

## Conventions & Patterns

- **Image versioning**: all `opencti/*` images share a single version tag. When one changes, all must change together.
- **Connector IDs**: every connector must have a stable UUID set in `.env`. UUIDs that are hardcoded (e.g., `mitre-001`, `urlhaus-connector-001`) are acceptable only when there is a single instance with no risk of ID collision.
- **Update interval**: external import connectors use `CONNECTOR_UPDATE_INTERVAL=3600` (1 hour) or `UPDATE_INTERVAL=86400` (24 hours); alignment is deliberate — avoid arbitrary values.
- **Confidence levels**: set per connector based on source reliability. Do not flatten all sources to 100.
- **Health checks**: all infrastructure services have a `healthcheck` block. Connectors depend on `opencti: condition: service_healthy`.
- **Volumes**: named Docker volumes only (no host-path mounts for data), except bind mounts for config files (`rabbitmq.conf`, `connectors/threatfox/config.yml`).
- **Restart policy**: `restart: always` on every service.

---

## Adding a New Connector

1. Add a service block in `docker-compose.yml` following existing connector patterns.
2. Set `OPENCTI_URL`, `OPENCTI_TOKEN`, `CONNECTOR_ID`, `CONNECTOR_TYPE`, `CONNECTOR_NAME`, `CONNECTOR_SCOPE`, `CONNECTOR_CONFIDENCE_LEVEL`, `CONNECTOR_LOG_LEVEL`.
3. Add `CONNECTOR_<NAME>_ID=` to `.env.example` (and `.env`).
4. If the connector needs an API key, add the variable to `.env.example` and document it in `README.md`.
5. Add a `depends_on: opencti: condition: service_healthy` block.
6. If the connector requires a config file, place it under `connectors/<name>/` and bind-mount it as `:ro`.
