#!/usr/bin/env bash
# Usage: ./rollback.sh <previous-image-tag>
# Example: ./rollback.sh abc1234

set -euo pipefail

IMAGE="${DOCKER_IMAGE:?Set DOCKER_IMAGE env var (e.g. your-user/health-system-api)}"
TAG="${1:?Provide the image tag to roll back to}"

echo "Rolling back Health System API to $IMAGE:$TAG ..."
export IMAGE_TAG="$TAG"
docker compose pull app
docker compose up -d --no-deps app
echo "Rollback complete. Running tag: $TAG"
