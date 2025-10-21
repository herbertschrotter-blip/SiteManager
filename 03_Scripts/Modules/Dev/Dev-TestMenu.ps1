# ============================================================
# Modul: Dev-TestMenu.ps1
# Version: MOD_V1.0.1
# Zweck:   Testet alle Hauptfunktionen der Library Lib_Menu.ps1
# Autor:   Herbert Schrotter
# Datum:   21.10.2025
# ============================================================

# ------------------------------------------------------------
# Voraussetzungen prüfen & Library laden
# ------------------------------------------------------------
try {
    $libPath = "$PSScriptRoot\..\..\Libs\Lib_Menu.ps1"
    if (Test-Path $libPath) {
        . $libPath
        Write-Host "Lib_Menu.ps1 erfolgreich geladen." -ForegroundColor Green
    }
    else {
        throw "Library nicht gefunden unter: $libPath"
    }
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}

# ------------------------------------------------------------
# Test 1: Einfaches Menü mit zwei Optionen
# ------------------------------------------------------------
$options1 = @{
    "1" = "Aktion 1 ausführen|Write-Host 'Testaktion 1 wurde ausgeführt.' -ForegroundColor Cyan"
    "2" = "Aktion 2 ausführen|Write-Host 'Testaktion 2 wurde ausgeführt.' -ForegroundColor Cyan"
}
Show-SubMenu -MenuTitle "Test 1 – Einfaches Menü" -Options $options1 -ReturnAfterAction

# ------------------------------------------------------------
# Test 2: Menü mit Untermenü (verschachtelt, auto-erkennung)
# ------------------------------------------------------------

# Untermenü-Definition
$optionsSub = @{
    "1" = "Untermenü-Option 1|Write-Host 'Untermenü Aktion 1' -ForegroundColor Yellow"
    "2" = "Untermenü-Option 2|Write-Host 'Untermenü Aktion 2' -ForegroundColor Yellow"
    "3" = "Zurück zum Hauptmenü|return '0'"
}

# Hauptmenü-Definition mit automatischem Aufruf
$options2 = @{
    "1" = "Untermenü öffnen|Show-SubMenu -MenuTitle 'Untermenü – Test 2' -Options `$optionsSub"
    "2" = "Hauptaktion|Write-Host 'Hauptaktion wurde ausgeführt.' -ForegroundColor Magenta"
    "3" = "Weitere Aktion|Write-Host 'Dritte Testaktion im Hauptmenü' -ForegroundColor Cyan"
}

# Menü starten
Show-SubMenu -MenuTitle "Test 2 – Menü mit Untermenü (LIB_V1.3.0)" -Options $options2

# ------------------------------------------------------------
# Test 3: DebugMode-Erkennung & Fehlerbehandlung
# ------------------------------------------------------------
$options3 = @{
    "1" = "Fehler provozieren|throw 'Beispielhafter Testfehler'"
    "2" = "Normale Aktion|Write-Host 'Aktion erfolgreich ausgeführt.' -ForegroundColor Green"
}
Show-SubMenu -MenuTitle "Test 3 – DebugMode & Fehler" -Options $options3

# ------------------------------------------------------------
# Testabschluss
# ------------------------------------------------------------
Write-Host "`nAlle Tests abgeschlossen." -ForegroundColor Green
Pause
