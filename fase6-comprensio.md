# Fase 6 — Activitats de comprensió: Integració DHCP i DNS

Aquestes 20 activitats estan dissenyades per treballar pas a pas la integració entre Kea DHCP i BIND9 DNS de la fase 6. Cada activitat inclou les ordres necessàries i preguntes de reflexió.

> **Requisit previ:** Desplegar la fase 6 amb `./scripts/deploy.sh dns` i verificar que tots els contenidors estan actius amb `docker ps`.

---

## Bloc 1 — Descoberta de l'entorn (activitats 1–4)

### Activitat 1. Identificar els contenidors i les xarxes

Executa les ordres següents i respon les preguntes.

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

```bash
docker network ls | grep clab
```

**Preguntes:**

1. Quants contenidors formen part del laboratori? Classifica'ls per funció (servidor DHCP, servidor DNS, relay, client).
2. Quina imatge Docker fa servir cada tipus de contenidor?
3. Per què hi ha dos servidors Kea i dos servidors DNS?

---

### Activitat 2. Explorar la topologia de xarxa

Consulta les adreces IP de cada contenidor.

```bash
docker exec clab-kea-lab-dns-kea-primary ip -4 addr show
```

```bash
docker exec clab-kea-lab-dns-relay-vlan10 ip -4 addr show
```

```bash
docker exec clab-kea-lab-dns-dns-primary ip -4 addr show
```

```bash
docker exec clab-kea-lab-dns-dns-secondary ip -4 addr show
```

**Preguntes:**

1. A quines xarxes està connectat `kea-primary`? I `kea-secondary`?
2. Quina xarxa comparteixen els servidors Kea que no comparteixen amb cap altre contenidor? Quina funció té?
3. En quina xarxa es troba el servidor DNS secundari? Per què no està a la xarxa backend?

---

### Activitat 3. Comprendre les rutes dels relays

Examina la taula d'encaminament d'un relay.

```bash
docker exec clab-kea-lab-dns-relay-vlan10 ip route
```

```bash
docker exec clab-kea-lab-dns-relay-vlan20 ip route
```

**Preguntes:**

1. Quines rutes té configurat `relay-vlan10` cap a les altres VLANs?
2. Per què els relays tenen `ip_forward=1` activat? Quina relació té amb les consultes DNS?
3. Com arriba un paquet des de `client-vlan10` fins al servidor `dns-primary` (10.50.1.50)? Descriu el camí complet.

---

### Activitat 4. Verificar la connectivitat bàsica

Comprova que els clients poden arribar als servidors DNS.

```bash
docker exec clab-kea-lab-dns-client-vlan10 ping -c 2 10.50.1.50
```

```bash
docker exec clab-kea-lab-dns-client-vlan10 ping -c 2 10.50.20.51
```

```bash
docker exec clab-kea-lab-dns-client-vlan30 ping -c 2 10.50.1.50
```

**Preguntes:**

1. Poden els clients de totes les VLANs arribar al DNS primari? I al secundari?
2. Si un client de la VLAN 30 fa ping al DNS secundari (10.50.20.51), per quants relays passa el paquet?
3. Què passaria si `relay-vlan10` no tingués `ip_forward=1`?

---

## Bloc 2 — Funcionament del DHCP amb relays (activitats 5–8)

### Activitat 5. Obtenir una adreça IP via DHCP

Sol·licita una adreça per al client de la VLAN 10.

```bash
docker exec clab-kea-lab-dns-client-vlan10 udhcpc -i eth1 -n
```

**Preguntes:**

1. Quina adreça IP ha obtingut el client? Està dins del rang configurat (.100–.200)?
2. Quin és el gateway assignat? Correspon a l'adreça del relay de la VLAN 10?
3. Quins servidors DNS ha rebut el client com a part de les opcions DHCP?

---

### Activitat 6. Verificar les opcions DHCP rebudes

Després d'obtenir IP, examina la configuració de xarxa del client.

```bash
docker exec clab-kea-lab-dns-client-vlan10 ip -4 addr show eth1
```

```bash
docker exec clab-kea-lab-dns-client-vlan10 cat /etc/resolv.conf
```

**Preguntes:**

1. Quin domini de cerca (search domain) apareix a `/etc/resolv.conf`?
2. Quins servidors DNS apareixen a `resolv.conf`? Coincideixen amb els configurats a `kea-dhcp4.conf`?
3. Per què és important que Kea distribueixi els servidors DNS interns en comptes dels públics (1.1.1.1)?

---

### Activitat 7. Obtenir adreces a les tres VLANs

Repeteix el procés per a les tres VLANs i observa les diferències.

```bash
docker exec clab-kea-lab-dns-client-vlan10 udhcpc -i eth1 -n
```

```bash
docker exec clab-kea-lab-dns-client-vlan20 udhcpc -i eth1 -n
```

```bash
docker exec clab-kea-lab-dns-client-vlan30 udhcpc -i eth1 -n
```

```bash
docker exec clab-kea-lab-dns-kea-primary cat /var/lib/kea/kea-leases4.csv
```

**Preguntes:**

1. Cada client rep una adreça del rang correcte de la seva VLAN?
2. Quants leases apareixen al fitxer CSV? Quins camps conté cada línia?
3. Com sap el servidor Kea a quina VLAN pertany cada petició si tots els paquets arriben pel relay a la mateixa interfície (10.50.1.0/24)?

---

### Activitat 8. Comprendre el paper del relay

Observa els logs del relay per entendre el procés de retransmissió.

```bash
docker logs clab-kea-lab-dns-relay-vlan10 2>&1 | tail -20
```

```bash
docker logs clab-kea-lab-dns-kea-primary 2>&1 | grep -i "dhcp4" | tail -10
```

**Preguntes:**

1. El relay envia les peticions DHCP a un sol servidor Kea o a tots dos? Per què?
2. Quin camp del paquet DHCP relayed indica al servidor Kea la subxarxa d'origen del client?
3. Si el `kea-primary` cau, què fa el relay? Qui respon les peticions DHCP?

---

## Bloc 3 — Funcionament del DNS (activitats 9–12)

### Activitat 9. Consultar registres DNS estàtics

Fes consultes DNS als registres predefinits a la zona.

```bash
docker exec clab-kea-lab-dns-client-vlan10 nslookup kea-primary.demoasix2025.test 10.50.1.50
```

```bash
docker exec clab-kea-lab-dns-client-vlan10 nslookup dns-primary.demoasix2025.test 10.50.1.50
```

```bash
docker exec clab-kea-lab-dns-client-vlan10 nslookup relay-vlan20.demoasix2025.test 10.50.1.50
```

**Preguntes:**

1. Quina adreça IP retorna per a `kea-primary`? Coincideix amb la IP real del contenidor?
2. On estan definits aquests registres estàtics? Consulta el fitxer de zona.
3. Podries resoldre `google.com` des d'aquest DNS? Per què sí o per què no? (Pista: revisa si la recursió està habilitada.)

---

### Activitat 10. Consultar el DNS secundari

Repeteix les consultes però dirigint-les al DNS secundari.

```bash
docker exec clab-kea-lab-dns-client-vlan20 nslookup kea-primary.demoasix2025.test 10.50.20.51
```

```bash
docker exec clab-kea-lab-dns-client-vlan20 nslookup dns-secondary.demoasix2025.test 10.50.20.51
```

**Preguntes:**

1. El DNS secundari respon amb les mateixes dades que el primari?
2. Com obté el DNS secundari les dades de zona? Quin mecanisme utilitza (AXFR/IXFR)?
3. Si modifiquem un registre al DNS primari, quant de temps trigarà el secundari a reflectir el canvi?

---

### Activitat 11. Examinar els fitxers de zona

Consulta directament els fitxers de zona del servidor DNS primari.

```bash
docker exec clab-kea-lab-dns-dns-primary cat /var/lib/bind/db.demoasix2025.test
```

```bash
docker exec clab-kea-lab-dns-dns-primary cat /var/lib/bind/db.10.50.10
```

**Preguntes:**

1. Identifica el registre SOA: quin és el servidor primari (MNAME)? Quin és el correu de l'administrador?
2. Quins registres NS (Name Server) té la zona?
3. Què és un registre DHCID que apareix al fitxer de zona? Quina funció té?

---

### Activitat 12. Comprovar la resolució inversa (PTR)

Fes consultes de resolució inversa per convertir IP a nom.

```bash
docker exec clab-kea-lab-dns-client-vlan10 nslookup 10.50.1.50 10.50.1.50
```

```bash
docker exec clab-kea-lab-dns-client-vlan10 nslookup 10.50.1.10 10.50.1.50
```

**Preguntes:**

1. Quin nom retorna per a la IP 10.50.1.50? I per a la 10.50.1.10?
2. En quin fitxer de zona estan definits aquests registres PTR?
3. Per què cal mantenir coherència entre els registres A (directes) i els PTR (inversos)?

---

## Bloc 4 — Integració DHCP + DNS / DDNS (activitats 13–16)

### Activitat 13. Observar el DDNS en acció

Sol·licita una IP per DHCP i comprova que es crea automàticament el registre DNS.

```bash
docker exec clab-kea-lab-dns-client-vlan10 udhcpc -i eth1 -n
```

Anota la IP obtinguda (per exemple, 10.50.10.100) i fes la consulta DNS corresponent.

```bash
docker exec clab-kea-lab-dns-client-vlan10 nslookup dhcp-10-50-10-100.demoasix2025.test 10.50.1.50
```

```bash
docker exec clab-kea-lab-dns-client-vlan10 nslookup 10.50.10.100 10.50.1.50
```

**Preguntes:**

1. El nom `dhcp-10-50-10-100.demoasix2025.test` existeix al DNS? Quina IP retorna?
2. La resolució inversa de la IP obtinguda retorna el nom correcte?
3. Qui ha creat aquests registres DNS: un administrador manualment o un procés automàtic? Quin procés?

---

### Activitat 14. Analitzar el flux DDNS complet

Examina els logs del dimoni kea-dhcp-ddns (D2) per veure les actualitzacions.

```bash
docker logs clab-kea-lab-dns-kea-primary 2>&1 | grep -i "ddns\|d2\|dns" | tail -20
```

```bash
docker exec clab-kea-lab-dns-dns-primary cat /var/lib/bind/db.demoasix2025.test
```

**Preguntes:**

1. Descriu el flux complet des que un client demana IP fins que el registre DNS existeix. Quants processos hi intervenen?
2. Quin protocol i port utilitza la comunicació entre `kea-dhcp4` i `kea-dhcp-ddns` (D2)?
3. Per què el dimoni D2 envia les actualitzacions DNS al servidor primari (10.50.1.50) i no al secundari?

---

### Activitat 15. Comprovar l'autenticació TSIG

Revisa la clau TSIG compartida entre Kea i BIND9.

```bash
docker exec clab-kea-lab-dns-kea-primary cat /etc/kea/kea-dhcp-ddns.conf | grep -A 5 "tsig"
```

```bash
docker exec clab-kea-lab-dns-dns-primary cat /etc/bind/named.conf | grep -A 5 "ddns-key"
```

**Preguntes:**

1. Quina és la clau TSIG compartida? Quin algorisme de hash utilitza?
2. Per què és necessària l'autenticació TSIG? Què passaria si qualsevol host pogués enviar actualitzacions DNS?
3. On està definida la clau a la configuració de BIND9? I a la de Kea?
4. Què significa la directiva `allow-update { key ddns-key; }` a la configuració de BIND9?

---

### Activitat 16. Verificar la propagació al DNS secundari

Comprova que els registres DDNS es propaguen correctament al servidor secundari.

```bash
docker exec clab-kea-lab-dns-client-vlan20 udhcpc -i eth1 -n
```

Espera uns segons i consulta el DNS secundari.

```bash
docker exec clab-kea-lab-dns-client-vlan20 nslookup dhcp-10-50-20-100.demoasix2025.test 10.50.20.51
```

```bash
docker exec clab-kea-lab-dns-client-vlan20 nslookup dhcp-10-50-20-100.demoasix2025.test 10.50.1.50
```

**Preguntes:**

1. El DNS secundari retorna el mateix resultat que el primari per al registre DDNS?
2. Quin mecanisme fa servir BIND9 per notificar el secundari dels canvis? (Pista: `also-notify` i `notify yes`)
3. Quina diferència hi ha entre una transferència AXFR i una IXFR? Quina és més eficient per a canvis DDNS petits?

---

## Bloc 5 — Alta disponibilitat i resiliència (activitats 17–19)

### Activitat 17. Verificar l'estat del clúster HA

Comprova que els dos servidors Kea estan sincronitzats.

```bash
docker exec clab-kea-lab-dns-kea-primary cat /var/lib/kea/kea-leases4.csv | wc -l
```

```bash
docker exec clab-kea-lab-dns-kea-secondary cat /var/lib/kea/kea-leases4.csv | wc -l
```

```bash
docker exec clab-kea-lab-dns-kea-primary ip -4 addr show | grep 10.50.99
```

```bash
docker exec clab-kea-lab-dns-kea-secondary ip -4 addr show | grep 10.50.99
```

**Preguntes:**

1. Tots dos servidors tenen el mateix nombre de leases?
2. Quina xarxa fan servir per comunicar-se entre ells (heartbeat)? Quines IPs tenen?
3. En mode `load-balancing`, com decideixen quin servidor respon cada petició DHCP?

---

### Activitat 18. Simular la caiguda d'un servidor Kea

Atura el servidor primari i observa el comportament.

```bash
docker stop clab-kea-lab-dns-kea-primary
```

Ara sol·licita una IP des d'un client.

```bash
docker exec clab-kea-lab-dns-client-vlan30 udhcpc -i eth1 -n
```

Verifica que el DDNS encara funciona (el secundari també té D2 configurat).

```bash
docker exec clab-kea-lab-dns-client-vlan30 nslookup dhcp-10-50-30-100.demoasix2025.test 10.50.1.50
```

**Preguntes:**

1. El client ha obtingut IP correctament amb el servidor primari aturat?
2. El registre DNS s'ha creat igualment? Quin servidor Kea ha enviat l'actualització DDNS?
3. Quin és el temps de failover configurat? (Pista: consulta `max-response-delay` a `kea-dhcp4.conf`)

Recorda restaurar el servidor:

```bash
docker start clab-kea-lab-dns-kea-primary
```

---

### Activitat 19. Simular la caiguda del DNS primari

Atura el DNS primari i comprova la resolució.

```bash
docker stop clab-kea-lab-dns-dns-primary
```

```bash
docker exec clab-kea-lab-dns-client-vlan20 nslookup kea-primary.demoasix2025.test 10.50.20.51
```

```bash
docker exec clab-kea-lab-dns-client-vlan20 nslookup dhcp-10-50-20-100.demoasix2025.test 10.50.20.51
```

Sol·licita una nova IP per DHCP.

```bash
docker exec clab-kea-lab-dns-client-vlan10 udhcpc -i eth1 -n
```

**Preguntes:**

1. El DNS secundari continua responent les consultes?
2. Quan el DNS primari està aturat, les actualitzacions DDNS es poden completar? Per què?
3. Quina és la diferència entre la disponibilitat de lectura (consultes DNS) i la d'escriptura (actualitzacions DDNS)?
4. Què passa amb els registres DDNS nous quan el primari torni a estar disponible?

Recorda restaurar el servidor:

```bash
docker start clab-kea-lab-dns-dns-primary
```

---

## Bloc 6 — Activitat de síntesi (activitat 20)

### Activitat 20. Traçar el recorregut complet d'un client

Aquesta activitat final integra tots els conceptes. Segueix tot el procés pas a pas per a un client de la VLAN 30.

**Pas 1.** Verifica que el client no té IP configurada.

```bash
docker exec clab-kea-lab-dns-client-vlan30 ip -4 addr show eth1
```

**Pas 2.** Sol·licita una adreça per DHCP.

```bash
docker exec clab-kea-lab-dns-client-vlan30 udhcpc -i eth1 -n
```

**Pas 3.** Confirma la IP i les opcions rebudes.

```bash
docker exec clab-kea-lab-dns-client-vlan30 ip -4 addr show eth1
```

```bash
docker exec clab-kea-lab-dns-client-vlan30 cat /etc/resolv.conf
```

**Pas 4.** Verifica el lease al servidor Kea.

```bash
docker exec clab-kea-lab-dns-kea-primary cat /var/lib/kea/kea-leases4.csv | grep "10.50.30"
```

**Pas 5.** Comprova el registre DNS directe (A) creat per DDNS.

```bash
docker exec clab-kea-lab-dns-client-vlan30 nslookup dhcp-10-50-30-100.demoasix2025.test 10.50.1.50
```

**Pas 6.** Comprova el registre DNS invers (PTR) creat per DDNS.

```bash
docker exec clab-kea-lab-dns-client-vlan30 nslookup 10.50.30.100 10.50.1.50
```

**Pas 7.** Verifica la propagació al DNS secundari.

```bash
docker exec clab-kea-lab-dns-client-vlan30 nslookup dhcp-10-50-30-100.demoasix2025.test 10.50.20.51
```

**Pas 8.** Comprova que un client d'una altra VLAN pot resoldre el nom.

```bash
docker exec clab-kea-lab-dns-client-vlan10 nslookup dhcp-10-50-30-100.demoasix2025.test 10.50.1.50
```

**Activitat final de reflexió:**

Dibuixa un diagrama de seqüència que mostri tots els passos des que `client-vlan30` envia un DHCP DISCOVER fins que qualsevol client de qualsevol VLAN pot resoldre el seu nom per DNS. El diagrama ha d'incloure:

- El client, el relay, el servidor Kea, el dimoni D2, el DNS primari i el DNS secundari.
- Els protocols utilitzats en cada comunicació (DHCP, DNS Update, AXFR/IXFR, NOTIFY).
- L'autenticació TSIG al punt on s'aplica.
- La direcció de cada missatge (qui inicia la comunicació).
