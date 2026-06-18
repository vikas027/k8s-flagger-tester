# k8s-flagger-tester

[![release](https://img.shields.io/github/v/release/vikas027/k8s-flagger-tester?logo=github&label=release)](https://github.com/vikas027/k8s-flagger-tester/releases)
[![docker](https://img.shields.io/docker/v/vikas027/k8s-flagger-tester?sort=semver&logo=docker&label=docker)](https://hub.docker.com/r/vikas027/k8s-flagger-tester)
[![ci](https://img.shields.io/github/actions/workflow/status/vikas027/k8s-flagger-tester/ci.yaml?logo=github&label=ci)](https://github.com/vikas027/k8s-flagger-tester/actions/workflows/ci.yaml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/vikas027/k8s-flagger-tester/badge)](https://securityscorecards.dev/viewer/?uri=github.com/vikas027/k8s-flagger-tester)

> Flagger load-tester extended with **hurl** and **k6** for HTTP assertion and load-test canary gates.

## Overview

`k8s-flagger-tester` extends the official [Flagger load-tester](https://github.com/fluxcd/flagger/tree/main/pkg/loadtester) with two additional tools pre-installed:

- **[hurl](https://hurl.dev/)** — declarative HTTP testing with assertions, used as Flagger webhook gates to verify a canary is functionally correct before traffic is shifted
- **[k6](https://k6.io/)** — scriptable load testing, used as a Flagger webhook gate to verify latency and error-rate thresholds under synthetic load

All bundled tools are installed at their latest stable versions with explicit version `ARG`s, making upgrades a one-line diff.

## Why Debian?

Alpine Linux uses musl libc. The hurl 8.x upstream releases a single Linux binary linked against glibc — there is no musl build. Running a glibc binary on Alpine requires a compat layer that is fragile and not officially supported. This image uses **Debian bookworm-slim** (glibc) as the runtime base. All static Go binaries (k6, kubectl, helm, ghz, grpc_health_probe) work unchanged on both.

## What's Included

| Tool | Version | Purpose |
|------|---------|---------|
| flagger-loadtester | 0.37.0 | Canary webhook handler |
| hurl | 8.0.1 | HTTP assertion testing |
| k6 | v2.0.0 | Load testing |
| helm | v4.2.2 | Chart operations |
| kubectl | v1.36.2 | Cluster operations |
| bats | v1.13.0 | Bash-based test suites |
| ghz | v0.121.0 | gRPC benchmarking |
| grpc_health_probe | v0.4.52 | gRPC health checks |

## Canary Gate Flow

```mermaid
sequenceDiagram
    participant F as Flagger
    participant L as LoadTester
    participant H as hurl
    participant K as k6

    F->>L: pre-rollout webhook
    L->>H: hurl --test canary.hurl
    H-->>L: assertions pass
    L->>K: k6 run load-test.js
    K-->>L: p99 < threshold, error-rate < 1%
    L-->>F: 200 OK
    F->>F: promote canary
```
