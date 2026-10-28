#!/bin/bash
#
# Build and push the multi-architecture app image for Knots (SHA256) and
# Knots (SHA256) Companion (Umbrel). Both apps pin the same image by digest.
#
# The image is paulscode/umbrel-bitcoin-knots-sha256, a small fork of
# Retropex/umbrel-bitcoin (the web interface the official Bitcoin Knots app runs)
# whose one bitcoind is the published Bitcoin Knots SHA256 release: its
# Dockerfile downloads the reproducible Guix build and verifies SHA256SUMS.asc
# against the maintainer's pinned key, and the build fails if it does not
# verify. So there is no separate node image to build first, and nothing is
# compiled here; the arm64 leg is quick. What the fork changes is listed in its
# KNOTS-SHA256.md.
#
# Prerequisites:
#   - docker login   (authenticate to Docker Hub as paulscode)
#   - a docker buildx builder with multi-arch support
#   - the umbrel-bitcoin-knots-sha256 fork checked out
#
# Usage:
#   ./build-umbrel-images.sh [--push]
#
# Without --push, the image is built locally (amd64 only).
# With --push, it is built for amd64+arm64 and pushed to Docker Hub.

set -euo pipefail

# App image version: the Bitcoin Knots SHA256 base (31.1) plus this image's own
# revision. The node release inside is set by KNOTS_SHA256_VERSION in the fork's
# Dockerfile.
VERSION="31.1.0"
IMAGE="paulscode/umbrel-bitcoin-knots-sha256:${VERSION}"
PLATFORMS="linux/amd64,linux/arm64"

SRC_DIR="${UMBREL_BITCOIN_KNOTS_SHA256_DIR:-${HOME}/workspace/umbrel-bitcoin-knots-sha256}"

if [[ ! -f "${SRC_DIR}/apps/backend/Dockerfile" ]]; then
  echo "❌ Error: umbrel-bitcoin-knots-sha256 not found at ${SRC_DIR}"
  echo "   Check it out, or set UMBREL_BITCOIN_KNOTS_SHA256_DIR."
  exit 1
fi

PUSH=""
for arg in "$@"; do
  case "$arg" in
    --push) PUSH=1 ;;
    *) echo "usage: $(basename "$0") [--push]" >&2; exit 1 ;;
  esac
done

if [[ -n "${PUSH}" ]]; then
  OUTPUT="type=registry"
  echo "🚀 Building and PUSHING ${IMAGE} (multi-arch) to Docker Hub"
else
  OUTPUT="type=docker"
  PLATFORMS="linux/amd64"
  echo "🔨 Building ${IMAGE} locally (amd64 only; use --push to publish multi-arch)"
fi

BUILDER=$(docker buildx ls | grep -E '^\S+.*docker-container.*' | head -1 | awk '{gsub(/\*$/,"",$1); print $1}' || true)
if [[ -n "${BUILDER}" ]]; then
  echo "📦 Using buildx builder: ${BUILDER}"
  docker buildx use "${BUILDER}"
fi

docker buildx build \
  --platform "${PLATFORMS}" \
  --file "${SRC_DIR}/apps/backend/Dockerfile" \
  --tag "${IMAGE}" \
  --output "${OUTPUT}" \
  "${SRC_DIR}"

echo "✅ Image built: ${IMAGE}"

if [[ -n "${PUSH}" ]]; then
  echo "=== Digest (pin it in BOTH apps' docker-compose.yml) ==="
  docker buildx imagetools inspect "${IMAGE}" --format '{{.Manifest.Digest}}'
fi
