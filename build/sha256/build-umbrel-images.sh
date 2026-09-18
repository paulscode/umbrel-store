#!/bin/bash
#
# Build and push the multi-architecture Docker image for Datum (SHA256) (Umbrel).
#
# The image is identical to the one the StartOS package uses: same Dockerfile,
# same pinned datum_gateway commit, same env-driven entrypoint. What differs on
# Umbrel is only how it is wired up, which lives in the compose file.
#
# Why this is not built by build/blake2b/build-umbrel-images.sh, which builds the
# other Datum image: the two packages no longer build from the same commit. The
# BLAKE2b package builds from the Convoy fork, because only Convoy's fork can talk
# to the pool that serves that chain, and this one builds from master, which
# tracks OCEAN. Feeding the Convoy build to a SHA256 miner would put Convoy's
# protocol extensions in front of a pool that does not speak them.
#
# They did once share an image. `paulscode/datum-blake2b:1.0.12`, which this app
# was pinned to until now, was built from beb9461 on master, so its contents were
# always the OCEAN line and only its name said otherwise. That name stopped being
# merely untidy when the BLAKE2b package moved to Convoy's fork, because the next
# tag in that repository is a different codebase. Hence a repository of its own.
#
# Changing which image the app pulls is an ordinary update. The Umbrel app id is
# `paulscode-datum-sha256` and does not change, so the app keeps its settings and
# its data directory, and Docker reuses every layer it already has by content
# rather than by repository name.
#
# Prerequisites:
#   - docker login   (authenticate to Docker Hub as paulscode)
#   - a docker buildx builder with multi-arch support
#   - the datum-sha256-startos package checked out
#
# Usage:
#   ./build-umbrel-images.sh [--push]
#
# Without --push, the image is built locally (amd64 only).
# With --push, it is built for amd64+arm64 and pushed to Docker Hub.

set -euo pipefail

VERSION="1.0.0"
IMAGE="paulscode/datum-sha256:${VERSION}"
PLATFORMS="linux/amd64,linux/arm64"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Like the BLAKE2b pair, this package is not checked out under ~/workspace beside
# umbrel-store; it lives in the Knots forks workspace alongside the StartOS
# tooling it was built with. Override with SHA256_STARTOS_DIR if yours is
# elsewhere.
STARTOS_DIR="${SHA256_STARTOS_DIR:-/mnt/Black/knots-forks/datum-sha256-startos}"

if [[ ! -f "${STARTOS_DIR}/Dockerfile" ]]; then
  echo "❌ Error: datum-sha256-startos not found at ${STARTOS_DIR}"
  echo "   Check it out, or set SHA256_STARTOS_DIR to the workspace holding it."
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
echo "=== Building Datum (SHA256) image ==="
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
