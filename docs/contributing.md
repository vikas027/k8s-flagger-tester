# Contributing

## Setup

```bash
mise run install
```

This installs Python dependencies and pre-commit hooks (including the commit-msg hook).

## Local Development

| Command | What it does |
|---------|-------------|
| `mise run lint` | Run all pre-commit hooks |
| `mise run docker-build-local` | Build image for local arch |
| `mise run docker-run` | Run the image on port 8080 |
| `mise run docker-preview` | Push ephemeral image to ttl.sh (6h TTL) |
| `mise run docs-serve` | Preview docs locally at http://localhost:8000 |

## Commit Style

Commits must follow [Conventional Commits](https://www.conventionalcommits.org/):

| Type | When to use |
|------|------------|
| `feat` | New capability or tool added |
| `fix` | Bug fix |
| `chore` | Dependency bump, config change |
| `docs` | Documentation only |
| `ci` | CI/CD workflow change |
| `build` | Dockerfile change |

The pre-commit `commit-msg` hook enforces this automatically.

## Pull Request Flow

1. Branch off `main`
2. Make changes — pre-commit runs on every `git commit`
3. Open a PR — CI runs lint, docker preview build, and Trivy security scan
4. Merge — release-please creates a release PR with a version bump
5. Release PR auto-merges — Docker image published to Docker Hub with `latest` + semver tags
