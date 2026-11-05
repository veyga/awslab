# GitHub Actions runner image for the ARC scale sets: the public actions-runner image plus
# the tooling our jobs need. Built and pushed to ECR by .github/workflows/runner-image.yml.
#
# The base image already ships the docker CLI + buildx, git, jq, curl and unzip. Jobs only
# get a docker daemon when the scale set runs in dind container mode.

ARG RUNNER_VERSION=2.338.2
ARG UV_VERSION=0.13.7

# uv publishes a scratch image holding just the static binaries
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

# ---------------------------------------------------------------------------------------
# fetch: download + checksum every tool into /out, so the final image needs no build deps
# ---------------------------------------------------------------------------------------
FROM ubuntu:24.04 AS fetch

ARG TARGETARCH
ARG HELM_VERSION=4.3.1
ARG KUBECTL_VERSION=1.37.2
ARG TERRAFORM_VERSION=1.17.1
ARG TERRAGRUNT_VERSION=1.2.1
ARG JUST_VERSION=1.59.0

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl unzip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/dl
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN mkdir -p /out/bin; \
  case "${TARGETARCH}" in \
    amd64) UNAME_ARCH=x86_64 ;; \
    arm64) UNAME_ARCH=aarch64 ;; \
    *) echo "unsupported arch ${TARGETARCH}" >&2; exit 1 ;; \
  esac; \
  echo "${UNAME_ARCH}" > /tmp/uname_arch

# helm
RUN f="helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz"; \
  curl -fsSLO "https://get.helm.sh/${f}"; \
  curl -fsSLO "https://get.helm.sh/${f}.sha256sum"; \
  sha256sum -c "${f}.sha256sum"; \
  tar -xzf "${f}" -C /tmp/dl; \
  install -m 755 "/tmp/dl/linux-${TARGETARCH}/helm" /out/bin/helm

# kubectl
RUN base="https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}"; \
  curl -fsSLO "${base}/kubectl"; \
  echo "$(curl -fsSL "${base}/kubectl.sha256")  kubectl" | sha256sum -c -; \
  install -m 755 kubectl /out/bin/kubectl

# terraform
RUN f="terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip"; \
  base="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}"; \
  curl -fsSLO "${base}/${f}"; \
  curl -fsSL "${base}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" | grep " ${f}\$" | sha256sum -c -; \
  unzip -q "${f}" terraform; \
  install -m 755 terraform /out/bin/terraform

# terragrunt
RUN f="terragrunt_linux_${TARGETARCH}"; \
  base="https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}"; \
  curl -fsSLO "${base}/${f}"; \
  curl -fsSL "${base}/SHA256SUMS" | grep " ${f}\$" | sha256sum -c -; \
  install -m 755 "${f}" /out/bin/terragrunt

# just
RUN f="just-${JUST_VERSION}-$(cat /tmp/uname_arch)-unknown-linux-musl.tar.gz"; \
  base="https://github.com/casey/just/releases/download/${JUST_VERSION}"; \
  curl -fsSLO "${base}/${f}"; \
  curl -fsSL "${base}/SHA256SUMS" | grep " ${f}\$" | sha256sum -c -; \
  tar -xzf "${f}" just; \
  install -m 755 just /out/bin/just

# aws cli v2 (self-contained bundle; AWS only publishes a "latest" zip + PGP signature).
# The installer writes absolute symlinks, so install at the same path the final image uses.
RUN curl -fsSL -o awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-$(cat /tmp/uname_arch).zip"; \
  unzip -q awscliv2.zip; \
  ./aws/install --install-dir /usr/local/aws-cli --bin-dir /tmp/aws-bin

# ---------------------------------------------------------------------------------------
# final runner image
# ---------------------------------------------------------------------------------------
FROM ghcr.io/actions/actions-runner:${RUNNER_VERSION}

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends make zip gettext-base skopeo \
  && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=fetch /out/bin/ /usr/local/bin/
COPY --from=fetch /usr/local/aws-cli /usr/local/aws-cli
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws \
  && ln -s /usr/local/aws-cli/v2/current/bin/aws_completer /usr/local/bin/aws_completer

# fail the build if any tool is missing or can't run on this arch
RUN docker --version \
  && uv --version \
  && helm version --short \
  && kubectl version --client \
  && aws --version \
  && terraform version \
  && terragrunt --version \
  && just --version \
  && skopeo --version

# ARC starts the container with /home/runner/run.sh as the runner user
USER runner
