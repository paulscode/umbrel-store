#!/bin/bash
#
# Build and push the multi-architecture Docker image for the Frigate companions (Umbrel):
# paulscode-frigate-sha256 and paulscode-frigate-blake2b run the same image.
#
# The image is the one the StartOS packages build: the same Dockerfile and patches (Frigate 1.6.1
# from source, a BLAKE2b-aware drongo, laid over ghcr.io/remcoros/frigate-docker). The two StartOS
# packages share both, so the SHA256 package is the build context. Only the runtime configuration
# differs: StartOS writes config.toml from its actions, the Umbrel apps' compose from the variables
# Umbrel injects and the app page's settings.
#
# Prerequisites:
#   - docker login   (authenticate to Docker Hub as paulscode)
#   - a docker buildx builder with multi-arch support
#   - the frigate-sha256-companion-startos package checked out
#
# Usage:
#   ./build-umbrel-images.sh [--push]
#
# Without --push, the image is built locally (amd64 only).
# With --push, it is built for amd64+arm64 and pushed to Docker Hub. The arm64 leg builds Frigate
# under QEMU (its tests are skipped there; see the Dockerfile) and takes a while.

set -euo pipefail

PLATFORMS="linux/amd64,linux/arm64"

STARTOS_DIR="${FRIGATE_COMPANION_STARTOS_DIR:-/mnt/Black/knots-forks/frigate-sha256-companion-startos}"

if [[ ! -f "${STARTOS_DIR}/Dockerfile" ]] || [[ ! -d "${STARTOS_DIR}/patches" ]]; then
  echo "Error: the Frigate (SHA256) Companion package not found at ${STARTOS_DIR}"
  echo "   Clone https://github.com/paulscode/frigate-sha256-companion-startos,"
  echo "   or set FRIGATE_COMPANION_STARTOS_DIR."
  exit 1
fi

# The package's own version (1.6.1:0 in startos/versions/current.ts is image 1.6.1.0), so the image
# cannot be built or pushed under a version the package is not at.
PKG_VERSION=$(sed -n "s/^ *version: '\([0-9.]*\):\([0-9]*\)',$/\1.\2/p" "${STARTOS_DIR}/startos/versions/current.ts" | head -1)
[[ -n "${PKG_VERSION}" ]] || { echo "Error: could not read the version from ${STARTOS_DIR}/startos/versions/current.ts"; exit 1; }
VERSION="${PKG_VERSION}"
IMAGE="paulscode/frigate-companion:${VERSION}"

# A multi-arch builder, named for this build only: `docker buildx use` would change the default for
# every later docker build on this machine.
BUILDER=$(docker buildx ls | grep -E '^\S+.*docker-container.*' | head -1 | awk '{gsub(/\*$/,"",$1); print $1}' || true)
BUILDER_ARGS=()
if [[ -n "${BUILDER}" ]]; then
  echo "Using buildx builder: ${BUILDER}"
  BUILDER_ARGS=(--builder "${BUILDER}")
fi

if [[ "${1:-}" == "--push" ]]; then
  # A pushed image must come from the released package exactly: a clean checkout at its tag.
  if [[ -n "$(git -C "${STARTOS_DIR}" status --porcelain)" ]]; then
    echo "Error: ${STARTOS_DIR} has uncommitted changes; push only from a clean checkout of v${VERSION}."
    exit 1
  fi
  if [[ "$(git -C "${STARTOS_DIR}" describe --tags --exact-match 2>/dev/null)" != "v${VERSION}" ]]; then
    echo "Error: ${STARTOS_DIR} is not at the tag v${VERSION} (release the package first, then check it out)."
    exit 1
  fi
  OUTPUT="type=registry"
  echo "Building and PUSHING multi-arch image to Docker Hub"
else
  OUTPUT="type=docker"
  PLATFORMS="linux/amd64"
  echo "Building image locally (amd64 only; use --push to publish multi-arch)"
fi

echo "Image: ${IMAGE}  Platforms: ${PLATFORMS}"
docker buildx build "${BUILDER_ARGS[@]}" \
  --platform "${PLATFORMS}" \
  --tag "${IMAGE}" \
  --output "${OUTPUT}" \
  -f "${STARTOS_DIR}/Dockerfile" \
  "${STARTOS_DIR}"

if [[ "${1:-}" == "--push" ]]; then
  echo
  echo "Pushed. Pin it in both apps' docker-compose.yml as ${IMAGE}@<index digest>:"
  docker buildx imagetools inspect "${IMAGE}" | sed -n 1,4p
fi
