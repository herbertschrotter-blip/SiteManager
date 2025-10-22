# ============================================================
# 🧩 DEV-MODUL – LogSystem-Testfunktionen
# Version: DEV_V1.1.0
# Zweck:   Testfunktionen für Lib_Log.ps1 – steuerbar über Lib_Menu.ps1
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================

# ManifestHint:
#   ExportFunctions: Test-LoadConfig, Test-InitSession, Test-WriteLogs, Test-Rotate, Test-CloseSession
#   Description: Entwicklungsmodul zur Prüfung der Logging-Library, vollständig steuerbar über Lib_Menu.
#   Category: DevTools
#   Tags: Logging, Menu, Test
#   Dependencies: Lib_Log

# ------------------------------------------------------------
# 🔗 Library laden
# ------------------------------------------------------------
try {
    $libLog = Join-Path $PSScriptRoot "..\..\Libs\Lib_Log.ps1"
    if (Test-Path $libLog) { . $libLog } else { throw "Lib_Log.ps1 nicht gefunden." }
    Write-Host "✅ Lib_Log.ps1 geladen (LogSystem-Tests bereit)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Fehler beim Laden von Lib_Log.ps1: $_" -ForegroundColor Red
    exit
}

# ------------------------------------------------------------
# 🧪 Testfunktionen
# ------------------------------------------------------------
function Test-LoadConfig {
    Write-Host "`n📂 Lade Log_Config.json..." -ForegroundColor Yellow
    Load-LogConfig
}

function Test-InitSession {
    Write-Host "`n🧾 Starte neue Log-Session..." -ForegroundColor Yellow
    Initialize-LogSession -ModuleName "DevLogSystem"
}

function Test-WriteLogs {
    Write-Host "`n✍️ Schreibe Testeinträge..." -ForegroundColor Yellow
    Write-FrameworkLog -Module "DevLogSystem" -Level "INFO"  -Message "Info: Logging-System gestartet."
    Write-FrameworkLog -Module "DevLogSystem" -Level "WARN"  -Message "Warnung: Testwarnung simuliert."
    Write-FrameworkLog -Module "DevLogSystem" -Level "ERROR" -Message "Fehler: Beispiel-Fehler erzeugt."
    Write-DebugLog     -Module "DevLogSystem" -Message "Debug: Zusätzliche Entwicklerinfo."
}

function Test-Rotate {
    Write-Host "`n♻️ Führe Logrotation aus..." -ForegroundColor Yellow
    Rotate-Logs -ModuleName "DevLogSystem" -LogConfig $global:LogConfig
}

function Test-CloseSession {
    Write-Host "`n🏁 Schließe Log-Session..." -ForegroundColor Yellow
    Close-LogSession -ModuleName "DevLogSystem"
}
