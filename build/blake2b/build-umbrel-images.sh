#!/bin/bash
#
# Build and push the multi-architecture Docker images for the BLAKE2b pair
# (Umbrel): the Knots node and the Datum gateway.
#
# One script for two images because they are one experiment. The node enforces
# the proposed BLAKE2b rules and the gateway hands that work to a Sia ASIC;
# neither is useful alone, they share a headline that has to match, and they are
# released together. Building them separately invites a pair that has drifted.
#
# The images are identical to the ones the StartOS packages use — same
# Dockerfiles, same pinned upstream commits, same env-driven entrypoints. What
# differs on Umbrel is only how they are wired up, which lives in the compose
# files, not in the images.
#
# Prerequisites:
#   - docker login   (authenticate to Docker Hub as paulscode)
#   - a docker buildx builder with multi-arch support
#   - the two StartOS packaging repos checked out
#
# Usage:
#   ./build-umbrel-images.sh [--push] [knots|datum]
#
# Without --push, images are built locally (amd64 only).
# With --push, they are built for amd64+arm64 and pushed to Docker Hub.
# NOTE: the arm64 leg compiles Bitcoin Knots under QEMU and is slow the first
# time. Afterwards the layer cache makes it quick.

set -euo pipefail

# Versioned separately. The pair is released together, but a fix to one is not a
# reason to make everybody re-pull the other, and Umbrel offers an update per app.
KNOTS_VERSION="1.0.1"
DATUM_VERSION="1.0.2"
PLATFORMS="linux/amd64,linux/arm64"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Unlike the other apps here, these two repos are not checked out under
# ~/workspace next to umbrel-store; they live in the BLAKE2b lab workspace
# alongside the StartOS tooling they were built with. Override with
# BLAKE2B_STARTOS_DIR if yours is elsewhere.
STARTOS_DIR="${BLAKE2B_STARTOS_DIR:-/mnt/Black/bitcoin-blake2b-regtest/startos}"

PUSH=""
WHICH="both"
for arg in "$@"; do
  case "$arg" in
    --push)        PUSH=1 ;;
    knots|datum)   WHICH="$arg" ;;
    *) echo "usage: $(basename "$0") [--push] [knots|datum]" >&2; exit 1 ;;
  esac
done

if [[ -n "${PUSH}" ]]; then
  OUTPUT="type=registry"
  echo "🚀 Building and PUSHING multi-arch images to Docker Hub"
else
  OUTPUT="type=docker"
  PLATFORMS="linux/amd64"
  echo "🔨 Building images locally (amd64 only; use --push to publish multi-arch)"
fi

# Select a buildx builder with multi-arch support, if one exists.
BUILDER=$(docker buildx ls | grep -E '^\S+.*docker-container.*' | head -1 | awk '{gsub(/\*$/,"",$1); print $1}' || true)
if [[ -n "${BUILDER}" ]]; then
  echo "📦 Using buildx builder: ${BUILDER}"
  docker buildx use "${BUILDER}"
fi

build_one() {
  local name="$1" repo="$2" version="$3" image="paulscode/$1:$3"
  local ctx="${STARTOS_DIR}/${repo}"

  if [[ ! -f "${ctx}/Dockerfile" ]]; then
    echo "❌ Error: ${repo} not found at ${ctx}"
    echo "   Check it out, or set BLAKE2B_STARTOS_DIR to the workspace holding it."
    exit 1
  fi

  echo ""
  echo "=== Building ${name} ==="
  echo "Image:      ${image}"
  echo "Context:    ${ctx}"
  echo "Platforms:  ${PLATFORMS}"
  echo ""

  docker buildx build \
    --platform "${PLATFORMS}" \
    --tag "${image}" \
    --tag "paulscode/${name}:latest" \
    --output "${OUTPUT}" \
    "${ctx}"

  echo "✅ Image built: ${image}"

  if [[ -n "${PUSH}" ]]; then
    echo "=== Digest ==="
    docker buildx imagetools inspect "${image}" --format '{{.Manifest.Digest}}'
  fi
}

[[ "${WHICH}" == "both" || "${WHICH}" == "knots" ]] && \
  build_one knots-blake2b knots-blake2b-startos "${KNOTS_VERSION}"
[[ "${WHICH}" == "both" || "${WHICH}" == "datum" ]] && \
  build_one datum-blake2b datum-blake2b-startos "${DATUM_VERSION}"

if [[ -n "${PUSH}" ]]; then
  echo ""
  echo "📝 Pin the digests above in each app's docker-compose.yml, e.g.:"
  echo "   image: paulscode/knots-blake2b:${KNOTS_VERSION}@sha256:<digest>"
  echo "   image: paulscode/datum-blake2b:${DATUM_VERSION}@sha256:<digest>"
  echo "   (the gateway digest appears three times: gateway, capture, report)"
fi

echo ""
echo "🎉 Done!"
