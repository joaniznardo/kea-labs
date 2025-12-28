#!/bin/sh
set -e

# Variables d'entorn esperades:
# - DHCP_SERVER: IP del servidor DHCP (o servidors separats per espai)
# - LISTEN_INTERFACE: Interfície client on escoltar (per defecte eth2)
# - UPSTREAM_INTERFACE: Interfície cap al servidor DHCP (per defecte eth1)

LISTEN_INTERFACE="${LISTEN_INTERFACE:-eth2}"
UPSTREAM_INTERFACE="${UPSTREAM_INTERFACE:-eth1}"

if [ -z "$DHCP_SERVER" ]; then
    echo "ERROR: Cal definir DHCP_SERVER"
    exit 1
fi

# Esperar que les interfícies estiguin disponibles i tinguin IP
# (containerlab assigna les IPs via exec després d'iniciar el contenidor)
echo "Esperant que $LISTEN_INTERFACE tingui una IP assignada..."
MAX_WAIT=60
WAITED=0
RELAY_IP=""

while [ -z "$RELAY_IP" ] && [ $WAITED -lt $MAX_WAIT ]; do
    RELAY_IP=$(ip -4 addr show "$LISTEN_INTERFACE" 2>/dev/null | awk '/inet / {split($2,a,"/"); print a[1]}' | head -1)
    if [ -z "$RELAY_IP" ]; then
        sleep 1
        WAITED=$((WAITED + 1))
    fi
done

if [ -z "$RELAY_IP" ]; then
    echo "ERROR: No s'ha trobat IP a $LISTEN_INTERFACE després de ${MAX_WAIT}s"
    ip addr show
    exit 1
fi

echo "Iniciant DHCP relay (dnsmasq)..."
echo "  Interfície client: $LISTEN_INTERFACE ($RELAY_IP)"
echo "  Interfície servidor: $UPSTREAM_INTERFACE"
echo "  Servidor(s) DHCP: $DHCP_SERVER"

# Construir opcions dhcp-relay per a cada servidor
RELAY_OPTS=""
for server in $DHCP_SERVER; do
    RELAY_OPTS="$RELAY_OPTS --dhcp-relay=${RELAY_IP},${server}"
done

# Executar dnsmasq en mode relay
# --no-daemon: primer pla
# --port=0: deshabilitar DNS
# --dhcp-relay: configurar relay (un per servidor)
# --log-dhcp: logging detallat
exec dnsmasq \
    --no-daemon \
    --port=0 \
    $RELAY_OPTS \
    --log-dhcp \
    --log-facility=-
