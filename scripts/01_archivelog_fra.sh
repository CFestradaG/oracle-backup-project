#!/bin/bash
# =============================================================================
# Script: 01_archivelog_fra.sh
# Descripción: Habilita el modo ARCHIVELOG y configura la Flash Recovery Area
#
# ARCHIVELOG: Modo que preserva todos los redo logs archivados, necesario para:
#   - Backups en línea (sin detener la base de datos)
#   - Recuperación point-in-time (PITR)
#   - Recuperación ante desastres
#
# FRA (Flash Recovery Area): Área de disco gestionada automáticamente por Oracle
#   que almacena: archive logs, backupsets, controlfile autobackups
#
# Ejecutado automáticamente en la PRIMERA inicialización del contenedor.
# =============================================================================

echo ""
echo "============================================================"
echo "  [01] Configurando ARCHIVELOG y Flash Recovery Area (FRA)"
echo "============================================================"

# Verificar que las variables de entorno de Oracle estén disponibles
export ORACLE_SID=${ORACLE_SID:-XE}
export ORACLE_HOME=${ORACLE_HOME:-/opt/oracle/product/21c/dbhomeXE}
export PATH=${ORACLE_HOME}/bin:${PATH}

sqlplus -s / as sysdba << 'SQLEOF'
-- ============================================================
-- PASO 1: Configurar Flash Recovery Area (FRA)
-- Tamaño: 2GB - suficiente para backups de desarrollo/demo
-- Ubicación: /opt/oracle/fra (directorio creado en el Dockerfile)
-- ============================================================
ALTER SYSTEM SET db_recovery_file_dest_size = 2G SCOPE=BOTH;
ALTER SYSTEM SET db_recovery_file_dest = '/opt/oracle/fra' SCOPE=BOTH;

-- ============================================================
-- PASO 2: Habilitar modo ARCHIVELOG
-- Requiere que la base de datos pase por estado MOUNT
-- Secuencia: SHUTDOWN -> MOUNT -> ARCHIVELOG -> OPEN
-- ============================================================
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- Forzar el primer archive log para verificar que funciona
ALTER SYSTEM SWITCH LOGFILE;

-- ============================================================
-- PASO 3: Verificación - estos resultados deben mostrarse en los logs
-- ============================================================
PROMPT ============================================================
PROMPT VERIFICACION: Estado de ARCHIVELOG
PROMPT ============================================================
SELECT NAME, LOG_MODE FROM V$DATABASE;

PROMPT ============================================================
PROMPT VERIFICACION: Configuracion de FRA
PROMPT ============================================================
SHOW PARAMETER db_recovery_file_dest;

PROMPT ============================================================
PROMPT VERIFICACION: Archive log list
PROMPT ============================================================
ARCHIVE LOG LIST;

EXIT;
SQLEOF

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "[01] ✓ ARCHIVELOG y FRA configurados exitosamente."
else
    echo "[01] ✗ ERROR configurando ARCHIVELOG/FRA (código: $EXIT_CODE)"
    exit $EXIT_CODE
fi
