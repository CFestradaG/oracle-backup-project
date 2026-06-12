# Sistema Integral de Backups Oracle XE
**Proyecto Final - Base de Datos II | Universidad Mariano Gálvez de Guatemala**

Imagen Docker con Oracle XE 21c configurada con ARCHIVELOG, TDE Wallet (AES128) y RMAN automatizado.

---

## Requisitos
- Docker Desktop instalado y corriendo
- Mínimo 4GB de RAM disponible para el contenedor
- Mínimo 10GB de espacio en disco

---

## Inicio rápido

### Opción A: Usar la imagen publicada en Docker Hub (recomendado)
```bash
# Descargar y levantar el contenedor
docker pull cestrda/oracle-backup-xe:latest
# Despues de descartar levantar el contenedor
docker run -d --name oracle-backup2 `
  -p 1521:1521 -p 5500:5500 `
  -e ORACLE_PASSWORD=Oracle123# `
  cestrda/oracle-backup-xe:latest


# Ver el progreso de inicialización (tarda ~5 minutos la primera vez)
docker logs -f oracle-backup
```

### Opción B: Construir desde el código fuente
```bash
git clone https://github.com/cestrda/oracle-backup-xe.git
cd oracle-backup-xe
docker build -t cestrda/oracle-backup-xe:latest .
docker compose up -d
```

---

## Credenciales
| Componente | Usuario/Parámetro | Valor |
|---|---|---|
| Oracle SYS | `SYS` | `Oracle123#` |
| Oracle SYSTEM | `SYSTEM` | `Oracle123#` |
| PDB XEPDB1 | `PDBADMIN` | `Oracle123#` |
| TDE Wallet | contraseña | `WalletPass123#` |

---

## Comandos de demostración para el proyecto

### Conectar a la base de datos
```bash
docker exec -it oracle-backup sqlplus / as sysdba
```

### Verificar modo ARCHIVELOG
```sql
ARCHIVE LOG LIST;
SELECT NAME, LOG_MODE FROM V$DATABASE;
```

### Verificar FRA
```sql
SHOW PARAMETER db_recovery_file_dest;
```

### Abrir el TDE Wallet (lo que el ingeniero pedirá demostrar)
```sql
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
    IDENTIFIED BY "WalletPass123#"
    CONTAINER=ALL;

-- Verificar estado
SELECT CON_ID, STATUS, WALLET_TYPE FROM V$ENCRYPTION_WALLET;
```

### Ejecutar backup manualmente
```bash
docker exec oracle-backup /opt/oracle/backup/scripts/run_backup.sh
```

### Restore Validate (lo que el ingeniero pedirá demostrar)
```bash
docker exec -it oracle-backup rman target /
```
```
# Dentro de RMAN:
RESTORE DATABASE VALIDATE;
```

### Ver logs del último backup
```bash
docker exec oracle-backup ls -lt /opt/oracle/backup/logs/
docker exec oracle-backup tail -50 /opt/oracle/backup/logs/historial.log
```

---

## Estructura del proyecto
```
oracle-backup-project/
├── Dockerfile                      # Definición de la imagen
├── docker-compose.yml              # Orquestación del contenedor
├── .env.example                    # Plantilla de variables de entorno
├── .gitignore
├── README.md
├── scripts/                        # Scripts de inicialización (1ra vez)
│   ├── 01_archivelog_fra.sh        # Habilita ARCHIVELOG + FRA
│   ├── 02_wallet_tde.sh            # Crea TDE Wallet + AES128
│   ├── 03_rman_config.sh           # Configura RMAN (retención, cifrado)
│   └── 04_cron_setup.sh            # Inicia cron + backup automático
└── backup/                         # Scripts de backup (siempre disponibles)
    ├── rman_backup.rman            # Script RMAN principal
    └── run_backup.sh               # Wrapper Bash con logs y alertas
```

---

## Configuración cubierta (rúbrica del proyecto)

| Criterio | Configuración | Puntos |
|---|---|---|
| **Cifrado y Wallet** | TDE Software Keystore + AES128 en `02_wallet_tde.sh` | 3 |
| **Lógica RMAN y Multitenant** | Backup CDB+PDB, compresión MEDIUM, retención 7 días en `rman_backup.rman` | 3 |
| **Mantenimiento y FRA** | FRA 2GB, CROSSCHECK, DELETE OBSOLETE en `rman_backup.rman` | 3 |
| **Automatización y Alertas** | Cron diario 02:00, logs con timestamp, alertas en `run_backup.sh` | 3 |
| **Documentación y Prueba** | Manual técnico + RESTORE VALIDATE | 3 |
