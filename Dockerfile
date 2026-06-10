# =============================================================================
# Dockerfile - Sistema Integral de Backups Oracle XE
# Proyecto Final - Base de Datos II - UMG
# Autor: cestrda
# =============================================================================
FROM gvenzl/oracle-xe:21-full

LABEL maintainer="cestrda"
LABEL description="Oracle XE 21c - ARCHIVELOG + TDE Wallet AES128 + RMAN Automatizado"
LABEL version="1.0"
LABEL project="Proyecto Final Base de Datos II - UMG"

# -----------------------------------------------------------------------------
# Crear directorios y configurar cron como root
# -----------------------------------------------------------------------------
USER root

RUN microdnf install -y cronie && \
    microdnf clean all && \
    mkdir -p /opt/oracle/wallet \
             /opt/oracle/fra \
             /opt/oracle/backup/logs \
             /opt/oracle/backup/scripts \
             /container-entrypoint-startdb.d && \
    chown -R oracle:dba /opt/oracle/wallet \
                        /opt/oracle/fra \
                        /opt/oracle/backup && \
    chmod 700 /opt/oracle/wallet && \
    # Crontab: backup diario a las 02:00 AM
    echo "0 2 * * * oracle /opt/oracle/backup/scripts/run_backup.sh >> /opt/oracle/backup/logs/cron.log 2>&1" \
        > /etc/cron.d/oracle-backup && \
    chmod 644 /etc/cron.d/oracle-backup

# Script de inicio de crond (se ejecuta cada vez que el contenedor arranca)
# Usa /container-entrypoint-startdb.d/ que gvenzl ejecuta en cada inicio
RUN printf '#!/bin/bash\necho "[CRON] Iniciando servicio crond..."\ncrond\necho "[CRON] crond iniciado (PID: $(cat /var/run/crond.pid 2>/dev/null || echo desconocido))"\n' \
    > /container-entrypoint-startdb.d/start_crond.sh && \
    chmod +x /container-entrypoint-startdb.d/start_crond.sh

# -----------------------------------------------------------------------------
# Copiar scripts de inicialización (se ejecutan UNA VEZ en el primer arranque)
# -----------------------------------------------------------------------------
COPY --chown=oracle:dba scripts/01_archivelog_fra.sh   /container-entrypoint-initdb.d/
COPY --chown=oracle:dba scripts/02_wallet_tde.sh        /container-entrypoint-initdb.d/
COPY --chown=oracle:dba scripts/03_rman_config.sh       /container-entrypoint-initdb.d/
COPY --chown=oracle:dba scripts/04_cron_setup.sh        /container-entrypoint-initdb.d/

# -----------------------------------------------------------------------------
# Copiar scripts de backup (disponibles siempre)
# -----------------------------------------------------------------------------
COPY --chown=oracle:dba backup/rman_backup.rman  /opt/oracle/backup/scripts/
COPY --chown=oracle:dba backup/run_backup.sh     /opt/oracle/backup/scripts/

RUN chmod +x /container-entrypoint-initdb.d/01_archivelog_fra.sh \
             /container-entrypoint-initdb.d/02_wallet_tde.sh \
             /container-entrypoint-initdb.d/03_rman_config.sh \
             /container-entrypoint-initdb.d/04_cron_setup.sh \
             /opt/oracle/backup/scripts/run_backup.sh

USER oracle
EXPOSE 1521 5500
VOLUME ["/opt/oracle/fra", "/opt/oracle/backup", "/opt/oracle/wallet"]
