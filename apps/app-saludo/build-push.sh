#!/usr/bin/env bash
# Construye y publica la imagen de app-saludo para amd64 (Linux/Intel) y arm64 (Mac Apple Silicon).
# Uso: ./build-push.sh            (publica :v1)
#      TAG=v2 ./build-push.sh
# Requiere: docker buildx y haber hecho login en ghcr.io (ver README.md).
set -euo pipefail

REPO="${REPO:-ghcr.io/matias-craftech/kubernetes-explicado-con-crayones/app-saludo}"
TAG="${TAG:-v1}"
IMAGE="$REPO:$TAG"
DIR="$(cd "$(dirname "$0")" && pwd)"

# El driver por defecto de Docker puede no soportar multi-plataforma: usamos un builder propio.
if ! docker buildx inspect crayones-builder >/dev/null 2>&1; then
  docker buildx create --name crayones-builder --driver docker-container >/dev/null
fi

docker buildx build \
  --builder crayones-builder \
  --platform linux/amd64,linux/arm64 \
  --tag "$IMAGE" \
  --push \
  "$DIR/src"

echo
echo "Publicada: $IMAGE"
docker buildx imagetools inspect "$IMAGE" | grep -E 'Name:|Platform:'
echo
echo "IMPORTANTE: la primera vez, GHCR publica el paquete como PRIVADO."
echo "Hacerlo público en: https://github.com/users/matias-craftech/packages/container/package/kubernetes-explicado-con-crayones%2Fapp-saludo"
echo "(Package settings -> Change visibility -> Public)"
