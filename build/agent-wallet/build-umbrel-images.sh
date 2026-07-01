#!/bin/bash
#
# Build and push the multi-architecture Docker image for Agent Wallet (Umbrel).
#
# The image is built from the agent-wallet-startos repo's Dockerfile.umbrel — the
# same infrastructure layering as the StartOS package (PostgreSQL + Redis + Tor +
# the BOLT 12 gateway, supervised by s6-overlay), with an Umbrel-specific
# entrypoint (docker_entrypoint_umbrel.sh) that maps Umbrel's environment/mounts
# to the app's env. It pins the same app + gateway base images as the 0.4.17.0
# StartOS release, so both packages run byte-identical binaries.
#
# Prerequisites:
#   - docker login            (authenticate to Docker Hub as paulscode)
#   - a docker buildx builder with multi-arch support
#   - the agent-wallet-startos repo checked out next to this one
#
# Usage:
#   ./build-umbrel-images.sh [--push]
#
# Without --push, the image is built locally (amd64 only).
# With --push, it is built for amd64+arm64 and pushed to Docker Hub.
# NOTE: the arm64 leg cross-builds the Python deps under QEMU and is slow.

set -euo pipefail

VERSION="0.4.17.0"
IMAGE="paulscode/agent-wallet-umbrel:${VERSION}"
PLATFORMS="linux/amd64,linux/arm64"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The build context + Dockerfile come from the StartOS wrapper repo (single source
# of the infra layering and entrypoints).
# This script lives at umbrel-store/build/agent-wallet/, so the StartOS repo
# (checked out under ~/workspace next to umbrel-store) is three levels up.
# Override with AGENT_WALLET_STARTOS_DIR if it lives elsewhere.
STARTOS_DIR="${AGENT_WALLET_STARTOS_DIR:-${SCRIPT_DIR}/../../../agent-wallet-startos}"

if [[ ! -f "${STARTOS_DIR}/Dockerfile.umbrel" ]]; then
  echo "❌ Error: agent-wallet-startos not found at ${STARTOS_DIR}"
  echo "   (need Dockerfile.umbrel). Clone it next to this repo, or set"
  echo "   AGENT_WALLET_STARTOS_DIR."
  exit 1
fi

# Select a buildx builder with multi-arch support, if one exists.
BUILDER=$(docker buildx ls | grep -E '^\S+.*docker-container.*' | head -1 | awk '{gsub(/\*$/,"",$1); print $1}' || true)
if [[ -n "${BUILDER}" ]]; then
  echo "📦 Using buildx builder: ${BUILDER}"
  docker buildx use "${BUILDER}"
fi

if [[ "${1:-}" == "--push" ]]; then
  OUTPUT="type=registry"
  echo "🚀 Building and PUSHING multi-arch image to Docker Hub"
else
  OUTPUT="type=docker"
  PLATFORMS="linux/amd64"
  echo "🔨 Building image locally (amd64 only; use --push to publish multi-arch)"
fi

echo ""
echo "=== Building Agent Wallet (Umbrel) image ==="
echo "Image:      ${IMAGE}"
echo "Dockerfile: ${STARTOS_DIR}/Dockerfile.umbrel"
echo "Context:    ${STARTOS_DIR}"
echo "Platforms:  ${PLATFORMS}"
echo ""

docker buildx build \
  --platform "${PLATFORMS}" \
  --tag "${IMAGE}" \
  --output "${OUTPUT}" \
  -f "${STARTOS_DIR}/Dockerfile.umbrel" \
  "${STARTOS_DIR}"

echo ""
echo "✅ Image built: ${IMAGE}"

if [[ "${1:-}" == "--push" ]]; then
  echo ""
  echo "=== Image Digest ==="
  docker buildx imagetools inspect "${IMAGE}" --format '{{.Manifest.Digest}}'
  echo ""
  echo "📝 Pin this digest in paulscode-agent-wallet/docker-compose.yml, e.g.:"
  echo "   image: ${IMAGE}@sha256:<digest>"
fi

echo ""
echo "🎉 Done!"
