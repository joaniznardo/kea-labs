# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Laboratori modular de Kea DHCP4 amb Containerlab. Cinc fases progressives: bàsic → VLANs → HA → Stork → Prometheus/Grafana.

## Common Commands

```bash
# Construir imatges Docker (relay i kea-stork)
./scripts/build-images.sh

# Desplegar una fase (crea bridges automàticament)
./scripts/deploy.sh 1|vlans|ha|stork|prometheus

# Destruir lab (--cleanup per eliminar bridges i volums)
./scripts/destroy.sh 1|vlans|ha|stork|prometheus|all [--cleanup]

# Test DHCP des del client (nicolaka/netshoot)
docker exec clab-kea-lab-basic-client1 udhcpc -i eth1 -n

# Veure leases (memfile)
docker exec clab-kea-lab-<fase>-kea cat /var/lib/kea/kea-leases4.csv

# Test rendiment amb perfdhcp
docker exec clab-kea-lab-<fase>-perfdhcp perfdhcp -4 -r 10 -n 100 10.50.10.1
```

## Architecture

- **base/**: Dockerfile.relay (Alpine + dhcp-helper)
- **fase1-basic/**: Kea + 1 client directe (sense VLANs)
- **fase2-vlans/**: + 3 VLANs amb relays (dhcp-helper), shared-networks a kea config
- **fase3-ha/**: + 2 servidors Kea load-balancing, hooks libdhcp_ha.so, xarxa heartbeat 10.50.99.0/24
- **fase4-stork/**: + Stork server, kea-ctrl-agent, stork-agent (supervisord per múltiples processos)
- **fase5-prometheus/**: + Prometheus + Grafana per mètriques i alertes (pool >80%, HA down)

## Network Configuration

| Xarxa | Rang | Funció |
|-------|------|--------|
| VLAN 10/20/30 | 10.50.{10,20,30}.0/24 | Clients (pool .100-.200, gw .1) |
| Backend | 10.50.1.0/24 | Kea ↔ Relays |
| Heartbeat | 10.50.99.0/24 | HA entre servidors |

## Key Files

- `*/topology.clab.yml`: Definició containerlab de cada fase
- `*/configs/kea/kea-dhcp4.conf`: Configuració Kea (JSON)
- `fase3-ha/`, `fase4-stork/`, `fase5-prometheus/`: Configs separades per kea-primary i kea-secondary
- `fase5-prometheus/configs/prometheus/`: prometheus.yml i alerts.yml
- `fase5-prometheus/configs/grafana/`: Dashboard i provisioning

## Monitoring URLs (fase5)

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9091
- **Stork**: http://localhost:8080 (admin/admin)

## Important Notes

- Kea utilitza **memfile** per leases (`/var/lib/kea/kea-leases4.csv`)
- Imatge oficial Kea: `docker.cloudsmith.io/isc/docker/kea-dhcp4:2.6.1`
- El script deploy.sh crea els bridges Linux automàticament (br-backend, br-vlan10/20/30)
- Relays envien a múltiples servidors en HA: `DHCP_SERVER: "10.50.1.10 10.50.1.11"`
- Fase 4 requereix imatge Stork: `docker.cloudsmith.io/isc/docker/stork:latest`
- DNS: 1.1.1.1, 1.0.0.1 | Domini: demokea.test
- Els fitxers de config han de tenir permisos 644

## Troubleshooting

- Si containerlab falla amb "interface not found", verificar que els bridges existeixen: `ip link show br-backend`
- Si Kea no arrenca, verificar logs: `docker logs clab-kea-lab-<fase>-kea`
- No usar `docker restart` - redesplegar amb containerlab
- La imatge oficial Kea és Alpine, usar `sh` en comptes de `bash`
