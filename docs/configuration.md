# Configuration

All tool versions are declared as `ARG`s in the Dockerfile and can be overridden at build time.

## Build Arguments

| ARG | Upstream |
|-----|----------|
| `HURL_VERSION` | [Orange-OpenSource/hurl](https://github.com/Orange-OpenSource/hurl/releases) |
| `K6_VERSION` | [grafana/k6](https://github.com/grafana/k6/releases) |
| `HELM_VERSION` | [helm/helm](https://github.com/helm/helm/releases) |
| `KUBECTL_VERSION` | [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes/releases) |
| `GHZ_VERSION` | [bojand/ghz](https://github.com/bojand/ghz/releases) |
| `GRPC_HEALTH_PROBE_VERSION` | [grpc-ecosystem/grpc-health-probe](https://github.com/grpc-ecosystem/grpc-health-probe/releases) |

Current pinned defaults are in the [`Dockerfile`](https://github.com/vikas027/k8s-flagger-tester/blob/main/Dockerfile) and updated automatically by Renovate.

## Overriding Versions

```bash
docker build \
  --build-arg HURL_VERSION=8.1.0 \
  --build-arg K6_VERSION=v2.1.0 \
  -t my-flagger-tester:custom .
```

## Base Images

The Dockerfile uses three `FROM` stages, all tracked by Dependabot:

| Stage | Image | Purpose |
|-------|-------|---------|
| `loadtester` | `ghcr.io/fluxcd/flagger-loadtester:0.37.0` | Provides the webhook binary |
| `bats` | `bats/bats:1.13.0` | Provides the bats test runner |
| final | `debian` | Runtime base (glibc) |

!!! note "Why Debian?"
    hurl releases a glibc-linked binary only. Debian (slim) is the cleanest base for running it without compatibility shims.
