# ============================================================
# 🧪 TESTTOOL – Manifest Generator
# Version: TEST_V1.3.0
# Zweck:   Testet PathManager-Integration und gibt erkannte Pfade aus
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================

# ------------------------------------------------------------
# 🔧 Pfadmanager laden
# ------------------------------------------------------------
try {
    $PathManager = Join-Path $PSScriptRoot "..\..\Libs\Lib_PathManager.ps1"
    if (!(Test-Path $PathManager)) {
        Write-Host "❌ PathManager nicht gefunden unter: $PathManager" -ForegroundColor Red
        exit
    }

    . $PathManager
    Write-Host "✅ Lib_PathManager erfolgreich geladen." -ForegroundColor Green
}
catch {
    Write-Host "❌ Fehler beim Laden des PathManagers: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# ------------------------------------------------------------
# 🧭 Pfade abrufen und anzeigen
# ------------------------------------------------------------
try {
    $paths = Get-PathMap
    if (-not $paths) {
        Write-Host "⚠️ Keine Pfade vom PathManager erhalten." -ForegroundColor Yellow
        exit
    }

    Write-Host "`n📦 ERKANNTE PFADSTRUKTUR (vom PathManager):" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────"
    $paths | Get-Member -MemberType NoteProperty | ForEach-Object {
        $key = $_.Name
        $value = $paths.$key
        Write-Host ("{0,-12}: {1}" -f $key, $value)
    }

    Write-Host "`n📂 Detailausgabe (PSCustomObject):" -ForegroundColor DarkGray
    $paths | Format-List

}
catch {
    Write-Host "❌ Fehler beim Abrufen der Pfade: $($_.Exception.Message)" -ForegroundColor Red
}

# ------------------------------------------------------------
# 🧠 Aktives System ausgeben
# ------------------------------------------------------------
try {
    $system = Get-ActiveSystem
    if ($system) {
        Write-Host "`n🧠 AKTIVES SYSTEM:" -ForegroundColor Cyan
        Write-Host "─────────────────────────────────────────────"
        Write-Host "Benutzer : $($system.Benutzer)"
        Write-Host "Computer : $($system.Computer)"
        Write-Host "Root     : $($system.Root)"
        Write-Host "LetzteErkennung: $($system.LetzteErkennung)"
    }
    else {
        Write-Host "`n⚠️ Kein aktives System gefunden (Fallback-Modus)." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Fehler beim Abrufen des aktiven Systems: $($_.Exception.Message)" -ForegroundColor Red
}

# ------------------------------------------------------------
# ✅ Abschlussmeldung
# ------------------------------------------------------------
Write-Host "`n✅ Testlauf abgeschlossen – keine Dateien wurden verändert oder erstellt." -ForegroundColor Green
