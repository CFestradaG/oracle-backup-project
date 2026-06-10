# =============================================================================
# build-and-push.ps1
# Construye la imagen Docker, la prueba y la sube a Docker Hub
# =============================================================================
# EJECUCION: Abrir PowerShell en la carpeta del proyecto y ejecutar:
#   .\build-and-push.ps1
# =============================================================================

$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$IMAGE_NAME = "cestrda/oracle-backup-xe"
$IMAGE_TAG = "latest"
$FULL_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  BUILD - Sistema de Backups Oracle XE" -ForegroundColor Cyan
Write-Host "  Imagen: $FULL_IMAGE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Set-Location $PROJECT_DIR

# PASO 1: Construir la imagen
Write-Host ""
Write-Host "[1/4] Construyendo imagen Docker..." -ForegroundColor Yellow
Write-Host "      Esto tarda ~5-10 minutos (descarga Oracle XE ~2GB)"
docker build -t $FULL_IMAGE .
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR en docker build" -ForegroundColor Red; exit 1 }
Write-Host "✓ Imagen construida exitosamente." -ForegroundColor Green

# PASO 2: Verificar que la imagen existe
Write-Host ""
Write-Host "[2/4] Verificando imagen..." -ForegroundColor Yellow
docker images $IMAGE_NAME
Write-Host "✓ Imagen verificada." -ForegroundColor Green

# PASO 3: Login y push a Docker Hub
Write-Host ""
Write-Host "[3/4] Iniciando sesion en Docker Hub..." -ForegroundColor Yellow
Write-Host "      Ingresa tus credenciales de Docker Hub cuando se soliciten."
docker login
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR en docker login" -ForegroundColor Red; exit 1 }

Write-Host "      Subiendo imagen a Docker Hub..."
docker push $FULL_IMAGE
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR en docker push" -ForegroundColor Red; exit 1 }
Write-Host "✓ Imagen publicada en Docker Hub." -ForegroundColor Green

# PASO 4: Verificar en Docker Hub
Write-Host ""
Write-Host "[4/4] COMPLETADO" -ForegroundColor Green
Write-Host ""
Write-Host "  Imagen disponible en: https://hub.docker.com/r/cestrda/oracle-backup-xe" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Para levantar el contenedor:" -ForegroundColor White
Write-Host "    docker compose up -d" -ForegroundColor Gray
Write-Host ""
Write-Host "  Para ver los logs de inicializacion:" -ForegroundColor White
Write-Host "    docker logs -f oracle-backup" -ForegroundColor Gray
