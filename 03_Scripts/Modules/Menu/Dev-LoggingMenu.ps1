# ============================================================
# 🧩 DEV-MODUL – Logging-Testmenü
# Version: MENU_V1.1.0
# Zweck:   Steuert die Testfunktionen aus Dev-LogSystem.ps1
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================

# ManifestHint:
#   ExportFunctions: (none)
#   Description: Menümodul für das Dev-LogSystem – ruft Testfunktionen direkt über Lib_Menu auf.
#   Category: Menu
#   Tags: Logging, DevTools, Menu
#   Dependencies: Lib_Menu, Lib_Log

# ------------------------------------------------------------
# 🔗 Libraries & Tool laden
# ------------------------------------------------------------
try {
    $libMenu = Join-Path $PSScriptRoot "..\..\Libs\Lib_Menu.ps1"
    if (Test-Path $libMenu) { . $libMenu } else { throw "Lib_Menu.ps1 nicht gefunden." }

    $libLog = Join-Path $PSScriptRoot "..\..\Libs\Lib_Log.ps1"
    if (Test-Path $libLog) { . $libLog } else { throw "Lib_Log.ps1 nicht gefunden." }

    $devLogSystem = Join-Path $PSScriptRoot "..\Dev\Dev-LogSystem.ps1"
    if (Test-Path $devLogSystem) { . $devLogSystem } else { throw "Dev-LogSystem.ps1 nicht gefunden." }

    Write-Host "✅ Dev-LoggingMenu geladen (Lib_Menu-Steuerung aktiv)." -ForegroundColor Green
}
catch {
    Write-Host "❌ Fehler beim Laden: $_" -ForegroundColor Red
    exit
}

# ------------------------------------------------------------
# 🧭 Menüdefinition
# ------------------------------------------------------------
$logMenu = @{
    "1" = "Config laden|Test-LoadConfig"
    "2" = "Session starten|Test-InitSession"
    "3" = "Testeinträge schreiben|Test-WriteLogs"
    "4" = "Rotation testen|Test-Rotate"
    "5" = "Session schließen|Test-CloseSession"
}

Show-SubMenu -MenuTitle "🧩 Logging-Test-Menü" -Options $logMenu
