#!/bin/bash
#
# Build and push the multi-architecture Docker image for Electrs Liquid (Umbrel).
#
# The image is identical to the one used by the StartOS package — it is built
# from the same Dockerfile in the electrs-liquid-startos repo, which bundles
# elementsd + electrs (--features liquid) behind an env-driven entrypoint.
#
# Prerequisites:
#   - docker login   (authenticate to Docker Hub as paulscode)
#   - a docker buildx builder with multi-arch support
#   - the electrs-liquid-startos repo checked out next to this one
#
# Usage:
#   ./build-umbrel-images.sh [--push]
#
# Without --push, the image is built locally (amd64 only).
# With --push, it is built for amd64+arm64 and pushed to Docker Hub.
# NOTE: the arm64 leg cross-compiles electrs under QEMU and is slow.

set -euo pipefail

VERSION="0.1.0"
IMAGE="paulscode/elements-electrs:${VERSION}"
PLATFORMS="linux/amd64,linux/arm64"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The build context is the StartOS wrapper repo (Dockerfile + docker/ inputs).
# This script lives at umbrel-store/build/electrs-liquid/, so the StartOS repo
# (checked out under ~/workspace next to umbrel-store) is three levels up.
# Override with ELECTRS_LIQUID_STARTOS_DIR if it lives elsewhere.
STARTOS_DIR="${ELECTRS_LIQUID_STARTOS_DIR:-${SCRIPT_DIR}/../../../electrs-liquid-startos}"

if [[ ! -f "${STARTOS_DIR}/Dockerfile" ]]; then
  echo "❌ Error: electrs-liquid-startos not found at ${STARTOS_DIR}"
  echo "   Clone it next to this repo, or set ELECTRS_LIQUID_STARTOS_DIR."
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
echo "=== Building Electrs Liquid image ==="
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
echo "✅ Image built: ${IMAGE}"

if [[ "${1:-}" == "--push" ]]; then
  echo ""
  echo "=== Image Digest ==="
  docker buildx imagetools inspect "${IMAGE}" --format '{{.Manifest.Digest}}'
  echo ""
  echo "📝 Pin this digest in paulscode-electrs-liquid/docker-compose.yml, e.g.:"
  echo "   image: ${IMAGE}@sha256:<digest>"
fi

echo ""
echo "🎉 Done!"
