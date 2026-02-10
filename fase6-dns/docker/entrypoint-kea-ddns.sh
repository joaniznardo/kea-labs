#!/bin/bash
set -e

echo "Iniciant kea-dhcp-ddns (D2)..."
kea-dhcp-ddns -c /etc/kea/kea-dhcp-ddns.conf &
D2_PID=$!

# Esperar que D2 estigui llest
sleep 2

echo "Iniciant kea-dhcp4..."
exec kea-dhcp4 -c /etc/kea/kea-dhcp4.conf
