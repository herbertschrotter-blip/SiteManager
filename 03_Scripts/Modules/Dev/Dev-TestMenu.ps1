# ============================================================
# Modul: Dev-TestMenu.ps1
# Version: MOD_V1.1.1
# Zweck:   Testet alle Hauptfunktionen der Library Lib_Menu.ps1 inkl. Pfad- und Systeminformationen
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Test-MenuSystem
#   Description: Entwicklertest für Lib_Menu.ps1 mit Integration von Lib_PathManager (Pfad- & Systemdiagnose)
#   Category: Dev
#   Tags: Menu, PathManager, Test, Framework, Diagnostic
#   Dependencies: Lib_Menu.ps1, Lib_PathManager.ps1
# ============================================================

# ------------------------------------------------------------
# 🔧 Library Lib_Menu.ps1 laden (inkl. PathManager)
# ------------------------------------------------------------
try {
    $libPath = "$PSScriptRoot\..\..\Libs\Lib_Menu.ps1"
    if (Test-Path $libPath) {
        . $libPath
        Write-Host "✅ Lib_Menu.ps1 erfolgreich geladen." -ForegroundColor Green
    }
    else {
        throw "❌ Library nicht gefunden unter: $libPath"
    }
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}

# ------------------------------------------------------------
# 🧭 System- & Pfadinfos ausgeben (von PathManager)
# ------------------------------------------------------------
try {
    $pathMap = Get-PathMap
    $activeSystem = Get-ActiveSystem

    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "🔍 LIB-STATUS & SYSTEMINFORMATION" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Cyan

    Write-Host "📦 Lib_Menu-Version     : LIB_V1.5.2" -ForegroundColor White
    Write-Host "📦 Lib_PathManager-Ver. : LIB_V1.2.3" -ForegroundColor White
    Write-Host ("👤 Benutzer             : " + $activeSystem.Benutzer) -ForegroundColor Gray
    Write-Host ("💻 Computer             : " + $activeSystem.Computer) -ForegroundColor Gray
    Write-Host ("📁 Root-Path            : " + $activeSystem.Root) -ForegroundColor Gray
    Write-Host "`n📂 AKTIVE PFADZUORDNUNG:" -ForegroundColor Yellow
    foreach ($prop in $pathMap.PSObject.Properties) {
        Write-Host ("   " + $prop.Name.PadRight(12) + ": " + $prop.Value) -ForegroundColor DarkGray
    }
    Write-Host "============================================" -ForegroundColor Cyan

    Write-Host "`n⏸️  Weiter mit [ENTER], um die Menütests zu starten ..." -ForegroundColor Magenta
    Read-Host | Out-Null
}
catch {
    Write-Host "⚠️ Konnte Pfad-/Systeminfos nicht abrufen: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ------------------------------------------------------------
# 🧪 Test 1: Einfaches Menü mit zwei Optionen
# ------------------------------------------------------------
$options1 = @{
    "1" = "Aktion 1 ausführen|Write-Host 'Testaktion 1 wurde ausgeführt.' -ForegroundColor Cyan"
    "2" = "Aktion 2 ausführen|Write-Host 'Testaktion 2 wurde ausgeführt.' -ForegroundColor Cyan"
}
Show-SubMenu -MenuTitle "Test 1 – Einfaches Menü" -Options $options1 -ReturnAfterAction

# ------------------------------------------------------------
# 🧪 Test 2: Menü mit Untermenü (verschachtelt, auto-erkennung)
# ------------------------------------------------------------
$optionsSub = @{
    "1" = "Untermenü-Option 1|Write-Host 'Untermenü Aktion 1' -ForegroundColor Yellow"
    "2" = "Untermenü-Option 2|Write-Host 'Untermenü Aktion 2' -ForegroundColor Yellow"
    "3" = "Zurück zum Hauptmenü|return '0'"
}

$options2 = @{
    "1" = "Untermenü öffnen|Show-SubMenu -MenuTitle 'Untermenü – Test 2' -Options `$optionsSub"
    "2" = "Hauptaktion|Write-Host 'Hauptaktion wurde ausgeführt.' -ForegroundColor Magenta"
    "3" = "Weitere Aktion|Write-Host 'Dritte Testaktion im Hauptmenü' -ForegroundColor Cyan"
}
Show-SubMenu -MenuTitle "Test 2 – Menü mit Untermenü" -Options $options2

# ------------------------------------------------------------
# 🧪 Test 3: DebugMode-Erkennung & Fehlerbehandlung
# ------------------------------------------------------------
$options3 = @{
    "1" = "Fehler provozieren|throw 'Beispielhafter Testfehler'"
    "2" = "Normale Aktion|Write-Host 'Aktion erfolgreich ausgeführt.' -ForegroundColor Green"
}
Show-SubMenu -MenuTitle "Test 3 – DebugMode & Fehler" -Options $options3

# ------------------------------------------------------------
# 🏁 Testabschluss
# ------------------------------------------------------------
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "✅ Alle Menütests abgeschlossen." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Pause
