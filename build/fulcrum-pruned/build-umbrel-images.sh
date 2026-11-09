#!/bin/bash
#
# Build and push the multi-architecture Docker image for Fulcrum Pruned (Umbrel).
#
# The image is the one the StartOS package builds: same Dockerfile, same fulcrum
# submodule (privkeyio's BLAKE2b fork), same patches. Only the runtime
# configuration differs: StartOS writes fulcrum.conf from its actions, while the
# Umbrel app's compose command writes it from the variables Umbrel injects.
#
# Prerequisites:
#   - docker login   (authenticate to Docker Hub as paulscode)
#   - a docker buildx builder with multi-arch support
#   - the paulscode/fulcrum-pruned repo checked out, with its submodule
#
# Usage:
#   ./build-umbrel-images.sh [--push]
#
# Without --push, the image is built locally (amd64 only).
# With --push, it is built for amd64+arm64 and pushed to Docker Hub.
# NOTE: the arm64 leg compiles Fulcrum and RocksDB under QEMU and is slow.

set -euo pipefail

VERSION="2.1.4.0"
IMAGE="paulscode/fulcrum-pruned:${VERSION}"
PLATFORMS="linux/amd64,linux/arm64"

STARTOS_DIR="${FULCRUM_PRUNED_STARTOS_DIR:-/mnt/Black/fulcrum-pruned/packaging/fulcrum-pruned-startos}"

if [[ ! -f "${STARTOS_DIR}/Dockerfile" ]]; then
  echo "Error: the Fulcrum Pruned package (paulscode/fulcrum-pruned) not found at ${STARTOS_DIR}"
  echo "   Clone https://github.com/paulscode/fulcrum-pruned,"
  echo "   or set FULCRUM_PRUNED_STARTOS_DIR."
  exit 1
fi
if [[ ! -f "${STARTOS_DIR}/fulcrum/Fulcrum.pro" ]]; then
  echo "Error: the fulcrum submodule at ${STARTOS_DIR}/fulcrum is empty."
  echo "   git -C ${STARTOS_DIR} submodule update --init"
  exit 1
fi

# The submodule's .git is a file pointing outside the build context, so the
# build cannot read the commit itself. Same value the StartOS Makefile passes.
COMMIT="$(git -C "${STARTOS_DIR}/fulcrum" describe --always --dirty --match 'NOT A TAG')+pruned"

BUILDER=$(docker buildx ls | grep -E '^\S+.*docker-container.*' | head -1 | awk '{gsub(/\*$/,"",$1); print $1}' || true)
if [[ -n "${BUILDER}" ]]; then
  echo "Using buildx builder: ${BUILDER}"
  docker buildx use "${BUILDER}"
fi

if [[ "${1:-}" == "--push" ]]; then
  OUTPUT="type=registry"
  echo "Building and PUSHING multi-arch image to Docker Hub"
else
  OUTPUT="type=docker"
  PLATFORMS="linux/amd64"
  echo "Building image locally (amd64 only; use --push to publish multi-arch)"
fi

echo "Image: ${IMAGE}  Commit: ${COMMIT}  Platforms: ${PLATFORMS}"
docker buildx build \
  --platform "${PLATFORMS}" \
  --build-arg "FULCRUM_GIT_COMMIT=${COMMIT}" \
  --tag "${IMAGE}" \
  --output "${OUTPUT}" \
  -f "${STARTOS_DIR}/Dockerfile" \
  "${STARTOS_DIR}"

echo "Done: ${IMAGE}"
if [[ "${1:-}" == "--push" ]]; then
  echo "   Pin it in the app's docker-compose.yml by tag AND digest:"
  echo "     docker buildx imagetools inspect ${IMAGE} --format '{{.Manifest.Digest}}'"
fi
