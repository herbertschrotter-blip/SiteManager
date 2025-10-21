# ============================================================
# Modul: Test-PathManager.ps1
# Version: DEV_V1.0.1
# Zweck:   Testet alle Funktionen der Lib_PathManager.ps1
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Test-PathManager
#   Description: Testmodul zur Überprüfung der Pfadfunktionen (Lib_PathManager.ps1)
#   Category: Dev
#   Tags: Path, Test, Framework, Structure
#   Dependencies: Lib_PathManager.ps1
# ============================================================

# ------------------------------------------------------------
# 🔧 Library laden
# ------------------------------------------------------------
$libPath = "$PSScriptRoot\..\..\Libs\Lib_PathManager.ps1"

if (-not (Test-Path $libPath)) {
    Write-Host "❌ Lib_PathManager.ps1 nicht gefunden unter: $libPath" -ForegroundColor Red
    exit
}
. $libPath

# ------------------------------------------------------------
# 🧩 Hilfsfunktion: Show-Result
# ------------------------------------------------------------
function Show-Result {
    param([string]$Test, [bool]$Success)
    if ($Success) {
        Write-Host ("✅ " + $Test) -ForegroundColor Green
    } else {
        Write-Host ("❌ " + $Test) -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# 🧪 Haupttestfunktion
# ------------------------------------------------------------
function Test-PathManager {

    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "🧭 STARTE FUNKTIONSTEST DER LIB_PATHMANAGER.PS1" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan

    try {
        # 1️⃣ Projektroot ermitteln
        $root = Get-ProjectRoot
        $okRoot = -not [string]::IsNullOrWhiteSpace($root)
        Show-Result "Projekt-Root erkannt" $okRoot
        if ($okRoot) { Write-Host "📁 Root: $root" -ForegroundColor Gray }

        # 2️⃣ Pfadobjekt abrufen
        $paths = $null
        try { $paths = Get-PathMap } catch {}
        $okMap = ($paths -ne $null -and $paths.Root -ne $null)
        Show-Result "Pfadobjekt erstellt" $okMap

        # 3️⃣ Einzelpfade prüfen
        $okConfig    = Test-Path (Get-PathConfig)
        $okLogs      = Test-Path (Get-PathLogs)
        $okBackup    = Test-Path (Get-PathBackup)
        $okTemplates = Test-Path (Get-PathTemplates)

        Show-Result "Config-Ordner vorhanden" $okConfig
        Show-Result "Logs-Ordner vorhanden" $okLogs
        Show-Result "Backup-Ordner vorhanden" $okBackup
        Show-Result "Templates-Ordner vorhanden" $okTemplates

        # 4️⃣ Strukturvollständigkeit prüfen
        $missing = @()
        foreach ($key in $paths.PSObject.Properties.Name) {
            $path = $paths.$key
            if (-not (Test-Path $path)) { $missing += $key }
        }
        if ($missing.Count -eq 0) {
            Show-Result "Alle Hauptordner vorhanden" $true
        } else {
            Show-Result "Fehlende Ordner erkannt" $false
            Write-Host "⚠️ Fehlende: $($missing -join ', ')" -ForegroundColor Yellow
        }

        # 5️⃣ Vertikale Pfadübersicht
        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "📊 PFADÜBERSICHT:" -ForegroundColor Yellow
        Write-Host "──────────────────────────────────────────────" -ForegroundColor DarkGray

        foreach ($prop in $paths.PSObject.Properties) {
            $name  = $prop.Name.PadRight(12)
            $value = $prop.Value
            Write-Host "$name : $value" -ForegroundColor Gray
        }

        Write-Host "============================================" -ForegroundColor Cyan

    } catch {
        Write-Host "❌ Unerwarteter Fehler: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n✅ Test abgeschlossen." -ForegroundColor Green
}

# ------------------------------------------------------------
# ▶️ Test starten
# ------------------------------------------------------------
Test-PathManager
