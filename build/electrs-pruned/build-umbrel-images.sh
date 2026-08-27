#!/bin/bash
#
# Build and push the multi-architecture Docker image for Electrs Pruned (Umbrel).
#
# The image is identical to the one the StartOS package uses — same Dockerfile,
# same electrs submodule, same patches. What differs is only how it is
# configured at runtime: StartOS writes electrs.toml from its config actions and
# execs `electrs`, while the entrypoint here builds the same file from
# environment variables when ELECTRS_CONFIG_FROM_ENV=1. Umbrel has no settings
# form, so that is the only way a setting can reach the daemon.
#
# Prerequisites:
#   - docker login   (authenticate to Docker Hub as paulscode)
#   - a docker buildx builder with multi-arch support
#   - the electrs-pruned-startos repo checked out
#
# Usage:
#   ./build-umbrel-images.sh [--push]
#
# Without --push, the image is built locally (amd64 only).
# With --push, it is built for amd64+arm64 and pushed to Docker Hub.
# NOTE: the arm64 leg compiles electrs and rocksdb under QEMU and is slow.

set -euo pipefail

VERSION="0.11.1"
IMAGE="paulscode/electrs-pruned:${VERSION}"
PLATFORMS="linux/amd64,linux/arm64"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The build context is the StartOS wrapper repo: it holds the Dockerfile, the
# electrs submodule and the patches applied during the build. Unlike the other
# packages in this store, that repo lives inside the electrs-pruned checkout
# rather than beside umbrel-store, so the default path reflects that.
STARTOS_DIR="${ELECTRS_PRUNED_STARTOS_DIR:-/mnt/Black/pruned-electrs/packaging/electrs-pruned-startos}"

if [[ ! -f "${STARTOS_DIR}/Dockerfile" ]]; then
  echo "❌ Error: electrs-pruned-startos not found at ${STARTOS_DIR}"
  echo "   Clone https://github.com/paulscode/electrs-pruned-startos,"
  echo "   or set ELECTRS_PRUNED_STARTOS_DIR."
  exit 1
fi

if [[ ! -f "${STARTOS_DIR}/electrs/Cargo.toml" ]]; then
  echo "❌ Error: the electrs submodule at ${STARTOS_DIR}/electrs is empty."
  echo "   git -C ${STARTOS_DIR} submodule update --init --recursive"
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
echo "=== Building Electrs Pruned image ==="
echo "Image:      ${IMAGE}"
echo "Dockerfile: ${STARTOS_DIR}/Dockerfile"
echo "Context:    ${STARTOS_DIR}"
echo "Platforms:  ${PLATFORMS}"
echo ""

docker buildx build \
  --platform "${PLATFORMS}" \
  --tag "${IMAGE}" \
  --output "${OUTPUT}" \
  -f "${STARTOS_DIR}/Dockerfile" \
  "${STARTOS_DIR}"

echo ""
echo "✅ Done: ${IMAGE}"
if [[ "${1:-}" != "--push" ]]; then
  echo "   Re-run with --push to publish multi-arch."
else
  echo "   Pin it in the app's docker-compose.yml by tag AND digest:"
  echo "     docker buildx imagetools inspect ${IMAGE} --format '{{.Manifest.Digest}}'"
fi
