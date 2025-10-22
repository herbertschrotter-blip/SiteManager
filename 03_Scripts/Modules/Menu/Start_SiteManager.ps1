# ============================================================
# 🧭 SITE MANAGER – HAUPTMODUL
# Version: SM_V0.1.0
# Zweck:   Einfaches Hauptmenü mit Tools, Einstellungen, DevTools
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================

# ------------------------------------------------------------
# 🧩 ManifestHint:
#   ExportFunctions: (none)
#   Description: Hauptmenü des Site Managers (rudimentäre Version)
#   Category: Core
#   Tags: Menu, Framework, Start
#   Dependencies: Lib_Menu.ps1, Lib_PathManager.ps1
# ============================================================

# ------------------------------------------------------------
# 🔧 Libraries laden
# ------------------------------------------------------------
try {
    # 🔧 Korrektur: Menü liegt in Modules/Menu → Libs liegen 2 Ebenen höher
    $libsPath = (Resolve-Path (Join-Path $PSScriptRoot "..\..\Libs")).Path

    . (Join-Path $libsPath "Lib_PathManager.ps1")
    . (Join-Path $libsPath "Lib_Menu.ps1")

    Write-Host "✅ Libraries geladen (PathManager + Menu)" -ForegroundColor DarkGray
}

catch {
    Write-Host "❌ Fehler beim Laden der Libraries: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# ------------------------------------------------------------
# 📋 Menüdefinition
# ------------------------------------------------------------
$mainMenu = @{
    "1" = "Tools"
    "2" = "Einstellungen"
    "3" = "Dev-Tools"
    "X" = "Beenden"
}

# ------------------------------------------------------------
# 🧭 Menü starten
# ------------------------------------------------------------
try {
    Write-Host ""
    Write-Host "🧩 Willkommen im Site Manager Framework" -ForegroundColor Cyan
    Write-Host "-------------------------------------"
    $selection = Show-SubMenu -MenuTitle "Hauptmenü" -Options $mainMenu


    switch ($selection) {
        "1" { Write-Host "🔧 Tools geöffnet (noch nicht implementiert)" -ForegroundColor Yellow }
        "2" { Write-Host "⚙️  Einstellungen geöffnet (noch nicht implementiert)" -ForegroundColor Yellow }
        "3" { Write-Host "🧰 Dev-Tools geöffnet (noch nicht implementiert)" -ForegroundColor Yellow }
        default { Write-Host "👋 Programm beendet." -ForegroundColor DarkGray }
    }
}
catch {
    Write-Host "❌ Fehler im Hauptmenü: $($_.Exception.Message)" -ForegroundColor Red
}
