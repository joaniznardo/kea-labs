# Laboratori Kea DHCP4 amb Containerlab

Laboratori modular i progressiu per aprendre i practicar amb el servidor DHCP Kea d'ISC.

## Requisits

- Docker
- [Containerlab](https://containerlab.dev/)
- Accés a Internet (per descarregar imatges)

## Estructura del laboratori

```
kea-lab/
├── base/                    # Fitxers comuns
│   ├── docker/
│   │   ├── Dockerfile.relay
│   │   └── entrypoint-relay.sh
│   └── postgres/
│       └── init.sql
├── fase1-basic/             # Kea bàsic
├── fase2-vlans/             # Múltiples VLANs
├── fase3-ha/                # Alta disponibilitat
├── fase4-stork/             # Monitorització
├── scripts/                 # Scripts d'utilitat
└── README.md
```

## Fases del laboratori

### Fase 1: Kea Bàsic
- Servidor Kea DHCP4 amb PostgreSQL
- Un client netshoot
- Xarxa directa (sense relay)
- Proves amb perfdhcp

### Fase 2: Múltiples VLANs
- 3 VLANs: 10.50.10.0/24, 10.50.20.0/24, 10.50.30.0/24
- 1 relay DHCP per VLAN (dhcp-helper)
- 1 client netshoot per VLAN
- Proves amb perfdhcp

### Fase 3: Alta Disponibilitat
- 2 servidors Kea en mode load-balancing
- Xarxa heartbeat dedicada (10.50.99.0/24)
- Relays configurats per enviar a ambdós servidors

### Fase 4: Monitorització amb Stork
- Stork server per monitorització web
- kea-ctrl-agent + stork-agent integrats
- Visualització de leases i estadístiques

## Inici ràpid

### 1. Construir imatges

```bash
./scripts/build-images.sh
```

### 2. Desplegar una fase

```bash
# Fase 1 (bàsic)
./scripts/deploy.sh 1

# Fase 2 (VLANs)
./scripts/deploy.sh vlans

# Fase 3 (HA)
./scripts/deploy.sh ha

# Fase 4 (Stork)
./scripts/deploy.sh stork
```

### 3. Verificar desplegament

```bash
# Veure contenidors
docker ps

# Inspeccionar lab
sudo containerlab inspect --topo fase1-basic/topology.clab.yml
```

### 4. Destruir lab

```bash
./scripts/destroy.sh 1
# o
./scripts/destroy.sh all
```

## Proves

### Test DHCP des del client

```bash
# Sol·licitar IP a la VLAN 10
./scripts/test-dhcp-client.sh request 10

# Veure informació de xarxa
./scripts/test-dhcp-client.sh info 10

# Sol·licitar IP a totes les VLANs
./scripts/test-dhcp-client.sh all
```

### Test de rendiment amb perfdhcp

```bash
# Test bàsic DISCOVER
./scripts/test-perfdhcp.sh discover

# Test d'estrès amb 100 clients a 50 req/s
./scripts/test-perfdhcp.sh stress -n 100 -r 50

# Test de taxa a la VLAN 20
./scripts/test-perfdhcp.sh rate -r 100 -v 20
```

### Accés directe als contenidors

```bash
# Client
docker exec -it clab-kea-lab-basic-client1 bash

# Servidor Kea
docker exec -it clab-kea-lab-basic-kea bash

# Consultar leases a PostgreSQL
docker exec -it clab-kea-lab-basic-postgres psql -U kea -d kea -c "SELECT * FROM lease4;"
```

## Configuració

### Xarxes

| Xarxa | Rang | Ús |
|-------|------|-----|
| VLAN 10 | 10.50.10.0/24 | Primera VLAN de clients |
| VLAN 20 | 10.50.20.0/24 | Segona VLAN de clients |
| VLAN 30 | 10.50.30.0/24 | Tercera VLAN de clients |
| Backend | 10.50.1.0/24 | Comunicació Kea-Relays |
| Heartbeat | 10.50.99.0/24 | HA entre servidors Kea |

### Pools DHCP

| VLAN | Pool | Gateway |
|------|------|---------|
| 10 | 10.50.10.100-200 | 10.50.10.1 |
| 20 | 10.50.20.100-200 | 10.50.20.1 |
| 30 | 10.50.30.100-200 | 10.50.30.1 |

### Opcions DHCP

- **DNS**: 1.1.1.1, 1.0.0.1
- **Domini de cerca**: demokea.test

## Arquitectura

### Fase 1: Bàsic

```
┌─────────────┐     ┌─────────────┐
│  PostgreSQL │◄────│     Kea     │
└─────────────┘     └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │   client1   │
                    └─────────────┘
```

### Fase 2: VLANs

```
                    ┌─────────────┐
                    │  PostgreSQL │
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │     Kea     │
                    └──────┬──────┘
                           │ 10.50.1.0/24
          ┌────────────────┼────────────────┐
          │                │                │
    ┌─────┴─────┐    ┌─────┴─────┐    ┌─────┴─────┐
    │relay-vlan10│   │relay-vlan20│   │relay-vlan30│
    └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
          │                │                │
    10.50.10.0/24    10.50.20.0/24    10.50.30.0/24
          │                │                │
    ┌─────┴─────┐    ┌─────┴─────┐    ┌─────┴─────┐
    │client-vlan10│  │client-vlan20│  │client-vlan30│
    └───────────┘    └───────────┘    └───────────┘
```

### Fase 3: HA

```
                    ┌─────────────┐
                    │  PostgreSQL │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │                               │
    ┌──────┴──────┐                 ┌──────┴──────┐
    │ kea-primary │◄──────────────►│kea-secondary│
    └──────┬──────┘  10.50.99.0/24 └──────┬──────┘
           │                               │
           └───────────────┬───────────────┘
                           │ 10.50.1.0/24
                      [relays]
```

### Fase 4: Stork

```
    ┌─────────────┐
    │stork-server │◄─────────────────────────┐
    └──────┬──────┘                          │
           │                                 │
    ┌──────┴──────┐                          │
    │  PostgreSQL │                          │
    └──────┬──────┘                          │
           │                                 │
    ┌──────┴──────┐     HA      ┌────────────┴───┐
    │ kea-primary │◄───────────►│ kea-secondary  │
    │ +ctrl-agent │             │  +ctrl-agent   │
    │ +stork-agent│             │  +stork-agent  │
    └─────────────┘             └────────────────┘
```

## Accés a Stork (Fase 4)

Un cop desplegat el lab de la fase 4:

1. Accedir a http://localhost:8080
2. Credencials per defecte: admin/admin

## Resolució de problemes

### El relay no funciona

1. Verificar que el relay té IP a la xarxa backend:
   ```bash
   docker exec clab-kea-lab-vlans-relay-vlan10 ip addr show eth2
   ```

2. Verificar que dhcp-helper està executant-se:
   ```bash
   docker exec clab-kea-lab-vlans-relay-vlan10 ps aux | grep dhcp
   ```

### Kea no arrenca

1. Verificar logs:
   ```bash
   docker logs clab-kea-lab-basic-kea
   ```

2. Verificar connexió a PostgreSQL:
   ```bash
   docker exec clab-kea-lab-basic-kea ping -c 2 postgres
   ```

### Client no obté IP

1. Verificar que Kea està escoltant:
   ```bash
   docker exec clab-kea-lab-basic-kea ss -ulnp | grep 67
   ```

2. Provar manualment:
   ```bash
   docker exec clab-kea-lab-basic-client1 dhclient -v eth1
   ```

## Recursos

- [Documentació Kea](https://kea.readthedocs.io/)
- [Containerlab](https://containerlab.dev/)
- [perfdhcp](https://kea.readthedocs.io/en/latest/man/perfdhcp.8.html)
- [Stork](https://stork.readthedocs.io/)

## Llicència

Ús educatiu.
