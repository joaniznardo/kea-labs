#!/bin/bash
# Script per construir les imatges Docker necessàries per al laboratori Kea
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Construcció d'imatges Docker per al laboratori Kea ==="

# Construir imatge del relay DHCP
echo ""
echo ">>> Construint imatge kea-relay..."
docker build -t kea-relay:latest -f "$BASE_DIR/base/docker/Dockerfile.relay" "$BASE_DIR/base/docker/"
echo "    kea-relay:latest construïda correctament"

# Construir imatge Kea amb Stork agent (només si existeix el Dockerfile)
if [ -f "$BASE_DIR/fase4-stork/docker/Dockerfile.kea-stork" ]; then
    echo ""
    echo ">>> Construint imatge kea-stork..."
    docker build -t kea-stork:latest -f "$BASE_DIR/fase4-stork/docker/Dockerfile.kea-stork" "$BASE_DIR/fase4-stork/docker/"
    echo "    kea-stork:latest construïda correctament"
fi

# Construir imatge Stork Server (només si existeix el Dockerfile)
if [ -f "$BASE_DIR/fase4-stork/docker/Dockerfile.stork-server" ]; then
    echo ""
    echo ">>> Construint imatge stork-server..."
    docker build -t stork-server:latest -f "$BASE_DIR/fase4-stork/docker/Dockerfile.stork-server" "$BASE_DIR/fase4-stork/docker/"
    echo "    stork-server:latest construïda correctament"
fi

echo ""
echo "=== Imatges construïdes correctament ==="
echo ""
echo "Imatges disponibles:"
docker images | grep -E "^(kea-relay|kea-stork|stork-server)" || true
