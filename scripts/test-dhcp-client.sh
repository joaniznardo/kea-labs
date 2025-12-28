#!/bin/bash
# Script per fer proves DHCP des dels clients netshoot
set -e

usage() {
    echo "Ús: $0 <acció> [vlan]"
    echo ""
    echo "Accions disponibles:"
    echo "  request     - Sol·licitar IP via DHCP"
    echo "  release     - Alliberar IP actual"
    echo "  renew       - Renovar IP actual"
    echo "  info        - Mostrar informació de xarxa"
    echo "  all         - Sol·licitar IP a totes les VLANs"
    echo ""
    echo "VLANs disponibles: 10, 20, 30 (per defecte: 10)"
    echo ""
    echo "Exemples:"
    echo "  $0 request 10"
    echo "  $0 info 20"
    echo "  $0 all"
    echo ""
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

ACTION="$1"
VLAN="${2:-10}"

# Trobar el contenidor del client
get_client_container() {
    local vlan=$1
    docker ps --format '{{.Names}}' | grep -E "client-vlan${vlan}$" | head -1
}

do_request() {
    local vlan=$1
    local container=$(get_client_container "$vlan")

    if [ -z "$container" ]; then
        echo "Error: No s'ha trobat el contenidor client-vlan$vlan"
        return 1
    fi

    echo ">>> Sol·licitant IP per client-vlan$vlan..."
    docker exec -it "$container" dhclient -v eth1 2>&1 || docker exec -it "$container" udhcpc -i eth1 -v 2>&1 || true
    echo ""
    echo ">>> Configuració obtinguda:"
    docker exec "$container" ip addr show eth1
    docker exec "$container" cat /etc/resolv.conf 2>/dev/null || true
}

do_release() {
    local vlan=$1
    local container=$(get_client_container "$vlan")

    if [ -z "$container" ]; then
        echo "Error: No s'ha trobat el contenidor client-vlan$vlan"
        return 1
    fi

    echo ">>> Alliberant IP per client-vlan$vlan..."
    docker exec "$container" dhclient -r eth1 2>&1 || docker exec "$container" ip addr flush dev eth1 2>&1 || true
    docker exec "$container" ip addr show eth1
}

do_renew() {
    local vlan=$1
    local container=$(get_client_container "$vlan")

    if [ -z "$container" ]; then
        echo "Error: No s'ha trobat el contenidor client-vlan$vlan"
        return 1
    fi

    echo ">>> Renovant IP per client-vlan$vlan..."
    docker exec "$container" dhclient -v eth1 2>&1 || true
    docker exec "$container" ip addr show eth1
}

do_info() {
    local vlan=$1
    local container=$(get_client_container "$vlan")

    if [ -z "$container" ]; then
        echo "Error: No s'ha trobat el contenidor client-vlan$vlan"
        return 1
    fi

    echo "=== Informació de xarxa per client-vlan$vlan ==="
    echo ""
    echo ">>> Interfícies:"
    docker exec "$container" ip addr show eth1
    echo ""
    echo ">>> Rutes:"
    docker exec "$container" ip route
    echo ""
    echo ">>> DNS:"
    docker exec "$container" cat /etc/resolv.conf 2>/dev/null || echo "No configurat"
}

case "$ACTION" in
    request)
        do_request "$VLAN"
        ;;
    release)
        do_release "$VLAN"
        ;;
    renew)
        do_renew "$VLAN"
        ;;
    info)
        do_info "$VLAN"
        ;;
    all)
        for v in 10 20 30; do
            echo "========================================"
            do_request "$v"
            echo ""
        done
        ;;
    *)
        echo "Error: Acció desconeguda '$ACTION'"
        usage
        ;;
esac
