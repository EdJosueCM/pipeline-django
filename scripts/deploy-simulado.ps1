param(
    [string]$RepoUrl,
    [string]$Rama = "main",
    [string]$Artefacto,
    [string]$Destino = "C:\deploy-simulado"
)

$ErrorActionPreference = "Stop"

function Ejecutar([string]$Exe, [string[]]$Argumentos) {
    $ErrorActionPreference = "Continue"
    & $Exe @Argumentos 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "Error: $Exe $($Argumentos -join ' ')" }
}

if (-not $RepoUrl -and -not $Artefacto) {
    throw "Indica -RepoUrl o -Artefacto."
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
    Write-Host "1. Copiando artefacto a $Destino"
    Copy-Item "$Artefacto\*" $Destino -Recurse
    Set-Location $Destino
    Write-Host "2. Cargando imagen Docker"
    Ejecutar docker @("load", "-i", (Join-Path $Destino "pipeline-django-image.tar.gz"))
    Write-Host "3. Levantando servicios"
    $compose = @("-f", "docker-compose.deploy.yml")
    Ejecutar docker (@("compose") + $compose + @("up", "-d"))
} else {
    Write-Host "1. Descargando proyecto desde $RepoUrl ($Rama)"
    Ejecutar git @("clone", "--branch", $Rama, "--depth", "1", $RepoUrl, $Destino)
    Set-Location $Destino
    Write-Host "2. Construyendo y levantando servicios"
    $compose = @()
    Ejecutar docker @("compose", "up", "-d", "--build")
}

Write-Host "4. Validando /health/"
$ok = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        $r = Invoke-RestMethod http://localhost:8000/health/ -TimeoutSec 3
        if ($r.status -eq "ok") { $ok = $true; break }
    } catch {}
    Start-Sleep -Seconds 2
}

docker compose @compose ps
if (-not $ok) { throw "La aplicacion no respondio en http://localhost:8000/health/" }

Write-Host "Despliegue OK: $($r | ConvertTo-Json -Compress)"
Start-Process "http://localhost:8000"
