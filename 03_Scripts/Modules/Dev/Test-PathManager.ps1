# ============================================================
# Modul: Test-PathManager.ps1
# Version: DEV_V1.1.0
# Zweck:   Testet alle Funktionen und Rückgaben der Lib_PathManager.ps1
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Test-PathManager
#   Description: Testmodul zur Überprüfung aller Endpunkte der Lib_PathManager.ps1 mit Ausgabe der Rückgabewerte
#   Category: Dev
#   Tags: Path, Test, Framework, Structure, Output
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
    param([string]$Test, [bool]$Success, [string]$Output = "")
    if ($Success) {
        Write-Host ("✅ " + $Test) -ForegroundColor Green
    } else {
        Write-Host ("❌ " + $Test) -ForegroundColor Red
    }
    if ($Output -ne "") {
        Write-Host ("   ↳ " + $Output) -ForegroundColor DarkGray
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
        # 1️⃣ Get-ProjectRoot
        $root = Get-ProjectRoot
        $okRoot = -not [string]::IsNullOrWhiteSpace($root)
        Show-Result "Get-ProjectRoot()" $okRoot $root

        # 2️⃣ Get-PathMap
        try { $paths = Get-PathMap } catch {}
        $okMap = ($paths -ne $null -and $paths.Root -ne $null)
        Show-Result "Get-PathMap()" $okMap
        if ($okMap) {
            foreach ($prop in $paths.PSObject.Properties) {
                Write-Host ("   " + $prop.Name.PadRight(12) + ": " + $prop.Value) -ForegroundColor Gray
            }
        }

        # 3️⃣ Einzelpfade
        $configPath    = Get-PathConfig
        $logsPath      = Get-PathLogs
        $backupPath    = Get-PathBackup
        $templatesPath = Get-PathTemplates

        Show-Result "Get-PathConfig()"    (Test-Path $configPath)    $configPath
        Show-Result "Get-PathLogs()"      (Test-Path $logsPath)      $logsPath
        Show-Result "Get-PathBackup()"    (Test-Path $backupPath)    $backupPath
        Show-Result "Get-PathTemplates()" (Test-Path $templatesPath) $templatesPath

        # 4️⃣ Systemfunktionen
        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "🧠 SYSTEMERKENNUNG:" -ForegroundColor Yellow
        Write-Host "──────────────────────────────────────────────" -ForegroundColor DarkGray

        $regResult = Register-System
        $okReg = $regResult -ne $null
        Show-Result "Register-System()" $okReg
        if ($okReg) {
            Write-Host "   ↳ Config aktualisiert: PathManager_Config.json" -ForegroundColor DarkGray
        }

        $activeSystem = Get-ActiveSystem
        $okActive = $activeSystem -ne $null
        Show-Result "Get-ActiveSystem()" $okActive
        if ($okActive) {
            foreach ($prop in $activeSystem.PSObject.Properties) {
                Write-Host ("   " + $prop.Name.PadRight(15) + ": " + $prop.Value) -ForegroundColor Gray
            }
        }

        # 5️⃣ Zusammenfassung
        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "📊 PFAD- UND SYSTEMÜBERSICHT:" -ForegroundColor Yellow
        Write-Host "──────────────────────────────────────────────" -ForegroundColor DarkGray

        foreach ($prop in $paths.PSObject.Properties) {
            $name  = $prop.Name.PadRight(12)
            $value = $prop.Value
            Write-Host "$name : $value" -ForegroundColor Gray
        }

        Write-Host "──────────────────────────────────────────────" -ForegroundColor DarkGray
        foreach ($prop in $activeSystem.PSObject.Properties) {
            $name  = $prop.Name.PadRight(15)
            $value = $prop.Value
            Write-Host "$name : $value" -ForegroundColor Gray
        }

        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host "`n✅ Test abgeschlossen." -ForegroundColor Green

    } catch {
        Write-Host "❌ Unerwarteter Fehler: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# ▶️ Test starten
# ------------------------------------------------------------
Test-PathManager
