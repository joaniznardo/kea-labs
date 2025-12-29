#!/bin/bash
# Script per desplegar una fase del laboratori Kea
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "Ús: $0 <fase>"
    echo ""
    echo "Fases disponibles:"
    echo "  1, basic      - Fase 1: Kea bàsic"
    echo "  2, vlans      - Fase 2: Múltiples VLANs amb relays"
    echo "  3, ha         - Fase 3: Alta disponibilitat (load-balancing)"
    echo "  4, stork      - Fase 4: Monitorització amb Stork"
    echo "  5, prometheus - Fase 5: Prometheus + Grafana"
    echo ""
    echo "Exemples:"
    echo "  $0 1"
    echo "  $0 vlans"
    echo "  $0 prometheus"
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

# Determinar la fase
case "$1" in
    1|basic)
        FASE="fase1-basic"
        ;;
    2|vlans)
        FASE="fase2-vlans"
        ;;
    3|ha)
        FASE="fase3-ha"
        ;;
    4|stork)
        FASE="fase4-stork"
        ;;
    5|prometheus)
        FASE="fase5-prometheus"
        ;;
    *)
        echo "Error: Fase desconeguda '$1'"
        usage
        ;;
esac

FASE_DIR="$BASE_DIR/$FASE"
TOPOLOGY_FILE="$FASE_DIR/topology.clab.yml"

if [ ! -f "$TOPOLOGY_FILE" ]; then
    echo "Error: No s'ha trobat el fitxer de topologia: $TOPOLOGY_FILE"
    exit 1
fi

echo "=== Desplegant $FASE ==="
echo ""

# Funció per crear bridges Linux
create_bridge() {
    local bridge=$1
    if ! ip link show "$bridge" &>/dev/null; then
        echo "    Creant bridge $bridge..."
        sudo ip link add name "$bridge" type bridge
        sudo ip link set "$bridge" up
    else
        echo "    Bridge $bridge ja existeix"
    fi
}

# Crear bridges Linux necessaris per a cada fase
echo ">>> Preparant bridges Linux..."
case "$FASE" in
    fase1-basic)
        create_bridge "br-dhcp"
        ;;
    fase2-vlans|fase3-ha|fase4-stork|fase5-prometheus)
        create_bridge "br-backend"
        create_bridge "br-vlan10"
        create_bridge "br-vlan20"
        create_bridge "br-vlan30"
        ;;
esac
echo ""

# Verificar que les imatges necessàries existeixen
echo ">>> Verificant imatges Docker..."
if [ "$FASE" = "fase2-vlans" ] || [ "$FASE" = "fase3-ha" ] || [ "$FASE" = "fase4-stork" ] || [ "$FASE" = "fase5-prometheus" ]; then
    if ! docker image inspect kea-relay:latest &>/dev/null; then
        echo "    Imatge kea-relay:latest no trobada. Construint..."
        "$SCRIPT_DIR/build-images.sh"
    else
        echo "    kea-relay:latest OK"
    fi
fi

if [ "$FASE" = "fase4-stork" ] || [ "$FASE" = "fase5-prometheus" ]; then
    if ! docker image inspect kea-stork:latest &>/dev/null; then
        echo "    Imatge kea-stork:latest no trobada. Construint..."
        "$SCRIPT_DIR/build-images.sh"
    else
        echo "    kea-stork:latest OK"
    fi
    if ! docker image inspect stork-server:latest &>/dev/null; then
        echo "    Imatge stork-server:latest no trobada. Construint..."
        "$SCRIPT_DIR/build-images.sh"
    else
        echo "    stork-server:latest OK"
    fi
fi

echo ""
echo ">>> Desplegant topologia amb containerlab..."
cd "$FASE_DIR"
sudo containerlab deploy --topo topology.clab.yml

echo ""
echo "=== Desplegament completat ==="
echo ""
echo "Comandes útils:"
echo "  - Veure contenidors: sudo containerlab inspect --topo $TOPOLOGY_FILE"
echo "  - Accedir a un node: docker exec -it clab-kea-lab-*-<node> sh"
echo "  - Destruir lab: $SCRIPT_DIR/destroy.sh $1"
