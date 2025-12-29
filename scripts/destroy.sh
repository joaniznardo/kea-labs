#!/bin/bash
# Script per destruir una fase del laboratori Kea
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "Ús: $0 <fase> [--cleanup]"
    echo ""
    echo "Fases disponibles:"
    echo "  1, basic      - Fase 1: Kea bàsic"
    echo "  2, vlans      - Fase 2: VLANs"
    echo "  3, ha         - Fase 3: Alta disponibilitat"
    echo "  4, stork      - Fase 4: Stork"
    echo "  5, prometheus - Fase 5: Prometheus + Grafana"
    echo "  all           - Totes les fases"
    echo ""
    echo "Opcions:"
    echo "  --cleanup   - Eliminar també els volums i dades persistents"
    echo ""
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

CLEANUP=false
if [ "$2" = "--cleanup" ]; then
    CLEANUP=true
fi

destroy_fase() {
    local fase=$1
    local fase_dir="$BASE_DIR/$fase"
    local topology_file="$fase_dir/topology.clab.yml"

    if [ -f "$topology_file" ]; then
        echo ">>> Destruint $fase..."
        cd "$fase_dir"
        sudo containerlab destroy --topo topology.clab.yml --cleanup 2>/dev/null || true
        echo "    $fase destruït"
    fi
}

case "$1" in
    1|basic)
        destroy_fase "fase1-basic"
        ;;
    2|vlans)
        destroy_fase "fase2-vlans"
        ;;
    3|ha)
        destroy_fase "fase3-ha"
        ;;
    4|stork)
        destroy_fase "fase4-stork"
        ;;
    5|prometheus)
        destroy_fase "fase5-prometheus"
        ;;
    all)
        echo "=== Destruint totes les fases ==="
        destroy_fase "fase1-basic"
        destroy_fase "fase2-vlans"
        destroy_fase "fase3-ha"
        destroy_fase "fase4-stork"
        destroy_fase "fase5-prometheus"
        ;;
    *)
        echo "Error: Fase desconeguda '$1'"
        usage
        ;;
esac

if [ "$CLEANUP" = true ]; then
    echo ""
    echo ">>> Netejant volums Docker..."
    docker volume prune -f 2>/dev/null || true
fi

echo ""
echo "=== Destrucció completada ==="
