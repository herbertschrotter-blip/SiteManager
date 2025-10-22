# ============================================================
# 🧪 TESTTOOL – Manifest Generator
# Version: TEST_V1.1.0
# Zweck:   Testet die Funktionen der Lib_ManifestGenerator.ps1
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================

# ------------------------------------------------------------
# 🔧 Einstellungen
# ------------------------------------------------------------
$RootPath     = Split-Path -Parent $PSScriptRoot
$LibPath      = Join-Path $RootPath "Libs\Lib_ManifestGenerator.ps1"
$LogPath      = Join-Path $RootPath "..\..\04_Logs\Manifest_ScanLog.txt"
$TestLibPath  = Join-Path $RootPath "Libs\Test_Lib_Dummy.psm1"
$InfoPath     = Join-Path $RootPath "..\..\00_Info\Module_Registry.json"
$CreatedFiles = @()   # Liste für Cleanup

# ------------------------------------------------------------
# 🧠 Logfunktion
# ------------------------------------------------------------
function Write-Log {
    param([string]$Message, [switch]$Error)

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = if ($Error) { "❌ [$timestamp] $Message" } else { "ℹ️ [$timestamp] $Message" }

    Write-Host $entry
    Add-Content -Path $LogPath -Value $entry
}

# ------------------------------------------------------------
# 🧩 Teststart
# ------------------------------------------------------------
Write-Host "`n🚀 Starte ManifestGenerator-Test..."
Write-Log "Starte Testlauf für ManifestGenerator"

# Prüfen, ob Library vorhanden
if (!(Test-Path $LibPath)) {
    Write-Log "Library nicht gefunden unter: $LibPath" -Error
    exit
}

# Library laden
. $LibPath
Write-Log "Library geladen: Lib_ManifestGenerator.ps1"

# ------------------------------------------------------------
# 🧱 Dummy-Modul erstellen
# ------------------------------------------------------------
$dummyHint = @"
# ============================================================
# 🧩 MANIFEST HINT
# ExportFunctions: Test-DummyFunction
# Description: Dummy Modul für Manifest-Test
# Category: Library
# Tags: Test, Manifest, Dummy
# Dependencies: Lib_Pathmanager
# ============================================================

function Test-DummyFunction {
    Write-Host 'Dummy function executed.'
}
"@

try {
    $dummyHint | Out-File -FilePath $TestLibPath -Encoding UTF8
    Write-Log "CREATED: $TestLibPath"
    $CreatedFiles += $TestLibPath
} catch {
    Write-Log "Fehler beim Schreiben des Testmoduls: $_" -Error
    exit
}

# ------------------------------------------------------------
# 🧾 Manifest-Scan ausführen
# ------------------------------------------------------------
try {
    Write-Host "`n📦 Starte ManifestScan..."
    Write-Log "Starte ManifestScan im Ordner: $(Split-Path $TestLibPath)"
    Invoke-ManifestScan -Path (Split-Path $TestLibPath)
    Write-Log "ManifestScan abgeschlossen."
} catch {
    Write-Log "Fehler beim ManifestScan: $_" -Error
}

# ------------------------------------------------------------
# 📁 Ergebnisse prüfen
# ------------------------------------------------------------
$TestManifest = [System.IO.Path]::ChangeExtension($TestLibPath, ".psd1")
if (Test-Path $TestManifest) {
    Write-Log "CREATED: $TestManifest"
    $CreatedFiles += $TestManifest
} else {
    Write-Log "❌ Manifest-Datei fehlt!" -Error
}

if (Test-Path $InfoPath) {
    Write-Log "✅ Registry-Datei gefunden: $InfoPath"
    $registry = Get-Content $InfoPath -Raw | ConvertFrom-Json
    Write-Host "`n🗂️ Inhalt der Registry:`n"
    $registry.GetEnumerator() | ForEach-Object {
        "{0,-25} | Version {1,-6} | {2}" -f $_.Key, $_.Value.Version, $_.Value.Description
    } | Write-Host
} else {
    Write-Log "❌ Registry-Datei fehlt: $InfoPath" -Error
}

# ------------------------------------------------------------
# 🧹 Cleanup – alles entfernen, was der Test erstellt hat
# ------------------------------------------------------------
Write-Host "`n🧹 Starte automatisches Aufräumen..."
foreach ($file in $CreatedFiles) {
    try {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Log "DELETED: $file"
        }
    } catch {
        Write-Log "❌ Fehler beim Löschen: $file → $_" -Error
    }
}

# Registry-Eintrag entfernen
if (Test-Path $InfoPath) {
    try {
        $registry = Get-Content $InfoPath -Raw | ConvertFrom-Json
        if ($registry.PSObject.Properties.Name -contains "Test_Lib_Dummy") {
            $registry.PSObject.Properties.Remove("Test_Lib_Dummy")
            $registry | ConvertTo-Json -Depth 4 | Out-File $InfoPath -Encoding UTF8
            Write-Log "UPDATED: Test_Lib_Dummy aus Registry entfernt."
        }
    } catch {
        Write-Log "❌ Fehler beim Entfernen aus Registry: $_" -Error
    }
}

Write-Host "`n✅ Testlauf abgeschlossen und alle Testdateien entfernt."
Write-Log "Testlauf abgeschlossen und alle Testdateien entfernt."
