# OpenCTI — Custom Docker Deployment

[![Lint](https://github.com/Vilnius-Cyber-Grid/opencti/actions/workflows/lint.yml/badge.svg)](https://github.com/Vilnius-Cyber-Grid/opencti/actions/workflows/lint.yml)

A production Docker Compose deployment of the [OpenCTI](https://opencti.io) Cyber Threat Intelligence platform, extended with a custom connector set and LDAP authentication.

Based on:

- [OpenCTI-Platform/opencti](https://github.com/OpenCTI-Platform/opencti) — core platform (Apache 2.0)
- [OpenCTI-Platform/docker](https://github.com/OpenCTI-Platform/docker) — reference Docker deployment

---

## Stack

| Service | Description |
| --- | --- |
| `rsa-key-generator` | One-shot RSA-4096 key generation on first boot |
| `opencti` | OpenCTI platform (`opencti/platform:6.8.12`) |
| `worker` | 3× OpenCTI workers |
| `elasticsearch` | Search & storage backend |
| `redis` | Cache |
| `minio` | S3-compatible object storage |
| `rabbitmq` | Message broker |

### Connectors

| Connector | Type | Notable env vars |
| --- | --- | --- |
| MITRE ATT&CK | External Import | — |
| MISP | External Import | `MISP_URL`, `MISP_API_KEY` |
| Shodan | External Import | `SHODAN_API_KEY` |
| ThreatFox | External Import | `THREATFOX_API_URL`, `THREATFOX_IMPORT_IOC_TYPES` |
| URLHaus | External Import | — |
| CISA KEV | External Import | — |
| AbuseIPDB | External Import | `ABUSEIPDB_API_KEY` |
| MalwareBazaar | External Import | `MALWAREBAZAAR_API_KEY` |
| Export File STIX/CSV/TXT | Internal Export | — |
| Import File STIX / Document | Internal Import | — |
| Document Analysis | Internal Analysis | — |

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
| --- | --- |
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

## IaC

### Ansible (`iac/ansible/`)

Three playbooks for target host bootstrap:

| Playbook | Purpose |
| --- | --- |
| `install_docker.yml` | Installs Docker Engine |
| `install_docker_compose.yml` | Installs Docker Compose v2 plugin |
| `add_docker_group.yml` | Adds the deploy user to the `docker` group |

Edit `iac/ansible/inventory` to target a different host.

### Terraform (`iac/terraform/vsphere/`)

Provisions the VM on vSphere.

```bash
cd iac/terraform/vsphere
cp terraform.tfvars.example terraform.tfvars
# Fill in terraform.tfvars
terraform init && terraform apply
```

> Do not commit `terraform.tfvars` or `.terraform/`.

---

## Authentication

The platform is configured with two providers:

- **Local** — break-glass admin account defined in `.env`
- **LDAP** — Active Directory SSO via `LdapStrategy`

---

## Static Checks & Linting

This repository uses [pre-commit](https://pre-commit.com) to enforce code quality on every commit. All linter configurations live in the `linters/` directory.

| Tool | Target | Config |
| --- | --- | --- |
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

## Contributing

### Branching

Work on a feature branch and open a pull request targeting `main`. All checks must pass before merging.

### Adding a Connector

1. Add a service block in `docker-compose.yml` following the existing connector pattern.
2. Set the required environment variables: `OPENCTI_URL`, `OPENCTI_TOKEN`, `CONNECTOR_ID`, `CONNECTOR_TYPE`, `CONNECTOR_NAME`, `CONNECTOR_SCOPE`, `CONNECTOR_CONFIDENCE_LEVEL`, `CONNECTOR_LOG_LEVEL`.
3. Add `CONNECTOR_<NAME>_ID=` (and any API key variables) to `.env.example`.
4. Add a `depends_on: opencti: condition: service_healthy` block.
5. Update the Connectors table in this README.

> All current connectors are configured entirely via environment variables. A bind-mounted `connectors/<name>/config.yml` is only needed when a setting has no corresponding env var.

### Upgrading OpenCTI

All `opencti/*` images share a single version tag. Update every `opencti/*` image in `docker-compose.yml` to the same new version simultaneously and update the version references in this README.

### Commit Hygiene

- Install the pre-commit hook once: `git config core.hooksPath hooks`
- The hook runs yamllint, markdownlint, dotenv-linter, gitleaks, and `docker compose config` validation automatically on every commit.
- Never commit `.env`, `terraform.tfvars`, or `.terraform/`.

---

## License

This project is licensed under the [Apache License 2.0](LICENSE).

The upstream OpenCTI platform (Community Edition) is copyright [Filigran](https://filigran.io) and also licensed under Apache 2.0.
