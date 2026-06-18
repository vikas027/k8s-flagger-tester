FROM ghcr.io/fluxcd/flagger-loadtester:0.37.0 AS loadtester
FROM bats/bats:1.13.0 AS bats

FROM debian:13-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG TARGETARCH
ARG HURL_VERSION=8.0.1
ARG K6_VERSION=v2.0.0
ARG HELM_VERSION=v4.2.2
ARG KUBECTL_VERSION=v1.36.2
ARG GHZ_VERSION=v0.121.0
ARG GRPC_HEALTH_PROBE_VERSION=v0.4.52

# I do not want to pin down the versions of the tools.
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl jq git libxml2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=loadtester /home/app/loadtester /home/app/loadtester

COPY --from=bats /opt/bats/ /opt/bats/
RUN ln -sf /opt/bats/bin/bats /usr/local/bin/bats

RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz -C /tmp \
    && install -m 0755 "/tmp/linux-${TARGETARCH}/helm" /usr/local/bin/helm \
    && rm -rf "/tmp/linux-${TARGETARCH}"

RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" -o /tmp/kubectl \
    && install -m 0755 /tmp/kubectl /usr/local/bin/kubectl \
    && rm /tmp/kubectl

RUN case "${TARGETARCH}" in \
        amd64) GHZ_ARCH="x86_64" ;; \
        arm64) GHZ_ARCH="arm64" ;; \
        *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/bojand/ghz/releases/download/${GHZ_VERSION}/ghz-linux-${GHZ_ARCH}.tar.gz" -o /tmp/ghz.tgz \
    && mkdir -p /tmp/ghz-bin \
    && tar -xzf /tmp/ghz.tgz -C /tmp/ghz-bin ghz \
    && install -m 0755 /tmp/ghz-bin/ghz /usr/local/bin/ghz \
    && rm -rf /tmp/ghz.tgz /tmp/ghz-bin

RUN curl -fsSL "https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-${TARGETARCH}" -o /tmp/grpc_health_probe \
    && install -m 0755 /tmp/grpc_health_probe /usr/local/bin/grpc_health_probe \
    && rm /tmp/grpc_health_probe

RUN mkdir -p /tmp/ghz \
    && curl -fsSL "https://raw.githubusercontent.com/grpc/grpc-proto/master/grpc/health/v1/health.proto" -o /tmp/ghz/health.proto

RUN case "${TARGETARCH}" in \
        amd64) HURL_ARCH="x86_64" ;; \
        arm64) HURL_ARCH="aarch64" ;; \
        *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/Orange-OpenSource/hurl/releases/download/${HURL_VERSION}/hurl-${HURL_VERSION}-${HURL_ARCH}-unknown-linux-gnu.tar.gz" -o /tmp/hurl.tgz \
    && tar -xzf /tmp/hurl.tgz -C /tmp \
    && install -m 0755 "/tmp/hurl-${HURL_VERSION}-${HURL_ARCH}-unknown-linux-gnu/bin/hurl" /usr/local/bin/hurl \
    && rm -rf /tmp/hurl.tgz "/tmp/hurl-${HURL_VERSION}-${HURL_ARCH}-unknown-linux-gnu" \
    && hurl --version

RUN curl -fsSL "https://github.com/grafana/k6/releases/download/${K6_VERSION}/k6-${K6_VERSION}-linux-${TARGETARCH}.tar.gz" -o /tmp/k6.tgz \
    && tar -xzf /tmp/k6.tgz -C /tmp \
    && install -m 0755 "/tmp/k6-${K6_VERSION}-linux-${TARGETARCH}/k6" /usr/local/bin/k6 \
    && rm -rf /tmp/k6.tgz "/tmp/k6-${K6_VERSION}-linux-${TARGETARCH}" \
    && k6 version

RUN groupadd -r app && \
    useradd -r -g app app && \
    mkdir -p /home/app && \
    chown -R app:app /home/app && \
    chown -R app:app /tmp/ghz

WORKDIR /home/app

USER app

RUN set -eu; \
    for tool in helm kubectl ghz grpc_health_probe hurl k6 bats; do \
      echo "--- ${tool} ---"; \
      case "${tool}" in \
        kubectl) "${tool}" version --client ;; \
        helm|k6) "${tool}" version ;; \
        *)       "${tool}" --version ;; \
      esac; \
    done

ENTRYPOINT ["./loadtester"]
