#!/bin/bash
#
# Build and push multi-architecture Docker images for Mempool BIP-110 (Umbrel)
#
# Prerequisites:
#   - docker login (authenticate to Docker Hub as paulscode)
#   - docker buildx builder with multi-arch support
#
# Usage:
#   ./build-umbrel-images.sh [--push]
#
# Without --push, images are built locally (amd64 only).
# With --push, images are built for amd64+arm64 and pushed to Docker Hub.

set -euo pipefail

VERSION="v3.2.1.3"
FRONTEND_IMAGE="paulscode/mempool-bip110-frontend:${VERSION}"
BACKEND_IMAGE="paulscode/mempool-bip110-backend:${VERSION}"
PLATFORMS="linux/amd64,linux/arm64"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The mempool-bip110 source tree is not part of this store repo. Point
# MEMPOOL_BIP110_DIR at your checkout; the default matches the author's layout.
MEMPOOL_DIR="${MEMPOOL_BIP110_DIR:-/mnt/1Lane/bip110-apps/mempool-bip110}"
DOCKER_DIR="${SCRIPT_DIR}/docker"

# Verify mempool-bip110 source exists
if [[ ! -d "${MEMPOOL_DIR}/frontend" ]] || [[ ! -d "${MEMPOOL_DIR}/backend" ]]; then
  echo "❌ Error: mempool-bip110 source not found at ${MEMPOOL_DIR}"
  echo "   Set MEMPOOL_BIP110_DIR to your mempool-bip110 checkout."
  exit 1
fi

# Select builder with multi-arch support
BUILDER=$(docker buildx ls | grep -E '^\S+.*docker-container.*' | head -1 | awk '{gsub(/\*$/,"",$1); print $1}' || true)
if [[ -n "${BUILDER}" ]]; then
  echo "📦 Using buildx builder: ${BUILDER}"
  docker buildx use "${BUILDER}"
fi

if [[ "${1:-}" == "--push" ]]; then
  OUTPUT="type=registry"
  echo "🚀 Building and PUSHING multi-arch images to Docker Hub"
else
  OUTPUT="type=docker"
  PLATFORMS="linux/amd64"
  echo "🔨 Building images locally (amd64 only; use --push to publish multi-arch)"
fi

echo ""
echo "=== Building Frontend Image ==="
echo "Image:      ${FRONTEND_IMAGE}"
echo "Dockerfile: ${DOCKER_DIR}/Dockerfile.frontend"
echo "Context:    ${MEMPOOL_DIR}"
echo "Platforms:  ${PLATFORMS}"
echo ""

# Ensure mining pool logos are present (they are .gitignored in mempool-bip110)
echo "📋 Copying mining pool logos into build context..."
mkdir -p "${MEMPOOL_DIR}/frontend/src/resources/mining-pools"
cp -n "${DOCKER_DIR}/mining-pools/"*.svg "${MEMPOOL_DIR}/frontend/src/resources/mining-pools/" 2>/dev/null || true

docker buildx build \
  --platform "${PLATFORMS}" \
  --tag "${FRONTEND_IMAGE}" \
  --output "${OUTPUT}" \
  -f "${DOCKER_DIR}/Dockerfile.frontend" \
  "${MEMPOOL_DIR}"

echo ""
echo "✅ Frontend image built: ${FRONTEND_IMAGE}"
echo ""

echo "=== Building Backend Image ==="
echo "Image:      ${BACKEND_IMAGE}"
echo "Dockerfile: ${DOCKER_DIR}/Dockerfile.backend"
echo "Context:    ${MEMPOOL_DIR}"
echo "Platforms:  ${PLATFORMS}"
echo ""

docker buildx build \
  --platform "${PLATFORMS}" \
  --tag "${BACKEND_IMAGE}" \
  --output "${OUTPUT}" \
  -f "${DOCKER_DIR}/Dockerfile.backend" \
  "${MEMPOOL_DIR}"

echo ""
echo "✅ Backend image built: ${BACKEND_IMAGE}"
echo ""

if [[ "${1:-}" == "--push" ]]; then
  echo "=== Image Digests ==="
  echo ""
  echo "Frontend:"
  docker buildx imagetools inspect "${FRONTEND_IMAGE}" --format '{{.Manifest.Digest}}'
  echo ""
  echo "Backend:"
  docker buildx imagetools inspect "${BACKEND_IMAGE}" --format '{{.Manifest.Digest}}'
  echo ""
  echo "📝 Pin these digests in paulscode-mempool-bip110/docker-compose.yml"
  echo "   e.g. paulscode/mempool-bip110-frontend:v3.2.1@sha256:<digest>"
fi

echo ""
echo "🎉 Done!"
