# k8s-flagger-tester Improvement Plan

Mirrors the dependency management and CI improvements applied to k8s-drift-eye and mcp-trippy.

---

## Context

This repo already has a solid foundation:
- `dorny/paths-filter` changes job gating docker-preview on Dockerfile changes ✅
- Action registry table in ci.yaml ✅
- `docs/dependency-updates.md` page exists ✅
- `site/` in `.gitignore` ✅
- Digest-pinned Dockerfile base images ✅

What follows is a targeted delta — not a rewrite.

---

## 1. Apply all open PRs first (9 open)

Incorporate all open dependency PRs into a single commit before making structural changes, so diffs stay clean.

| PR | What |
|----|------|
| #13 | `debian:13-slim` docker digest update |
| #14 | `actions/setup-python` v6.2.0 → v6.3.0 |
| #15 | `grafana/k6` ARG v2.0.0 → v2.1.0 |
| #16 | `docker/build-push-action` v7.2.0 → v7.3.0 |
| #17 | `github/codeql-action` → v4.36.3 |
| #18 | `docker/login-action` v4.2.0 → v4.4.0 |
| #19 | `docker/metadata-action` v6.1.0 → v6.2.0 |
| #20 | `docker/setup-buildx-action` v4.1.0 → v4.2.0 |
| #21 | `dorny/paths-filter` v4.0.1 → v4.0.2 |

Update the **action registry table** in `ci.yaml` to match. Also update `release.yaml` and `docs.yaml` for the docker action bumps.

---

## 2. dependabot.yml — grouping, schedule, correct prefixes, add pip

**Changes:**
- Add `groups` to all existing ecosystems (one PR per group)
- Change `docker` prefix from `chore(docker)` → `fix(docker)` so Docker base image bumps trigger a release
- Change schedule to Sunday 09:00 UTC on all ecosystems; remove `cooldown`
- Add `pip` ecosystem for `requirements.txt` with `chore(deps)` (docs tooling, no release)

**Result:**

| Group | Tool | Prefix | Release? |
|-------|------|--------|----------|
| `github-actions` | Dependabot | `chore(ci)` | No |
| `docker` | Dependabot | `fix(docker)` | Yes |
| `pip-deps` | Dependabot | `chore(deps)` | No |

---

## 3. renovate.json — fix deprecated fields, add scope and grouping

**Changes:**
- Remove `"pre-commit": {"enabled": true}` (deprecated — use `enabledManagers`)
- Add `"enabledManagers": ["pre-commit", "custom.regex"]` so Renovate never touches what Dependabot owns (Docker FROM lines, GitHub Actions)
- `fileMatch` → `managerFilePatterns` with `/^Dockerfile$/` regex format
- Remove `extractVersionTemplate` from hurl (not needed — hurl releases are already semver-shaped)
- Add `"schedule": ["at 09:00 on sunday"]`
- Add `packageRules` for grouping:
  - `pre-commit hooks` → `chore(ci):` (no release)
  - `dockerfile tool versions` → `fix(docker):` (triggers release)
- Add regex manager for `python` version in `mise.toml` → `chore(ci):` (no release)

**Coverage after change:**

| Group | What | Prefix | Release? |
|-------|------|--------|----------|
| `pre-commit hooks` | `.pre-commit-config.yaml` revs | `chore(ci):` | No |
| `dockerfile tool versions` | `ARG HURL/K6/HELM/KUBECTL/GHZ/GRPC_HEALTH_PROBE` | `fix(docker):` | Yes |
| mise python | `python = "..."` in `mise.toml` | `chore(ci):` | No |

---

## 4. .pre-commit-config.yaml — add missing hooks + renovate validator

Current hooks vs mcp-trippy baseline — missing:
- `check-json`
- `check-toml`
- `check-case-conflict`
- `detect-private-key`
- `no-commit-to-branch` (prevent direct commits to `main`)
- `renovate-config-validator` (from `renovatebot/pre-commit-hooks@43.252.1`)

Add all of the above. The `renovate-config-validator` hook catches `renovate.json` errors locally before they reach the GitHub App.

---

## 5. ci.yaml — add workflow_dispatch + lint summary

**Changes:**
- Add `workflow_dispatch:` trigger so CI can be manually triggered (matches k8s-drift-eye/mcp-trippy pattern)
- Add a **Generate summary** step to the `lint` job listing all pre-commit hooks run (currently the lint job has no summary). Mirror the mcp-trippy format:

```
| Check | Tool |
| Trailing whitespace | pre-commit |
| End of file fixer | pre-commit |
| YAML syntax | pre-commit |
| Merge conflicts | pre-commit |
| Large files | pre-commit |
| JSON syntax | pre-commit |
| TOML syntax | pre-commit |
| Case conflicts | pre-commit |
| Private keys | pre-commit |
| No commit to main | pre-commit |
| YAML style | yamllint |
| Dockerfile | hadolint |
| GitHub Actions workflows | actionlint |
| Commit message | conventional-commits |
| Renovate config | renovate-config-validator |
```

Note: ci.yaml already has the `changes` job filtering on `Dockerfile` — no change needed there.

---

## 6. docs/dependency-updates.md — update to reflect new ownership

The file exists but reflects the pre-improvement state (no grouping, no pip, no pre-commit manager, no schedule). Rewrite to match the full coverage table format used in mcp-trippy, including:
- Why two tools
- Ownership split table (Dependabot vs Renovate)
- All groups with prefix and release trigger
- Schedule (Sunday 09:00 UTC)
- Complete covered tools reference table

---

## 7. GitHub repo settings

- Enable **auto-delete head branch** after PR merge (currently not set)

---

## 8. Full tool coverage audit (post-changes)

| Tool / Version | File | Owner |
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

## Execution order

1. Create branch `chore/dependency-management`
2. Apply open PRs (#13–#21) — single commit, close originals after merge
3. Fix `renovate.json` (deprecated fields, enabledManagers, schedule, grouping)
4. Fix `dependabot.yml` (groups, schedule, prefixes, pip ecosystem)
5. Update `.pre-commit-config.yaml` (add missing hooks)
6. Update `ci.yaml` (workflow_dispatch, lint summary, registry table)
7. Update `docs/dependency-updates.md`
8. Run `mise run lint` locally to verify all hooks pass
9. Commit, push, open PR
10. Wait for all checks to pass → merge
11. Close superseded open PRs
12. Enable auto-delete branches in GitHub settings
