# =============================================================================
# github-setup.ps1
# Inicializa el repositorio git y hace push a GitHub
# =============================================================================
# PRE-REQUISITO: Crear un repo vacío en GitHub con nombre "oracle-backup-xe"
#   URL: https://github.com/new
#   - Repository name: oracle-backup-xe
#   - Visibility: Public (para compartir con compañeros)
#   - NO inicializar con README (ya tenemos uno)
#
# EJECUCION: Abrir PowerShell en la carpeta del proyecto y ejecutar:
#   .\github-setup.ps1
# =============================================================================

$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$GITHUB_USER = "cestrda"
$REPO_NAME = "oracle-backup-xe"
$REMOTE_URL = "https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  GITHUB SETUP - oracle-backup-xe" -ForegroundColor Cyan
Write-Host "  Repo: $REMOTE_URL" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Set-Location $PROJECT_DIR

# Inicializar git
Write-Host ""
Write-Host "[1/5] Inicializando repositorio git..." -ForegroundColor Yellow
git init
git add .
git commit -m "feat: Sistema Integral de Backups Oracle XE

- ARCHIVELOG + Flash Recovery Area (2GB)
- TDE Software Keystore (Wallet) con cifrado AES128
- RMAN: retencion 7 dias, compresion MEDIUM, backup CDB+PDB
- Script de automatizacion Bash con logs y alertas
- Cron diario 02:00 AM
- Docker compose con volumenes persistentes

Proyecto Final Base de Datos II - UMG"

Write-Host "✓ Commit inicial creado." -ForegroundColor Green

# Agregar remote
Write-Host ""
Write-Host "[2/5] Configurando remote origin..." -ForegroundColor Yellow
git remote add origin $REMOTE_URL
Write-Host "      Remote: $REMOTE_URL" -ForegroundColor Gray
Write-Host "✓ Remote configurado." -ForegroundColor Green

# Branch principal
Write-Host ""
Write-Host "[3/5] Configurando branch main..." -ForegroundColor Yellow
git branch -M main
Write-Host "✓ Branch renombrado a main." -ForegroundColor Green

# Push
Write-Host ""
Write-Host "[4/5] Haciendo push a GitHub..." -ForegroundColor Yellow
Write-Host "      Ingresa tus credenciales de GitHub cuando se soliciten."
git push -u origin main
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR en git push" -ForegroundColor Red; exit 1 }
Write-Host "✓ Codigo publicado en GitHub." -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  COMPLETADO" -ForegroundColor Green
Write-Host "  Repositorio: $REMOTE_URL" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Green
