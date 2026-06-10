#!/bin/bash
# =============================================================================
# Script: 04_cron_setup.sh
# Descripción: Inicia el servicio cron y verifica la programación del backup
#
# El crontab fue configurado en el Dockerfile:
#   "0 2 * * *" = todos los días a las 02:00 AM
#
# Ejecutado automáticamente en la PRIMERA inicialización del contenedor.
# =============================================================================

echo ""
echo "============================================================"
echo "  [04] Iniciando servicio cron y verificando programación"
echo "============================================================"

# Iniciar el demonio cron en segundo plano
crond

# Pequeña espera para que crond arranque
sleep 2

# Verificar que crond está corriendo
if pgrep crond > /dev/null 2>&1; then
    echo "[04] ✓ Servicio cron iniciado correctamente (PID: $(pgrep crond))"
else
    echo "[04] ✗ ADVERTENCIA: crond no pudo iniciarse. El backup automático no funcionará."
    echo "[04]   Puede ejecutar el backup manualmente con:"
    echo "[04]   docker exec oracle-backup /opt/oracle/backup/scripts/run_backup.sh"
fi

# Mostrar la programación activa
echo ""
echo "--- Programación de backup automático ---"
cat /etc/cron.d/oracle-backup

echo ""
echo "[04] El backup se ejecutará automáticamente todos los días a las 02:00 AM."
echo "[04] Para ejecutarlo manualmente:"
echo "[04]   docker exec oracle-backup /opt/oracle/backup/scripts/run_backup.sh"
echo ""
echo "============================================================"
echo "  INICIALIZACION COMPLETADA"
echo "  Oracle XE listo con:"
echo "    ✓ Modo ARCHIVELOG habilitado"
echo "    ✓ FRA configurada en /opt/oracle/fra (2GB)"
echo "    ✓ TDE Wallet con cifrado AES128"
echo "    ✓ RMAN: retención 7 días, compresión MEDIUM"
echo "    ✓ Backup automático diario a las 02:00 AM"
echo "============================================================"
