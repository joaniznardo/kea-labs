# Activitats Pràctiques: Kea DHCP4 amb Containerlab

**Mòdul**: Serveis de Xarxa i Internet
**Cicle**: ASIX (2n curs)
**Durada**: 4 sessions de 2 hores (8 hores totals)

---

## Índex

1. [Sessió 1: Kea DHCP4 Bàsic](#sessió-1-kea-dhcp4-bàsic)
2. [Sessió 2: VLANs i DHCP Relay](#sessió-2-vlans-i-dhcp-relay)
3. [Sessió 3: Alta Disponibilitat](#sessió-3-alta-disponibilitat)
4. [Sessió 4: Monitorització i Repte Final](#sessió-4-monitorització-i-repte-final)
5. [Rúbriques d'Avaluació](#rúbriques-davaluació)
6. [Solucions](#solucions)

---

## Preparació Inicial

Abans de començar, clona el repositori i construeix les imatges:

```bash
cd ~/kea-lab
./scripts/build-images.sh
```

**Verificació**:
```bash
docker images | grep -E "kea-relay|kea-stork|stork-server"
```

Hauries de veure 3 imatges.

---

# Sessió 1: Kea DHCP4 Bàsic

**Objectius**:
- Comprendre l'estructura JSON de configuració de Kea
- Identificar els components essencials d'una configuració DHCP
- Resoldre errors comuns de configuració

## 1.1 Activitat de Reflexió (Autoavaluació)

### Preguntes de comprensió

Respon les següents preguntes abans de tocar el lab:

**P1.1**: En el protocol DHCP, quin és l'ordre correcte dels missatges en una assignació inicial d'IP?

**P1.2**: Quina diferència hi ha entre `renew-timer` i `rebind-timer`? Per què el rebind és més gran?

**P1.3**: Per què Kea recomana usar `dhcp-socket-type: raw` en lloc de `udp`?

**P1.4**: Quin avantatge té usar `memfile` com a backend de leases en un entorn de proves?

---

## 1.2 Activitat d'Identificació (Per entregar)

### Analitza la configuració

Desplega la fase 1 i analitza la configuració:

```bash
./scripts/deploy.sh 1
```

Examina la configuració:

```bash
docker exec clab-kea-lab-basic-kea cat /etc/kea/kea-dhcp4.conf
```

**Tasca**: Completa la següent taula identificant els valors configurats:

| Paràmetre | Valor | Funció |
|-----------|-------|--------|
| valid-lifetime | | |
| Interfície d'escolta | | |
| Fitxer de leases | | |
| Rang del pool | | |
| Gateway dels clients | | |
| Servidors DNS | | |

### Autocorrecció

Executa aquest script per verificar les teves respostes:

```bash
docker exec clab-kea-lab-basic-kea sh -c '
echo "=== AUTOCORRECCIÓ ==="
echo ""
echo "valid-lifetime: $(grep -o "valid-lifetime.*[0-9]*" /etc/kea/kea-dhcp4.conf | head -1)"
echo "Interfície: $(grep -o "interfaces.*\[.*\]" /etc/kea/kea-dhcp4.conf | head -1)"
echo "Fitxer leases: $(grep -o "name.*kea-leases.*csv" /etc/kea/kea-dhcp4.conf)"
echo "Pool: $(grep -o "pool.*10\.50\.[0-9.]*" /etc/kea/kea-dhcp4.conf)"
echo "Router: $(grep -A1 "routers" /etc/kea/kea-dhcp4.conf | grep data)"
echo "DNS: $(grep -A1 "domain-name-servers" /etc/kea/kea-dhcp4.conf | grep data)"
'
```

---

## 1.3 Repte: Troubleshooting de Configuració

### Escenari

El teu company ha modificat la configuració de Kea i ara el servei no arrenca. Has d'identificar i corregir els errors.

### Preparació

Crea una configuració amb errors:

```bash
cat > /tmp/kea-dhcp4-errors.conf << 'EOF'
{
    "Dhcp4": {
        "valid-lifetime": "quatre mil",
        "renew-timer": 1000,
        "rebind-timer": 500,

        "interfaces-config": {
            "interfaces": ["eth99"],
            "dhcp-socket-type": "raw"
        },

        "lease-database": {
            "type": "memfile",
            "persist": true,
            "name": "/var/lib/kea/kea-leases4.csv"
        },

        "subnet4": [
            {
                "id": 1,
                "subnet": "10.50.10.0/24",
                "pools": [
                    {
                        "pool": "10.50.10.250 - 10.50.10.300"
                    }
                ],
                "option-data": [
                    {
                        "name": "routers",
                        "data": "10.50.20.1"
                    }
                ]
            }
        ]
    }
}
EOF
```

Copia la configuració errònia al contenidor:

```bash
docker cp /tmp/kea-dhcp4-errors.conf clab-kea-lab-basic-kea:/tmp/
```

Intenta validar-la:

```bash
docker exec clab-kea-lab-basic-kea kea-dhcp4 -t /tmp/kea-dhcp4-errors.conf
```

### Tasques

**T1.3.1**: Identifica **tots els errors** de la configuració (n'hi ha 5).

**T1.3.2**: Per cada error, explica:
- Quin és el problema
- Per què és un error
- Com es corregeix

**T1.3.3**: Crea una configuració corregida i verifica que passa la validació.

### Verificació

Un cop corregida, la validació hauria de mostrar:

```bash
docker exec clab-kea-lab-basic-kea kea-dhcp4 -t /tmp/kea-dhcp4-corregit.conf
# Hauria de dir: "Configuration check successful"
```

---

## 1.4 Repte Obert: Configuració Personalitzada

### Requisits

Modifica la configuració de Kea per complir:

1. Lease time de 2 hores (en segons)
2. Pool d'adreces: 10.50.10.50 - 10.50.10.99
3. DNS: 8.8.8.8 i 8.8.4.4
4. Domini de cerca: empresa.local
5. Reserva estàtica: MAC `00:11:22:33:44:55` → IP `10.50.10.10`

### Lliurament

1. Fitxer de configuració modificat
2. Captura de la validació exitosa
3. Captura d'un client obtenint IP del nou pool

### Comandes de verificació

```bash
# Validar configuració
docker exec clab-kea-lab-basic-kea kea-dhcp4 -t /etc/kea/kea-dhcp4.conf

# Provar DHCP
docker exec clab-kea-lab-basic-client1 udhcpc -i eth1 -n -q

# Veure IP assignada
docker exec clab-kea-lab-basic-client1 ip addr show eth1

# Veure leases
docker exec clab-kea-lab-basic-kea cat /var/lib/kea/kea-leases4.csv
```

### Finalització Sessió 1

```bash
./scripts/destroy.sh 1
```

---

# Sessió 2: VLANs i DHCP Relay

**Objectius**:
- Comprendre el funcionament del DHCP relay
- Entendre el paper del camp giaddr
- Diagnosticar problemes de relay

## 2.1 Activitat de Reflexió (Autoavaluació)

### Preguntes de comprensió

**P2.1**: Per què el missatge DHCP Discover no pot arribar directament al servidor DHCP quan client i servidor estan en xarxes diferents?

**P2.2**: Què és el camp `giaddr` i qui l'omple? Quin valor té?

**P2.3**: En la nostra topologia, el relay té dues interfícies (eth1 i eth2). Quina IP s'usa com a giaddr? Per què?

**P2.4**: Si tenim 3 VLANs però només 1 servidor DHCP, com sap el servidor quina subnet usar per cada petició?

---

## 2.2 Activitat d'Identificació (Per entregar)

### Anàlisi de topologia

Desplega la fase 2:

```bash
./scripts/deploy.sh vlans
```

### Tasca 1: Mapa de xarxa

Completa la taula amb les IPs de cada component:

```bash
# Executa per obtenir la informació
echo "=== KEA ===" && docker exec clab-kea-lab-vlans-kea ip -4 addr show eth1 | grep inet
echo "=== RELAY VLAN10 ===" && docker exec clab-kea-lab-vlans-relay-vlan10 ip -4 addr | grep inet
echo "=== RELAY VLAN20 ===" && docker exec clab-kea-lab-vlans-relay-vlan20 ip -4 addr | grep inet
echo "=== RELAY VLAN30 ===" && docker exec clab-kea-lab-vlans-relay-vlan30 ip -4 addr | grep inet
```

| Component | IP Backend (eth1) | IP VLAN (eth2) | Funció |
|-----------|-------------------|----------------|--------|
| kea | | - | |
| relay-vlan10 | | | |
| relay-vlan20 | | | |
| relay-vlan30 | | | |

### Tasca 2: Flux de paquets

Captura el tràfic DHCP mentre un client obté IP:

**Terminal 1** (captura):
```bash
docker exec clab-kea-lab-vlans-relay-vlan10 sh -c "apk add tcpdump >/dev/null 2>&1; tcpdump -i any -n port 67 or port 68" &
```

**Terminal 2** (client):
```bash
docker exec clab-kea-lab-vlans-client-vlan10 dhclient -v eth1
```

Identifica en la captura:
- L'adreça origen i destí del DISCOVER original
- L'adreça origen i destí del DISCOVER reenviat
- El valor de giaddr

### Autocorrecció

```bash
echo "=== AUTOCORRECCIÓ ==="
echo ""
echo "Comprova que el client ha obtingut una IP de la VLAN10:"
docker exec clab-kea-lab-vlans-client-vlan10 ip -4 addr show eth1 | grep "10.50.10"
echo ""
echo "La IP hauria d'estar en el rang 10.50.10.100-200"
echo ""
echo "Comprova el lease al servidor:"
docker exec clab-kea-lab-vlans-kea cat /var/lib/kea/kea-leases4.csv | grep "10.50.10"
```

---

## 2.3 Repte: Troubleshooting de Relay

### Escenari

El relay de la VLAN20 no funciona correctament. Els clients no obtenen IP.

### Preparació (simular l'error)

```bash
# Atura el relay actual
docker exec clab-kea-lab-vlans-relay-vlan20 pkill dnsmasq

# Inicia'l amb configuració errònia (servidor incorrecte)
docker exec clab-kea-lab-vlans-relay-vlan20 sh -c '
dnsmasq --no-daemon --port=0 --dhcp-relay=10.50.20.1,10.50.1.99 --log-dhcp &
'
```

### Diagnòstic

**T2.3.1**: Intenta obtenir IP des del client VLAN20:

```bash
docker exec clab-kea-lab-vlans-client-vlan20 timeout 10 dhclient -v eth1
```

**T2.3.2**: Analitza els logs del relay:

```bash
docker logs clab-kea-lab-vlans-relay-vlan20 2>&1 | tail -20
```

**T2.3.3**: Verifica la connectivitat del relay:

```bash
docker exec clab-kea-lab-vlans-relay-vlan20 ping -c 2 10.50.1.10
docker exec clab-kea-lab-vlans-relay-vlan20 ping -c 2 10.50.1.99
```

### Tasques

1. Identifica quin és el problema
2. Explica per què els clients no obtenen IP
3. Proposa la solució

### Verificació de la solució

```bash
# Restaurar configuració correcta
docker restart clab-kea-lab-vlans-relay-vlan20
sleep 5

# Provar de nou
docker exec clab-kea-lab-vlans-client-vlan20 dhclient -v eth1

# Verificar
docker exec clab-kea-lab-vlans-client-vlan20 ip -4 addr show eth1 | grep "10.50.20"
```

---

## 2.4 Repte Obert: Afegir una Nova VLAN

### Requisits

Afegeix una VLAN 40 al sistema amb:
- Xarxa: 10.50.40.0/24
- Pool: 10.50.40.100 - 10.50.40.200
- Gateway: 10.50.40.1
- IP del relay al backend: 10.50.1.23

### Passos suggerits

1. Modifica `fase2-vlans/configs/kea/kea-dhcp4.conf` per afegir la subnet
2. Modifica `fase2-vlans/topology.clab.yml` per afegir:
   - Un nou bridge `br-vlan40`
   - Un nou relay `relay-vlan40`
   - Un nou client `client-vlan40`
   - Els links corresponents
3. Afegeix la ruta al servidor Kea

### Comandes de verificació

```bash
# Redesplegar
./scripts/destroy.sh vlans
./scripts/deploy.sh vlans

# Verificar que el client obté IP
docker exec clab-kea-lab-vlans-client-vlan40 dhclient -v eth1
docker exec clab-kea-lab-vlans-client-vlan40 ip addr show eth1

# Hauria de tenir una IP 10.50.40.x
```

### Finalització Sessió 2

```bash
./scripts/destroy.sh vlans
```

---

# Sessió 3: Alta Disponibilitat

**Objectius**:
- Comprendre els modes HA de Kea
- Configurar i verificar el failover
- Diagnosticar problemes de sincronització

## 3.1 Activitat de Reflexió (Autoavaluació)

### Preguntes de comprensió

**P3.1**: Quina diferència hi ha entre els modes `load-balancing` i `hot-standby`?

**P3.2**: Per què és necessària una xarxa separada (heartbeat) per la comunicació HA?

**P3.3**: Què passa si el `max-response-delay` expira sense rebre heartbeat del peer?

**P3.4**: En mode `load-balancing`, com decideixen els dos servidors qui respon a cada client?

**P3.5**: Per què cal desactivar `multi-threading` quan s'usa HA?

---

## 3.2 Activitat d'Identificació (Per entregar)

### Anàlisi de configuració HA

Desplega la fase 3:

```bash
./scripts/deploy.sh ha
```

### Tasca 1: Comparació de configuracions

```bash
# Veure diferències entre primary i secondary
diff <(docker exec clab-kea-lab-ha-kea-primary cat /etc/kea/kea-dhcp4.conf) \
     <(docker exec clab-kea-lab-ha-kea-secondary cat /etc/kea/kea-dhcp4.conf)
```

Documenta:
- Quines línies són diferents?
- Per què són diferents?

### Tasca 2: Estat HA

Verifica l'estat de l'HA:

```bash
# Estat del primary
docker exec clab-kea-lab-ha-kea-primary sh -c '
echo "{\"command\": \"ha-heartbeat\"}" | socat - UNIX:/run/kea/control_socket_4
'

# Estat del secondary
docker exec clab-kea-lab-ha-kea-secondary sh -c '
echo "{\"command\": \"ha-heartbeat\"}" | socat - UNIX:/run/kea/control_socket_4
'
```

### Tasca 3: Verificar sincronització

Obté una IP des d'un client:

```bash
docker exec clab-kea-lab-ha-client-vlan10 dhclient -v eth1
```

Verifica que el lease existeix als dos servidors:

```bash
echo "=== PRIMARY ==="
docker exec clab-kea-lab-ha-kea-primary cat /var/lib/kea/kea-leases4.csv
echo ""
echo "=== SECONDARY ==="
docker exec clab-kea-lab-ha-kea-secondary cat /var/lib/kea/kea-leases4.csv
```

### Autocorrecció

```bash
echo "=== AUTOCORRECCIÓ ==="
echo ""
PRIMARY_LEASES=$(docker exec clab-kea-lab-ha-kea-primary cat /var/lib/kea/kea-leases4.csv | grep -c "10.50")
SECONDARY_LEASES=$(docker exec clab-kea-lab-ha-kea-secondary cat /var/lib/kea/kea-leases4.csv | grep -c "10.50")
echo "Leases al primary: $PRIMARY_LEASES"
echo "Leases al secondary: $SECONDARY_LEASES"
if [ "$PRIMARY_LEASES" -eq "$SECONDARY_LEASES" ]; then
    echo "CORRECTE: Els leases estan sincronitzats"
else
    echo "ERROR: Els leases NO estan sincronitzats"
fi
```

---

## 3.3 Repte: Simulació de Failover

### Escenari

Simularem la caiguda del servidor primary i verificarem que el secondary assumeix el servei.

### Procediment

**Pas 1**: Obté IPs inicials des dels 3 clients:

```bash
for vlan in 10 20 30; do
    echo "=== VLAN $vlan ==="
    docker exec clab-kea-lab-ha-client-vlan$vlan dhclient -v eth1 2>&1 | grep "bound to"
done
```

**Pas 2**: Anota les IPs assignades:

```bash
for vlan in 10 20 30; do
    echo "Client VLAN$vlan: $(docker exec clab-kea-lab-ha-client-vlan$vlan ip -4 addr show eth1 | grep inet | awk '{print $2}')"
done
```

**Pas 3**: Simula la caiguda del primary:

```bash
docker stop clab-kea-lab-ha-kea-primary
```

**Pas 4**: Espera 60-90 segons perquè el secondary detecti la caiguda:

```bash
echo "Esperant failover..."
sleep 70
```

**Pas 5**: Verifica que els clients poden renovar:

```bash
for vlan in 10 20 30; do
    echo "=== Renovant VLAN $vlan ==="
    docker exec clab-kea-lab-ha-client-vlan$vlan dhclient -v eth1 2>&1 | grep -E "bound|DHCPACK"
done
```

### Tasques

**T3.3.1**: Els clients han pogut renovar? Quina IP tenen ara?

**T3.3.2**: Consulta els logs del secondary durant el failover:

```bash
docker logs clab-kea-lab-ha-kea-secondary 2>&1 | grep -i "partner\|state\|failover" | tail -20
```

**T3.3.3**: Restaura el primary i observa la sincronització:

```bash
docker start clab-kea-lab-ha-kea-primary
sleep 30
docker logs clab-kea-lab-ha-kea-primary 2>&1 | tail -20
```

---

## 3.4 Repte: Troubleshooting HA

### Escenari

Després d'un reinici, els dos servidors no sincronitzen correctament.

### Preparació (simular l'error)

```bash
# Atura els dos servidors
docker exec clab-kea-lab-ha-kea-primary pkill kea-dhcp4
docker exec clab-kea-lab-ha-kea-secondary pkill kea-dhcp4

# Modifica la IP del heartbeat del secondary (error!)
docker exec clab-kea-lab-ha-kea-secondary ip addr del 10.50.99.11/24 dev eth2
docker exec clab-kea-lab-ha-kea-secondary ip addr add 10.50.99.99/24 dev eth2

# Reinicia els serveis
docker exec clab-kea-lab-ha-kea-primary kea-dhcp4 -c /etc/kea/kea-dhcp4.conf &
docker exec clab-kea-lab-ha-kea-secondary kea-dhcp4 -c /etc/kea/kea-dhcp4.conf &
```

### Diagnòstic

**T3.4.1**: Comprova l'estat HA:

```bash
docker logs clab-kea-lab-ha-kea-primary 2>&1 | tail -10
docker logs clab-kea-lab-ha-kea-secondary 2>&1 | tail -10
```

**T3.4.2**: Verifica la connectivitat heartbeat:

```bash
docker exec clab-kea-lab-ha-kea-primary ping -c 2 10.50.99.11
docker exec clab-kea-lab-ha-kea-secondary ping -c 2 10.50.99.10
```

**T3.4.3**: Comprova les IPs configurades:

```bash
docker exec clab-kea-lab-ha-kea-primary ip addr show eth2
docker exec clab-kea-lab-ha-kea-secondary ip addr show eth2
```

### Tasques

1. Identifica el problema
2. Explica per què l'HA no funciona
3. Corregeix l'error i verifica que es sincronitzen

### Verificació

```bash
# Corregir IP
docker exec clab-kea-lab-ha-kea-secondary ip addr del 10.50.99.99/24 dev eth2
docker exec clab-kea-lab-ha-kea-secondary ip addr add 10.50.99.11/24 dev eth2

# Reiniciar per forçar sincronització
docker restart clab-kea-lab-ha-kea-secondary
sleep 30

# Verificar
docker logs clab-kea-lab-ha-kea-secondary 2>&1 | grep -i "state" | tail -5
```

### Finalització Sessió 3

```bash
./scripts/destroy.sh ha
```

---

# Sessió 4: Monitorització i Repte Final

**Objectius**:
- Comprendre l'arquitectura de Stork
- Configurar i diagnosticar agents
- Integrar tots els coneixements en un repte final

## 4.1 Activitat de Reflexió (Autoavaluació)

### Preguntes de comprensió

**P4.1**: Quina és la diferència entre `stork-agent` i `kea-ctrl-agent`? Quin comunica amb quin?

**P4.2**: Per què necessitem `supervisord` als contenidors amb Stork?

**P4.3**: Quin és el flux de comunicació quan Stork vol obtenir les estadístiques de leases de Kea?

**P4.4**: Per què les màquines s'han d'autoritzar manualment a Stork?

---

## 4.2 Activitat d'Identificació (Per entregar)

### Desplegar i analitzar

```bash
./scripts/deploy.sh stork
```

Espera 60 segons perquè tots els serveis arranquin:

```bash
echo "Esperant que els serveis arranquin..."
sleep 60
```

### Tasca 1: Verificar serveis

Comprova que tots els processos corren als servidors Kea:

```bash
for server in kea-primary kea-secondary; do
    echo "=== $server ==="
    docker exec clab-kea-lab-stork-$server supervisorctl status
done
```

### Tasca 2: Registre d'agents

Consulta les màquines registrades a Stork:

```bash
docker exec clab-kea-lab-stork-postgres psql -U postgres -d stork -c \
    "SELECT id, address, agent_port, authorized, last_visited_at FROM machine;"
```

Autoritza les màquines:

```bash
docker exec clab-kea-lab-stork-postgres psql -U postgres -d stork -c \
    "UPDATE machine SET authorized = true;"
```

### Tasca 3: Verificar daemons detectats

```bash
docker exec clab-kea-lab-stork-postgres psql -U postgres -d stork -c \
    "SELECT d.id, d.name, d.version, a.name as app
     FROM daemon d
     JOIN app a ON d.app_id = a.id;"
```

### Autocorrecció

```bash
echo "=== AUTOCORRECCIÓ ==="
MACHINES=$(docker exec clab-kea-lab-stork-postgres psql -U postgres -d stork -tAc "SELECT COUNT(*) FROM machine WHERE authorized = true;")
DAEMONS=$(docker exec clab-kea-lab-stork-postgres psql -U postgres -d stork -tAc "SELECT COUNT(*) FROM daemon;")

echo "Màquines autoritzades: $MACHINES (esperat: 2)"
echo "Daemons detectats: $DAEMONS (esperat: 4 - 2x dhcp4 + 2x ca)"

if [ "$MACHINES" -eq 2 ] && [ "$DAEMONS" -ge 4 ]; then
    echo "CORRECTE: Stork configurat correctament"
else
    echo "ERROR: Revisa la configuració"
fi
```

---

## 4.3 Repte: Troubleshooting de Stork Agent

### Escenari

L'agent del secondary no es registra correctament.

### Preparació (simular l'error)

```bash
# Atura l'agent
docker exec clab-kea-lab-stork-kea-secondary supervisorctl stop stork-agent

# Reinicia amb URL incorrecta
docker exec clab-kea-lab-stork-kea-secondary sh -c '
/usr/bin/stork-agent --server-url http://servidor-inexistent:8080 --host kea-secondary &
'
```

### Diagnòstic

**T4.3.1**: Comprova l'estat dels processos:

```bash
docker exec clab-kea-lab-stork-kea-secondary supervisorctl status
docker exec clab-kea-lab-stork-kea-secondary ps aux | grep stork
```

**T4.3.2**: Mira els logs de l'agent:

```bash
docker exec clab-kea-lab-stork-kea-secondary cat /var/log/kea/stork-agent.err.log | tail -20
```

**T4.3.3**: Verifica la connectivitat:

```bash
docker exec clab-kea-lab-stork-kea-secondary ping -c 2 clab-kea-lab-stork-stork-server
```

### Tasques

1. Identifica quin és el problema
2. Explica per què l'agent no pot registrar-se
3. Proposa com corregir-ho

### Solució

```bash
# Atura el procés erroni
docker exec clab-kea-lab-stork-kea-secondary pkill stork-agent

# Reinicia amb supervisord (que té la config correcta)
docker exec clab-kea-lab-stork-kea-secondary supervisorctl start stork-agent

# Verifica
sleep 10
docker exec clab-kea-lab-stork-kea-secondary supervisorctl status
```

---

## 4.4 Repte Final: Desplegament Complet

### Escenari

Has de desplegar una infraestructura DHCP per una empresa amb els següents requisits:

#### Requisits funcionals

1. **4 departaments** (VLANs):
   - Administració: 10.50.10.0/24 (pool .50-.100)
   - Desenvolupament: 10.50.20.0/24 (pool .50-.150)
   - Producció: 10.50.30.0/24 (pool .50-.200)
   - Convidats: 10.50.40.0/24 (pool .100-.200, lease time 1 hora)

2. **Alta disponibilitat**: Dos servidors en mode load-balancing

3. **Monitorització**: Stork amb accés web

4. **Reserves**:
   - Servidor d'impressió (Administració): `00:11:22:33:44:55` → `10.50.10.10`
   - Servidor CI/CD (Desenvolupament): `00:11:22:33:44:66` → `10.50.20.10`

5. **Opcions personalitzades per departament**:
   - Tots: DNS 10.50.1.53 i 10.50.1.54
   - Desenvolupament: domini `dev.empresa.local`
   - Producció: domini `prod.empresa.local`
   - Convidats: domini `guest.empresa.local`

### Lliurament

1. Fitxers de configuració modificats
2. Topologia actualitzada
3. Documentació dels canvis (breu)
4. Captures de:
   - Clients de cada VLAN amb IP correcta
   - Stork mostrant els 4 daemons
   - Un failover exitós

### Comandes de verificació

```bash
# Test bàsic de cada VLAN
for vlan in 10 20 30 40; do
    echo "=== VLAN $vlan ==="
    docker exec clab-kea-lab-stork-client-vlan$vlan dhclient -v eth1 2>&1 | grep "bound"
    docker exec clab-kea-lab-stork-client-vlan$vlan ip addr show eth1 | grep inet
done

# Verificar reserves (si pots canviar la MAC)
# Cal executar amb la MAC correcta

# Verificar Stork
curl -s http://localhost:8080/api/machines | jq .

# Verificar HA
docker exec clab-kea-lab-stork-postgres psql -U postgres -d stork -c \
    "SELECT d.name, d.version FROM daemon d JOIN app a ON d.app_id = a.id;"
```

### Rúbrica específica del repte final

| Criteri | Punts |
|---------|-------|
| 4 VLANs funcionant | 2 |
| Pools correctes | 1 |
| HA funcionant | 2 |
| Stork operatiu | 1.5 |
| Reserves configurades | 1 |
| Opcions per departament | 1 |
| Documentació | 1 |
| Failover demostrat | 0.5 |
| **Total** | **10** |

### Finalització

```bash
./scripts/destroy.sh stork
```

---

# Rúbriques d'Avaluació

## Rúbrica General per Reptes

| Nivell | Descripció | Punts |
|--------|------------|-------|
| **Excel·lent** | Solució completa, ben documentada, sense errors | 10 |
| **Notable** | Solució funcional amb petites mancances | 8-9 |
| **Bé** | Solució parcialment funcional, identifica els problemes | 6-7 |
| **Suficient** | Intenta la solució, identifica alguns problemes | 5 |
| **Insuficient** | No arriba a una solució funcional | 0-4 |

## Rúbrica per Activitats d'Identificació

| Criteri | Excel·lent (2.5) | Bé (1.5) | Insuficient (0.5) |
|---------|------------------|----------|-------------------|
| Precisió de les dades | Totes correctes | >75% correctes | <50% correctes |
| Comprensió demostrada | Explica el perquè | Només dades | Dades incorrectes |

## Rúbrica per Troubleshooting

| Criteri | Punts |
|---------|-------|
| Identifica correctament el problema | 3 |
| Explica la causa arrel | 3 |
| Proposa solució correcta | 2 |
| Verifica la solució | 2 |
| **Total** | **10** |

---

# Solucions

## Sessió 1

### P1.1
DISCOVER → OFFER → REQUEST → ACK (DORA)

### P1.2
- `renew-timer` (T1): El client intenta renovar amb el servidor original (50% del lease)
- `rebind-timer` (T2): El client intenta amb qualsevol servidor (87.5% del lease)
- T2 > T1 perquè primer s'intenta el servidor original, i només si falla es busquen alternatives

### P1.3
- `raw`: Permet enviar/rebre paquets sense tenir IP configurada (necessari per clients sense IP)
- `udp`: Requereix stack IP complet, pot tenir problemes amb clients nous

### P1.4
- Simple, no requereix infraestructura addicional
- Fàcil de debugar (fitxer CSV llegible)
- Suficient per a entorns petits/proves

### T1.3 - Errors de configuració

1. **`valid-lifetime: "quatre mil"`**: Ha de ser numèric → `4000`
2. **`rebind-timer: 500`**: Ha de ser > renew-timer → `2000`
3. **`interfaces: ["eth99"]`**: Interfície inexistent → `["eth1"]`
4. **`pool: "10.50.10.250 - 10.50.10.300"`**: .300 no és vàlid → `"10.50.10.100 - 10.50.10.200"`
5. **`routers: "10.50.20.1"`**: Està fora de la subnet 10.50.10.0/24 → `"10.50.10.1"`

---

## Sessió 2

### P2.1
El DHCP Discover és broadcast (destí 255.255.255.255). Els routers no reenvien broadcasts entre xarxes per defecte.

### P2.2
- `giaddr` = Gateway IP Address
- L'omple el relay agent
- Conté la IP de la interfície del relay que connecta amb els clients

### P2.3
S'usa la IP d'eth2 (la de la VLAN dels clients). Per exemple, 10.50.10.1 per VLAN10. Perquè és la xarxa on estan els clients i indica al servidor quina subnet usar.

### P2.4
El servidor mira el camp `giaddr` del paquet reenviat pel relay. Com que giaddr = IP del relay a la xarxa client (ex: 10.50.10.1), Kea busca una subnet que contingui aquesta IP.

### T2.3 - Troubleshooting relay
**Problema**: El relay està configurat per enviar a 10.50.1.99, però el servidor Kea està a 10.50.1.10.
**Solució**: Corregir l'adreça del servidor DHCP a la configuració del relay.

---

## Sessió 3

### P3.1
- **Load-balancing**: Ambdós servidors actius, reparteixen clients
- **Hot-standby**: Un actiu, l'altre passiu (només assumeix si el primary falla)

### P3.2
- Trànsit de sincronització no interfereix amb el servei DHCP
- Més seguretat (xarxa aïllada)
- Fàcil diagnòstic de problemes

### P3.3
El servidor entra en estat `partner-down` i assumeix tot el pool d'adreces (failover automàtic si `auto-failover: true`).

### P3.4
Hash de l'adreça MAC del client. Cada servidor respon a aproximadament el 50% dels clients de forma determinista.

### P3.5
L'HA de Kea utilitza mecanismes de sincronització que no són thread-safe amb multi-threading activat (limitació de la implementació actual).

---

## Sessió 4

### P4.1
- **kea-ctrl-agent**: API REST per controlar Kea localment (rep comandes, les envia via socket Unix a kea-dhcp4)
- **stork-agent**: Agent que connecta amb Stork Server, recol·lecta info de kea-ctrl-agent
- Flux: Stork Server ↔ stork-agent ↔ kea-ctrl-agent ↔ kea-dhcp4

### P4.2
Docker està dissenyat per un procés per contenidor. Amb Stork necessitem 3 processos (kea-dhcp4, kea-ctrl-agent, stork-agent). Supervisord gestiona múltiples processos.

### P4.3
1. Stork Server demana estadístiques a stork-agent
2. stork-agent fa petició HTTP a kea-ctrl-agent (port 8000)
3. kea-ctrl-agent envia comanda via socket Unix a kea-dhcp4
4. kea-dhcp4 respon amb les dades
5. La resposta torna pel mateix camí

### P4.4
Seguretat: Cal verificar que els agents que es connecten són legítims i autoritzats per l'administrador.

---

## Repte Final - Guia de solució

### Modificacions necessàries

1. **Afegir VLAN40** a topology.clab.yml:
```yaml
br-vlan40:
  kind: bridge

client-vlan40:
  kind: linux
  image: nicolaka/netshoot:latest

relay-vlan40:
  kind: linux
  image: kea-relay:latest
  env:
    DHCP_SERVER: "10.50.1.10 10.50.1.11"
    LISTEN_INTERFACE: "eth2"
  exec:
    - ip addr add 10.50.1.24/24 dev eth1
    - ip addr add 10.50.40.1/24 dev eth2
```

2. **Afegir subnet40** a kea-dhcp4.conf:
```json
{
    "id": 40,
    "subnet": "10.50.40.0/24",
    "valid-lifetime": 3600,
    "pools": [{ "pool": "10.50.40.100 - 10.50.40.200" }],
    "option-data": [
        { "name": "routers", "data": "10.50.40.1" },
        { "name": "domain-search", "data": "guest.empresa.local" }
    ]
}
```

3. **Modificar DNS global**:
```json
"option-data": [
    { "name": "domain-name-servers", "data": "10.50.1.53, 10.50.1.54" }
]
```

4. **Afegir reserves** a les subnets corresponents:
```json
"reservations": [
    {
        "hw-address": "00:11:22:33:44:55",
        "ip-address": "10.50.10.10"
    }
]
```

5. **Afegir links** per la nova VLAN i rutes als servidors Kea.

---

## Notes finals

- Les solucions proporcionades són orientatives
- Es valorarà especialment la comprensió demostrada en les explicacions
- És acceptable arribar a solucions alternatives si són correctes i estan justificades
