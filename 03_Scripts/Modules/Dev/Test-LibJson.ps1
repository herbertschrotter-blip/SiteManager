# ============================================================
# Modul: Test-LibJson.ps1
# Version: DEV_V1.3.0
# Zweck:   Manueller Test für Lib_Json.ps1 mit PathManager-Unterstützung
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Test-LibJson
#   Description: Manueller Test für alle JSON-Funktionen der Lib_Json.ps1 mit dynamischer Pfaderkennung
#   Category: Dev
#   Tags: JSON, Test, Developer, Debug, Validation, Paths, Interactive
#   Dependencies: Lib_Json.ps1, Lib_PathManager.ps1
# ============================================================

# ------------------------------------------------------------
# 🔧 Libraries laden
# ------------------------------------------------------------
$libPathManagerPath = "$PSScriptRoot\..\..\Libs\Lib_PathManager.ps1"
$libJsonPath        = "$PSScriptRoot\..\..\Libs\Lib_Json.ps1"

if (Test-Path $libPathManagerPath) {
    . $libPathManagerPath
    $paths = Get-PathMap
} else {
    Write-Host "⚠️ PathManager nicht gefunden – arbeite mit relativen Pfaden." -ForegroundColor Yellow
    $paths = $null
}

if (Test-Path $libJsonPath) {
    . $libJsonPath
} else {
    Write-Host "❌ Lib_Json.ps1 nicht gefunden unter: $libJsonPath" -ForegroundColor Red
    exit
}


. $libPathManagerPath
. $libJsonPath

# ------------------------------------------------------------
# ⚙️ Testpfade automatisch über PathManager
# ------------------------------------------------------------
$paths = Get-PathMap
$testFolder = Join-Path $paths.Config "Tests"
$testFile   = Join-Path $testFolder "Json_Test.json"
$logPath    = Join-Path $paths.Logs "Json_Log.txt"

if (-not (Test-Path $testFolder)) { New-Item -ItemType Directory -Path $testFolder | Out-Null }

# ------------------------------------------------------------
# 🧩 Hilfsfunktion zur Ergebnisanzeige
# ------------------------------------------------------------
function Show-Result {
    param([string]$Test, [bool]$Success)
    if ($Success) {
        Write-Host ("✅ " + $Test) -ForegroundColor Green
    } else {
        Write-Host ("❌ " + $Test) -ForegroundColor Red
    }
}

function Pause-Step {
    param([string]$Message)
    Write-Host ""
    Read-Host "⏸️  Weiter mit [ENTER] – $Message"
}

# ------------------------------------------------------------
# 🧪 Hauptfunktion: Test-LibJson
# ------------------------------------------------------------
function Test-LibJson {

    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "🧩 MANUELLER FUNKTIONSTEST DER LIB_JSON.PS1" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan

    # Alte Dateien löschen
    if (Test-Path $testFile) { Remove-Item $testFile -Force }
    if (Test-Path $logPath)  { Remove-Item $logPath  -Force }

    try {
        Pause-Step "Starte mit Test 1 – Datei erstellen & lesen"
        # 1️⃣ Test: Datei-Erstellung & Lesen
        $initData = @(@{ Init = "true"; Zeit = (Get-Date).ToString("HH:mm:ss") })
        Save-JsonFile -Data $initData -Path $testFile
        $exists = Test-Path $testFile
        Show-Result "Datei erstellt" $exists

        # ⏱️ kurze Wartezeit (OneDrive / Caching)
        Start-Sleep -Milliseconds 500

        $data = Get-JsonFile -Path $testFile
        Show-Result "Datei lesbar" ($data -is [array] -and $data.Count -gt 0)


        Pause-Step "Test 2 – Eintrag hinzufügen"
        # 2️⃣ Test: Hinzufügen eines Eintrags
        $entry = @{ Name = "ProjektX"; Wert = 123; Zeit = (Get-Date).ToString("HH:mm:ss") }
        Add-JsonEntry -Path $testFile -Entry $entry
        $data = Get-JsonFile -Path $testFile
        Show-Result "Eintrag hinzugefügt" ($data.Count -eq 1 -and $data[0].Name -eq "ProjektX")

        Pause-Step "Test 3 – Wert aktualisieren"
        # 3️⃣ Test: Wert aktualisieren
        Update-JsonValue -Path $testFile -Key "Version" -Value "1.0.0"
        $updated = Get-JsonFile -Path $testFile
        $ok = $updated | Get-Member -Name "Version" -ErrorAction SilentlyContinue
        Show-Result "Wert 'Version' hinzugefügt" ($null -ne $ok)

        Pause-Step "Test 4 – Eintrag löschen"
        # 4️⃣ Test: Eintrag löschen
        Remove-JsonEntry -Path $testFile -Key "Name" -Value "ProjektX"
        $jsonAfterRemove = Get-JsonFile -Path $testFile
        Show-Result "Eintrag gelöscht" ($jsonAfterRemove.Count -eq 0)

        Pause-Step "Test 5 – Leere Datei automatisch erstellen"
        # 5️⃣ Test: Automatische Erstellung bei fehlender Datei
        if (Test-Path $testFile) { Remove-Item $testFile -Force }
        $jsonNew = Get-JsonFile -Path $testFile -CreateIfMissing
        Show-Result "Leere Datei automatisch erstellt" (Test-Path $testFile)

        Pause-Step "Test 6 – Ungültiges JSON simulieren"
        # 6️⃣ Test: Ungültiges JSON erkennen
        Set-Content -Path $testFile -Value "{ invalid json" -Encoding utf8
        $jsonInvalid = Get-JsonFile -Path $testFile
        Show-Result "Fehlerbehandlung bei ungültigem JSON" ($jsonInvalid.Count -eq 0)

        Pause-Step "Test 7 – Logging prüfen"
        # 7️⃣ Test: Logging prüfen
        $logExists = Test-Path $logPath
        Show-Result "Logging-Datei vorhanden" $logExists
        if ($logExists) {
            $lines = Get-Content $logPath | Select-Object -Last 5
            $okLog = ($lines -match "WRITE|READ|ADD|REMOVE|UPDATE")
            Show-Result "Log-Einträge vorhanden" ($okLog.Count -gt 0)
        }

        Pause-Step "Test 8 – Roundtrip-Integrität"
        # 8️⃣ Test: JSON-Integrität (Lesen & Schreiben mehrfach)
        $testObj = @(
            @{ ID = 1; Name = "Alpha" },
            @{ ID = 2; Name = "Beta" }
        )
        Save-JsonFile -Data $testObj -Path $testFile
        $roundTrip = Get-JsonFile -Path $testFile
        Show-Result "Roundtrip-Integrität (Lesen=Schreiben)" ($roundTrip.Count -eq 2 -and $roundTrip[1].Name -eq "Beta")

        Pause-Step "Test 9 – Performance-Test (100 Schreibvorgänge)"
        # 9️⃣ Test: Performance (100 Schreibvorgänge)
        $okPerf = $true
        try {
            for ($i = 1; $i -le 100; $i++) {
                Add-JsonEntry -Path $testFile -Entry @{ TestNr = $i }
            }
            $count = (Get-JsonFile -Path $testFile).Count
            $okPerf = ($count -ge 100)
        } catch { $okPerf = $false }
        Show-Result "100 Schreibvorgänge erfolgreich" $okPerf

    } catch {
        Write-Host "❌ Unerwarteter Fehler: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n📄 JSON-Datei: $testFile"
    Write-Host "🧾 Log-Datei:  $logPath"
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "✅ MANUELLER TEST ABGESCHLOSSEN" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
}

# ------------------------------------------------------------
# ▶️ Test starten
# ------------------------------------------------------------
Test-LibJson
