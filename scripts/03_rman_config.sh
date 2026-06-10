#!/bin/bash
# =============================================================================
# Script: 03_rman_config.sh
# Descripción: Configura los parámetros persistentes de RMAN
# =============================================================================

echo ""
echo "============================================================"
echo "  [03] Configurando parámetros persistentes de RMAN"
echo "============================================================"

# Ruta directa al binario rman en Oracle XE 21c
RMAN=/opt/oracle/product/21c/dbhomeXE/bin/rman

echo "[03] RMAN path: ${RMAN}"

if [ ! -e "${RMAN}" ]; then
    echo "[03] ✗ ERROR: rman no encontrado en ${RMAN}"
    exit 1
fi

"${RMAN}" target / << 'RMANEOF'
# Politica de retencion: 7 dias
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
# Compresion MEDIUM
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE;
# Cifrado AES128 para todos los backups (usa el TDE Wallet)
CONFIGURE ENCRYPTION FOR DATABASE ON;
CONFIGURE ENCRYPTION ALGORITHM 'AES128';
# Autobackup del controlfile
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/opt/oracle/fra/ctrl_%F.bkp';
# Optimizacion de backup
CONFIGURE BACKUP OPTIMIZATION ON;
# Verificacion final
SHOW ALL;
EXIT;
RMANEOF

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "[03] ✓ Configuración RMAN aplicada exitosamente."
else
    echo "[03] ✗ ERROR configurando RMAN (código: $EXIT_CODE)"
    exit $EXIT_CODE
fi
