# Dependency Updates

Two bots run side-by-side to keep every pinned version current:

| Bot | What it tracks | Config | Schedule |
|-----|---------------|--------|----------|
| [Dependabot](https://docs.github.com/en/code-security/dependabot) | `FROM` base images · GitHub Actions SHAs | `.github/dependabot.yml` | Weekly |
| [Renovate](https://docs.renovatebot.com/) | `ARG` tool versions in `Dockerfile` | `renovate.json` | On push + scheduled |

## Why Two Bots?

**Dependabot** understands Docker `FROM` lines and GitHub Actions SHAs natively — it cannot update `ARG` version strings inside a `RUN` layer.

**Renovate** fills that gap via regex-based custom managers, opening a PR whenever any tool version in the Dockerfile has a new upstream release.

## What Renovate Tracks

Each `ARG` in the Dockerfile is mapped to its upstream GitHub release source:

| ARG | Repository |
|-----|-----------|
| `HURL_VERSION` | `Orange-OpenSource/hurl` |
| `K6_VERSION` | `grafana/k6` |
| `HELM_VERSION` | `helm/helm` |
| `KUBECTL_VERSION` | `kubernetes/kubernetes` |
| `GHZ_VERSION` | `bojand/ghz` |
| `GRPC_HEALTH_PROBE_VERSION` | `grpc-ecosystem/grpc-health-probe` |

## Release Cadence

Every merged Dependabot or Renovate PR triggers a **patch version bump** via release-please, which auto-merges and publishes a new Docker image. The `latest` tag always points to the most recent release.
