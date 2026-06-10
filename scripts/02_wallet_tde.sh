#!/bin/bash
# =============================================================================
# Script: 02_wallet_tde.sh
# Descripción: Configura el TDE Software Keystore (Wallet) y cifrado AES128
# =============================================================================

echo ""
echo "============================================================"
echo "  [02] Configurando TDE Software Keystore (Wallet) AES128"
echo "============================================================"

# Oracle XE 21c usa WALLET_ROOT=/opt/oracle/admin/XE por defecto
# El wallet TDE vive en $WALLET_ROOT/wallet/
WALLET_DIR=/opt/oracle/admin/XE/wallet
WALLET_PASSWORD="WalletPass123#"

# Crear el directorio si no existe (Oracle a veces no lo crea)
mkdir -p "${WALLET_DIR}"
chmod 700 "${WALLET_DIR}"

echo "[02] Directorio del wallet: ${WALLET_DIR}"

sqlplus -s / as sysdba << SQLEOF
-- ============================================================
-- Crear el Software Keystore en la ubicación por defecto de Oracle XE
-- ============================================================
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE '${WALLET_DIR}'
    IDENTIFIED BY "${WALLET_PASSWORD}";

-- ============================================================
-- Abrir el Wallet en CDB + PDB (XEPDB1)
-- ============================================================
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
    IDENTIFIED BY "${WALLET_PASSWORD}"
    CONTAINER=ALL;

-- ============================================================
-- Crear la Master Encryption Key en CDB$ROOT con backup
-- ============================================================
ADMINISTER KEY MANAGEMENT SET KEY
    IDENTIFIED BY "${WALLET_PASSWORD}"
    WITH BACKUP
    CONTAINER=ALL;

-- ============================================================
-- Configurar clave maestra explícita en PDB XEPDB1
-- Requerido para que RMAN pueda cifrar backups de la PDB
-- Sin esto el backup falla con ORA-28361
-- ============================================================
ALTER SESSION SET CONTAINER=XEPDB1;
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
    IDENTIFIED BY "${WALLET_PASSWORD}";
ADMINISTER KEY MANAGEMENT SET KEY FORCE KEYSTORE
    IDENTIFIED BY "${WALLET_PASSWORD}"
    WITH BACKUP;
ALTER SESSION SET CONTAINER=CDB\$ROOT;

-- ============================================================
-- Crear wallet de Auto-Login (cwallet.sso)
-- Permite que Oracle abra la wallet automáticamente al arrancar
-- ============================================================
ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE
    FROM KEYSTORE '${WALLET_DIR}'
    IDENTIFIED BY "${WALLET_PASSWORD}";

-- ============================================================
-- VERIFICACION
-- ============================================================
PROMPT ============================================================
PROMPT VERIFICACION: Estado del TDE Wallet
PROMPT ============================================================
SELECT CON_ID, WRL_PARAMETER, STATUS, WALLET_TYPE
FROM   V\$ENCRYPTION_WALLET
ORDER BY CON_ID;

EXIT;
SQLEOF

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "[02] ✓ TDE Wallet configurado en: ${WALLET_DIR}"
    ls -la "${WALLET_DIR}/"
else
    echo "[02] ✗ ERROR configurando TDE Wallet (código: $EXIT_CODE)"
    exit $EXIT_CODE
fi
