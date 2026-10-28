<#
.SYNOPSIS
  Despliegue simulado del proyecto en una carpeta externa (Sesión 3, Actividad 2).

.EXAMPLE
  # Modo 1: descargar el proyecto desde GitHub y construirlo con Docker Compose
  .\scripts\deploy-simulado.ps1 -RepoUrl https://github.com/<usuario>/pipeline-django.git

.EXAMPLE
  # Modo 2: usar la imagen generada por GitHub Actions (artefacto descargado y descomprimido)
  .\scripts\deploy-simulado.ps1 -Artefacto C:\Users\<usuario>\Downloads\pipeline-django-image
#>
param(
    [string]$RepoUrl,
    [string]$Rama = "main",
    [string]$Artefacto,
    [string]$Destino = "C:\deploy-simulado"
)

$ErrorActionPreference = "Stop"

if (-not $RepoUrl -and -not $Artefacto) {
    throw "Indica -RepoUrl (clonar y construir) o -Artefacto (imagen del pipeline)."
}

if (Test-Path $Destino) {
    Write-Host "Limpiando despliegue anterior en $Destino"
    Push-Location $Destino
    try { docker compose down -v 2>$null } catch {}
    try { docker compose -f docker-compose.deploy.yml down -v 2>$null } catch {}
    Pop-Location
    Remove-Item -Recurse -Force $Destino
}
New-Item -ItemType Directory -Force $Destino | Out-Null

if ($Artefacto) {
    Write-Host "1. Copiando artefacto del pipeline a $Destino"
    Copy-Item "$Artefacto\*" $Destino -Recurse
    Set-Location $Destino
    Write-Host "2. Cargando imagen Docker"
    # docker load acepta .tar.gz directamente
    docker load -i (Join-Path $Destino "pipeline-django-image.tar.gz")
    Write-Host "3. Levantando servicios con Docker Compose"
    $compose = @("-f", "docker-compose.deploy.yml")
    docker compose @compose up -d
} else {
    Write-Host "1. Descargando proyecto desde $RepoUrl (rama $Rama)"
    git clone --branch $Rama --depth 1 $RepoUrl $Destino
    Set-Location $Destino
    Write-Host "2-3. Construyendo y levantando servicios con Docker Compose"
    $compose = @()
    docker compose up -d --build
}

Write-Host "4. Validando /health/ ..."
$ok = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        $r = Invoke-RestMethod http://localhost:8000/health/ -TimeoutSec 3
        if ($r.status -eq "ok") { $ok = $true; break }
    } catch {}
    Start-Sleep -Seconds 2
}

docker compose @compose ps
if (-not $ok) { throw "La aplicación no respondió en http://localhost:8000/health/" }

Write-Host "Despliegue OK: $($r | ConvertTo-Json -Compress)"
Write-Host "Abriendo http://localhost:8000 en el navegador..."
Start-Process "http://localhost:8000"
