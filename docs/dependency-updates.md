# Dependency Updates

Two tools divide ownership so no dependency falls through the cracks and there is no overlap between them. Both run weekly on **Sunday at 09:00 UTC**.

---

## Why Two Tools?

**Dependabot** is the obvious first choice — native GitHub integration, zero configuration for most ecosystems. But it has two blind spots in this repo:

- It cannot update `ARG` version strings inside Dockerfile `RUN` layers — only `FROM` references
- It has no ecosystem for pre-commit hook `rev:` pins

**Renovate** fills both gaps with regex custom managers and its built-in `pre-commit` support.

!!! info "Scope isolation"
    Renovate is configured with `enabledManagers: ["pre-commit", "custom.regex"]` — it never touches what Dependabot already owns (Docker `FROM` images, GitHub Actions, pip packages).

---

## Ownership Split

=== "Dependabot"

    Configured in `.github/dependabot.yml`.

    | Group | What | Commit prefix | Triggers release? |
    |-------|------|---------------|:-----------------:|
    | `github-actions` | All GitHub Actions in `.github/workflows/` | `chore(ci)` | No |
    | `docker` | `FROM` base images in `Dockerfile` | `fix(docker)` | Yes |
    | `pip-deps` | `mkdocs-material`, `pre-commit`, `pyyaml`, `yamllint` in `requirements.txt` | `chore(deps)` | No |

=== "Renovate"

    Configured in `renovate.json`.

    | Group | What | Commit prefix | Triggers release? |
    |-------|------|---------------|:-----------------:|
    | `pre-commit hooks` | All `rev:` pins in `.pre-commit-config.yaml` | `chore(ci):` | No |
    | `dockerfile tool versions` | `ARG` tool versions in `Dockerfile` | `fix(docker):` | Yes |
    | mise python | `python = "..."` in `mise.toml` | `chore(ci):` | No |

---

## Covered Tools Reference

| Tool / Version | File | Covered by |
|---|---|---|
| All GitHub Actions | `.github/workflows/` | Dependabot `github-actions` |
| `FROM ghcr.io/fluxcd/flagger-loadtester` | `Dockerfile` | Dependabot `docker` |
| `FROM bats/bats` | `Dockerfile` | Dependabot `docker` |
| `FROM debian:13-slim` | `Dockerfile` | Dependabot `docker` |
| `mkdocs-material`, `pre-commit`, `pyyaml`, `yamllint` | `requirements.txt` | Dependabot `pip` |
| Pre-commit hook `rev:` pins | `.pre-commit-config.yaml` | Renovate `pre-commit` |
| `ARG HURL_VERSION` | `Dockerfile` | Renovate `custom.regex` |
| `ARG K6_VERSION` | `Dockerfile` | Renovate `custom.regex` |
| `ARG HELM_VERSION` | `Dockerfile` | Renovate `custom.regex` |
| `ARG KUBECTL_VERSION` | `Dockerfile` | Renovate `custom.regex` |
| `ARG GHZ_VERSION` | `Dockerfile` | Renovate `custom.regex` |
| `ARG GRPC_HEALTH_PROBE_VERSION` | `Dockerfile` | Renovate `custom.regex` |
| `python = "..."` | `mise.toml` | Renovate `custom.regex` |

---

## Release Trigger Logic

Groups using `fix:` prefix cause release-please to open a Release PR when merged to `main`. You decide when to merge — nothing ships automatically. Groups using `chore:` are silently consumed with no changelog entry and no version bump.

| Prefix | Triggers release? |
|--------|:-----------------:|
| `fix(docker):` | Yes — patch |
| `chore(ci):` | No |
| `chore(deps):` | No |

---

## Schedule

Both tools run on the same cadence — at most five PRs on a Sunday morning, one per group.

| Tool | Config | Schedule |
|------|--------|----------|
| Dependabot | `.github/dependabot.yml` | `day: sunday · time: "09:00" · timezone: UTC` |
| Renovate | `renovate.json` | `schedule: ["at 09:00 on sunday"]` |
