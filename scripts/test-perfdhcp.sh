#!/bin/bash
# Script per fer proves de rendiment amb perfdhcp
set -e

usage() {
    echo "Ús: $0 <test> [opcions]"
    echo ""
    echo "Tests disponibles:"
    echo "  discover     - Test bàsic de DHCPDISCOVER (4-way handshake)"
    echo "  renew        - Test de renovació de leases"
    echo "  release      - Test d'alliberament de leases"
    echo "  stress       - Test d'estrès amb múltiples clients"
    echo "  rate         - Test de taxa de peticions (discovers/segon)"
    echo ""
    echo "Opcions:"
    echo "  -i <iface>   - Interfície a utilitzar (per defecte: eth1)"
    echo "  -n <num>     - Nombre de clients a simular (per defecte: 10)"
    echo "  -r <rate>    - Taxa de peticions per segon (per defecte: 10)"
    echo "  -s <server>  - IP del servidor DHCP (per defecte: broadcast)"
    echo "  -v <vlan>    - VLAN a provar: 10, 20, 30 (per defecte: 10)"
    echo ""
    echo "Exemples:"
    echo "  $0 discover"
    echo "  $0 stress -n 100 -r 50"
    echo "  $0 rate -r 100 -v 20"
    echo ""
    exit 1
}

# Valors per defecte
IFACE="eth1"
NUM_CLIENTS=10
RATE=10
SERVER=""
VLAN=10

# Parsejar opcions
TEST=""
while [ $# -gt 0 ]; do
    case "$1" in
        discover|renew|release|stress|rate)
            TEST="$1"
            ;;
        -i)
            IFACE="$2"
            shift
            ;;
        -n)
            NUM_CLIENTS="$2"
            shift
            ;;
        -r)
            RATE="$2"
            shift
            ;;
        -s)
            SERVER="$2"
            shift
            ;;
        -v)
            VLAN="$2"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Opció desconeguda: $1"
            usage
            ;;
    esac
    shift
done

if [ -z "$TEST" ]; then
    usage
fi

# Determinar la interfície segons la VLAN
case "$VLAN" in
    10) IFACE="eth1" ;;
    20) IFACE="eth2" ;;
    30) IFACE="eth3" ;;
esac

# Determinar el contenidor perfdhcp (depèn del lab desplegat)
CONTAINER=$(docker ps --format '{{.Names}}' | grep -E "perfdhcp$" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "Error: No s'ha trobat el contenidor perfdhcp. Assegura't que el lab està desplegat."
    exit 1
fi

echo "=== Test perfdhcp: $TEST ==="
echo "  Contenidor: $CONTAINER"
echo "  Interfície: $IFACE (VLAN $VLAN)"
echo "  Clients: $NUM_CLIENTS"
echo "  Taxa: $RATE req/s"
echo ""

case "$TEST" in
    discover)
        # Test bàsic: DORA complet
        echo ">>> Executant test DISCOVER (4-way handshake)..."
        docker exec -it "$CONTAINER" perfdhcp -4 -r "$RATE" -n "$NUM_CLIENTS" -l "$IFACE"
        ;;
    renew)
        # Test de renovació
        echo ">>> Executant test de RENEW..."
        docker exec -it "$CONTAINER" perfdhcp -4 -r "$RATE" -n "$NUM_CLIENTS" -l "$IFACE" -f 1 -F
        ;;
    release)
        # Test d'alliberament
        echo ">>> Executant test de RELEASE..."
        docker exec -it "$CONTAINER" perfdhcp -4 -r "$RATE" -n "$NUM_CLIENTS" -l "$IFACE" -R "$NUM_CLIENTS"
        ;;
    stress)
        # Test d'estrès
        echo ">>> Executant test d'ESTRÈS..."
        docker exec -it "$CONTAINER" perfdhcp -4 -r "$RATE" -n "$NUM_CLIENTS" -l "$IFACE" -D 50% -O 30 -a 5
        ;;
    rate)
        # Test de taxa màxima
        echo ">>> Executant test de TAXA..."
        docker exec -it "$CONTAINER" perfdhcp -4 -r "$RATE" -n "$NUM_CLIENTS" -l "$IFACE" -p 60
        ;;
esac

echo ""
echo "=== Test completat ==="
