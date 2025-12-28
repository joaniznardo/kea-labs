-- Script d'inicialització de PostgreSQL per Kea DHCP i Stork
-- Aquest script es crea les bases de dades i usuaris necessaris

-- Base de dades per als leases de Kea
CREATE DATABASE kea;
CREATE USER kea WITH PASSWORD 'kea';
GRANT ALL PRIVILEGES ON DATABASE kea TO kea;

-- Base de dades per a Stork
CREATE DATABASE stork;
CREATE USER stork WITH PASSWORD 'stork';
GRANT ALL PRIVILEGES ON DATABASE stork TO stork;

-- Connectar a la base de dades kea per donar permisos al schema
\c kea
GRANT ALL ON SCHEMA public TO kea;

-- Connectar a la base de dades stork per donar permisos al schema
\c stork
GRANT ALL ON SCHEMA public TO stork;
