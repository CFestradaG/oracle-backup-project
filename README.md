# Sistema Integral de Backups Oracle XE 21c

**Proyecto Final — Base de Datos II | Universidad Mariano Gálvez de Guatemala**

Imagen Docker con Oracle XE 21c preconfigurada con ARCHIVELOG, TDE Wallet AES128 y RMAN automatizado. Un solo comando levanta la base de datos completamente lista.

| | |
|---|---|
| **Docker Hub** | `cestrda/oracle-backup-xe:latest` |
| **GitHub** | `github.com/cestrda/oracle-backup-xe` |
| **Oracle versión** | 21c Express Edition (21.3.0.0) |

---

## Requisitos previos

- Docker Desktop instalado y corriendo
- Mínimo **4 GB de RAM** disponibles para el contenedor
- Mínimo **10 GB de espacio en disco**
- Conexión a internet (solo para el primer `docker pull`)

---

## Opción A — Usar la imagen de Docker Hub (recomendado)

Es la forma más rápida. No requiere clonar el repositorio.

### Paso 1: Descargar la imagen

```bash
docker pull cestrda/oracle-backup-xe:latest
```

### Paso 2: Crear y levantar el contenedor

```bash
docker run -d \
  --name oracle-backup \
  -p 1521:1521 \
  -p 5500:5500 \
  -e ORACLE_PASSWORD=Oracle123# \
  cestrda/oracle-backup-xe:latest
```

> **En Windows (PowerShell)** usa backtick `` ` `` en lugar de `\` para continuar líneas:
> ```powershell
> docker run -d `
>   --name oracle-backup `
>   -p 1521:1521 -p 5500:5500 `
>   -e ORACLE_PASSWORD=Oracle123# `
>   cestrda/oracle-backup-xe:latest
> ```

### Paso 3: Monitorear la inicialización

```bash
docker logs -f oracle-backup
```

La primera vez tarda aproximadamente **5 minutos**. La base de datos está lista cuando aparece:

```
#########################
DATABASE IS READY TO USE!
#########################
```

Durante ese tiempo, los scripts de inicialización se ejecutan en orden:
- `[01]` Habilita ARCHIVELOG y configura FRA (2 GB)
- `[02]` Crea el TDE Wallet con cifrado AES128
- `[03]` Aplica la configuración persistente de RMAN
- `[04]` Registra el backup automático diario a las 02:00 AM

---

## Opción B — Construir desde el código fuente

```bash
git clone https://github.com/cestrda/oracle-backup-xe.git
cd oracle-backup-xe
docker compose up -d
docker logs -f oracle-backup
```

---

## Credenciales

| Componente | Usuario | Contraseña |
|---|---|---|
| Oracle SYS | `SYS` | `Oracle123#` |
| Oracle SYSTEM | `SYSTEM` | `Oracle123#` |
| PDB XEPDB1 | `PDBADMIN` | `Oracle123#` |
| TDE Wallet | — | `WalletPass123#` |

---

## Verificar que todo funciona

Una vez que el contenedor muestre `DATABASE IS READY TO USE!`, ejecuta los siguientes comandos para confirmar cada componente.

### Conectar a SQL*Plus

```bash
docker exec -it oracle-backup sqlplus / as sysdba
```

### Verificar modo ARCHIVELOG

```sql
SELECT NAME, LOG_MODE FROM V$DATABASE;
```
Resultado esperado: `LOG_MODE = ARCHIVELOG`

### Verificar Flash Recovery Area (FRA)

```sql
SHOW PARAMETER db_recovery_file_dest;
```
Resultado esperado: `VALUE = /opt/oracle/fra` y `VALUE = 2G`

### Verificar TDE Wallet

```sql
SELECT CON_ID, STATUS, WALLET_TYPE FROM V$ENCRYPTION_WALLET;
```
Resultado esperado: tres filas (CON_ID 1, 2, 3) con `STATUS = OPEN`

```sql
EXIT;
```

### Verificar configuración RMAN

```bash
docker exec -it oracle-backup rman target /
```
```
RMAN> SHOW ALL;
RMAN> EXIT;
```
Resultado esperado: `CONFIGURE ENCRYPTION FOR DATABASE ON`, `AES128`, `RECOVERY WINDOW OF 7 DAYS`

---

## Ejecutar el backup

### Backup manual

```bash
docker exec oracle-backup /opt/oracle/backup/scripts/run_backup.sh
```

La salida termina con `RESULTADO: BACKUP EXITOSO | Duración: XXs`.

### Ver el historial de backups

```bash
docker exec oracle-backup cat /opt/oracle/backup/logs/historial.log
```

### Ver los backupsets en RMAN

```bash
docker exec -it oracle-backup rman target /
```
```
RMAN> LIST BACKUP SUMMARY;
RMAN> EXIT;
```

### Backup automático (cron)

El contenedor ejecuta el backup automáticamente todos los días a las **02:00 AM**. El log se guarda en:

```
/opt/oracle/backup/logs/backup_YYYYMMDD_HHMMSS.log
/opt/oracle/backup/logs/historial.log
/opt/oracle/backup/logs/ALERTAS.log   ← solo si hay errores
```

---

## Demostración para el profesor

### Abrir y cerrar el TDE Wallet

```bash
docker exec -it oracle-backup sqlplus / as sysdba
```
```sql
-- Ver estado actual
SELECT CON_ID, STATUS, WALLET_TYPE FROM V$ENCRYPTION_WALLET;

-- Cerrar el wallet
ADMINISTER KEY MANAGEMENT SET KEYSTORE CLOSE
    IDENTIFIED BY "WalletPass123#" CONTAINER=ALL;

-- Verificar cerrado
SELECT CON_ID, STATUS, WALLET_TYPE FROM V$ENCRYPTION_WALLET;

-- Abrir el wallet
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
    IDENTIFIED BY "WalletPass123#" CONTAINER=ALL;

-- Verificar abierto
SELECT CON_ID, STATUS, WALLET_TYPE FROM V$ENCRYPTION_WALLET;

EXIT;
```

### RESTORE VALIDATE (prueba de integridad)

Verifica que los backups son válidos y recuperables sin restaurar datos.

```bash
docker exec -it oracle-backup rman target /
```
```
RMAN> LIST BACKUP SUMMARY;
RMAN> RESTORE DATABASE VALIDATE;
RMAN> RESTORE ARCHIVELOG ALL VALIDATE;
RMAN> EXIT;
```

Resultado esperado: `validation complete` en cada pieza del backup.

---

## Comandos útiles

| Acción | Comando |
|---|---|
| Ver logs en tiempo real | `docker logs -f oracle-backup` |
| Entrar a SQL\*Plus | `docker exec -it oracle-backup sqlplus / as sysdba` |
| Entrar a RMAN | `docker exec -it oracle-backup rman target /` |
| Ejecutar backup manual | `docker exec oracle-backup /opt/oracle/backup/scripts/run_backup.sh` |
| Ver historial | `docker exec oracle-backup cat /opt/oracle/backup/logs/historial.log` |
| Detener el contenedor | `docker stop oracle-backup` |
| Eliminar el contenedor | `docker rm oracle-backup` |
| Reiniciar el contenedor | `docker start oracle-backup` |

---

## Estructura del proyecto

```
oracle-backup-project/
├── Dockerfile                      # Definición de la imagen Docker
├── docker-compose.yml              # Orquestación del contenedor
├── .env.example                    # Plantilla de variables de entorno
├── scripts/                        # Se ejecutan UNA VEZ en el primer inicio
│   ├── 01_archivelog_fra.sh        # Habilita ARCHIVELOG + configura FRA 2GB
│   ├── 02_wallet_tde.sh            # Crea TDE Wallet + AES128 + auto-login
│   ├── 03_rman_config.sh           # Retención 7 días, cifrado, compresión MEDIUM
│   └── 04_cron_setup.sh            # Registra el backup diario a las 02:00 AM
└── backup/                         # Disponibles siempre
    ├── rman_backup.rman            # Script RMAN principal (backup + mantenimiento)
    └── run_backup.sh               # Orquestador con logs y alertas
```

---

## Cobertura de la rúbrica

| Criterio | Puntos | Implementación |
|---|---|---|
| Cifrado y Wallet | 3 | TDE Software Keystore + AES128 (`02_wallet_tde.sh`) |
| Lógica RMAN y Multitenant | 3 | Backup CDB+PDB, compresión MEDIUM, retención 7 días (`rman_backup.rman`) |
| Mantenimiento y FRA | 3 | FRA 2GB, CROSSCHECK, DELETE OBSOLETE (`rman_backup.rman`) |
| Automatización y Alertas | 3 | Cron 02:00 AM, logs con timestamp, alertas en fallo (`run_backup.sh`) |
| Documentación y Prueba | 3 | Manual técnico + RESTORE VALIDATE exitoso |
| **Total** | **15** | |
