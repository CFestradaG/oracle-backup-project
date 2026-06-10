#!/bin/bash
# =============================================================================
# Script: run_backup.sh
# Descripción: Automatización del backup RMAN con logs y alertas
# Ejecución automática: diario 02:00 AM (cron)
# Ejecución manual: docker exec oracle-backup /opt/oracle/backup/scripts/run_backup.sh
# =============================================================================

export ORACLE_SID=XE
export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
export PATH=${ORACLE_HOME}/bin:${PATH}
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:${LD_LIBRARY_PATH}

RMAN=/opt/oracle/product/21c/dbhomeXE/bin/rman
BACKUP_DIR=/opt/oracle/backup
LOG_DIR=${BACKUP_DIR}/logs
RMAN_SCRIPT=${BACKUP_DIR}/scripts/rman_backup.rman
WALLET_PASSWORD="WalletPass123#"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/backup_${TIMESTAMP}.log"
ALERT_FILE="${LOG_DIR}/ALERTAS.log"
HISTORIAL_FILE="${LOG_DIR}/historial.log"
INICIO_EPOCH=$(date +%s)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"; }

# Usar $HOSTNAME (variable de entorno) en lugar del comando hostname
SERVIDOR=${HOSTNAME:-oracle-db}

send_alert() {
    local msg="$1"
    local ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "================================================================" >> "${ALERT_FILE}"
    echo "[ALERTA - ${ts}] ${msg}" >> "${ALERT_FILE}"
    echo "  Servidor: ${SERVIDOR} | DB: ${ORACLE_SID} | Log: ${LOG_FILE}" >> "${ALERT_FILE}"
    echo "================================================================" >> "${ALERT_FILE}"
    echo ""; echo "!!!!! ALERTA: ${msg}"; echo "!!!!! Log: ${LOG_FILE}"; echo ""
}

registrar_historial() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1 | Duración: $2s | Log: ${LOG_FILE}" >> "${HISTORIAL_FILE}"
}

mkdir -p "${LOG_DIR}"

log "================================================================"
log "  SISTEMA DE BACKUP ORACLE XE - INICIO"
log "  Servidor: ${SERVIDOR} | DB: ${ORACLE_SID} | Timestamp: ${TIMESTAMP}"
log "================================================================"

# Verificar Oracle corriendo con sqlplus
ORACLE_STATUS=$(${ORACLE_HOME}/bin/sqlplus -s / as sysdba << 'EOF'
SET PAGESIZE 0 FEEDBACK OFF
SELECT STATUS FROM V$INSTANCE;
EXIT;
EOF
)
if echo "${ORACLE_STATUS}" | grep -q "OPEN"; then
    log "✓ Oracle está corriendo (STATUS: OPEN)."
else
    log "ERROR: Oracle no está corriendo o no está en estado OPEN."
    send_alert "BACKUP FALLIDO: Oracle ${ORACLE_SID} no disponible en ${SERVIDOR}"
    registrar_historial "FALLIDO - Oracle no activo" "0"
    exit 1
fi

# Verificar script RMAN
if [ ! -f "${RMAN_SCRIPT}" ]; then
    log "ERROR: Script RMAN no encontrado: ${RMAN_SCRIPT}"
    send_alert "BACKUP FALLIDO: Script RMAN no encontrado"
    registrar_historial "FALLIDO - Script no encontrado" "0"
    exit 1
fi
log "✓ Script RMAN: ${RMAN_SCRIPT}"

# Abrir TDE Wallet
log "--- Abriendo TDE Wallet ---"
${ORACLE_HOME}/bin/sqlplus -s / as sysdba << SQLEOF >> "${LOG_FILE}" 2>&1
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "${WALLET_PASSWORD}" CONTAINER=ALL;
SELECT '  CON_ID: '||CON_ID||' STATUS: '||STATUS||' TIPO: '||WALLET_TYPE AS w FROM V\$ENCRYPTION_WALLET;
EXIT;
SQLEOF
log "✓ Wallet abierto."

# Ejecutar RMAN
log "--- Ejecutando backup RMAN ---"
"${RMAN}" target / cmdfile="${RMAN_SCRIPT}" log="${LOG_FILE}" append
RMAN_EXIT=$?

DURACION=$(( $(date +%s) - INICIO_EPOCH ))
log "================================================================"
if [ $RMAN_EXIT -eq 0 ]; then
    log "  RESULTADO: BACKUP EXITOSO | Duración: ${DURACION}s"
    registrar_historial "EXITOSO" "${DURACION}"
    exit 0
else
    log "  RESULTADO: BACKUP FALLIDO | Código: ${RMAN_EXIT} | Duración: ${DURACION}s"
    send_alert "BACKUP FALLIDO: RMAN código ${RMAN_EXIT} después de ${DURACION}s"
    registrar_historial "FALLIDO - RMAN código ${RMAN_EXIT}" "${DURACION}"
    exit $RMAN_EXIT
fi
