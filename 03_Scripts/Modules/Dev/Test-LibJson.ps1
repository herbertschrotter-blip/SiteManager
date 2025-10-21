# ============================================================
# Modul: Test-LibJson.ps1
# Version: DEV_V1.1.2
# Zweck:   Umfassender automatischer Test für Lib_Json.ps1
# Autor:   Herbert Schrotter
# Datum:   21.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Test-LibJson
#   Description: Vollautomatischer Test für alle JSON-Funktionen der Lib_Json.ps1
#   Category: Dev
#   Tags: JSON, Test, Developer, Debug, Validation
#   Dependencies: Lib_Json.ps1
# ============================================================

# ------------------------------------------------------------
# 🔧 Library laden (korrigierter Pfad)
# ------------------------------------------------------------
$libPath = "$PSScriptRoot\..\..\Libs\Lib_Json.ps1"

if (-not (Test-Path $libPath)) {
    Write-Host "❌ Lib_Json.ps1 nicht gefunden unter: $libPath" -ForegroundColor Red
    exit
}
. $libPath

# ------------------------------------------------------------
# ⚙️ Testpfade (korrigiert)
# ------------------------------------------------------------
$testFolder = "$PSScriptRoot\..\..\..\01_Config\Tests"
$testFile   = Join-Path $testFolder "Json_Test.json"
$logPath    = "$PSScriptRoot\..\..\..\04_Logs\Json_Log.txt"

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

# ------------------------------------------------------------
# 🧪 Hauptfunktion: Test-LibJson
# ------------------------------------------------------------
function Test-LibJson {

    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "🧩 STARTE FUNKTIONSTEST DER LIB_JSON.PS1" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan

    # Alte Dateien löschen
    if (Test-Path $testFile) { Remove-Item $testFile -Force }
    if (Test-Path $logPath)  { Remove-Item $logPath  -Force }

    try {
        # 1️⃣ Test: Datei-Erstellung & Lesen
        Save-JsonFile -Data @() -Path $testFile
        $exists = Test-Path $testFile
        Show-Result "Datei erstellt" $exists

        $data = Get-JsonFile -Path $testFile
        Show-Result "Datei lesbar" ($data -is [array])

        # 2️⃣ Test: Hinzufügen eines Eintrags
        $entry = @{ Name = "ProjektX"; Wert = 123; Zeit = (Get-Date).ToString("HH:mm:ss") }
        Add-JsonEntry -Path $testFile -Entry $entry
        $data = Get-JsonFile -Path $testFile
        Show-Result "Eintrag hinzugefügt" ($data.Count -eq 1 -and $data[0].Name -eq "ProjektX")

        # 3️⃣ Test: Wert aktualisieren
        Update-JsonValue -Path $testFile -Key "Version" -Value "1.0.0"
        $updated = Get-JsonFile -Path $testFile
        $ok = $updated | Get-Member -Name "Version" -ErrorAction SilentlyContinue
        Show-Result "Wert 'Version' hinzugefügt" ($null -ne $ok)

        # 4️⃣ Test: Eintrag löschen
        Remove-JsonEntry -Path $testFile -Key "Name" -Value "ProjektX"
        $jsonAfterRemove = Get-JsonFile -Path $testFile
        Show-Result "Eintrag gelöscht" ($jsonAfterRemove.Count -eq 0)

        # 5️⃣ Test: Automatische Erstellung bei fehlender Datei
        if (Test-Path $testFile) { Remove-Item $testFile -Force }
        $jsonNew = Get-JsonFile -Path $testFile -CreateIfMissing
        Show-Result "Leere Datei automatisch erstellt" (Test-Path $testFile)

        # 6️⃣ Test: Ungültiges JSON erkennen
        Set-Content -Path $testFile -Value "{ invalid json" -Encoding utf8
        $jsonInvalid = Get-JsonFile -Path $testFile
        Show-Result "Fehlerbehandlung bei ungültigem JSON" ($jsonInvalid.Count -eq 0)

        # 7️⃣ Test: Logging prüfen
        $logExists = Test-Path $logPath
        Show-Result "Logging-Datei vorhanden" $logExists
        if ($logExists) {
            $lines = Get-Content $logPath | Select-Object -Last 5
            $okLog = ($lines -match "WRITE|READ|ADD|REMOVE|UPDATE")
            Show-Result "Log-Einträge vorhanden" ($okLog.Count -gt 0)
        }

        # 8️⃣ Test: JSON-Integrität (Lesen & Schreiben mehrfach)
        $testObj = @(
            @{ ID = 1; Name = "Alpha" },
            @{ ID = 2; Name = "Beta" }
        )
        Save-JsonFile -Data $testObj -Path $testFile
        $roundTrip = Get-JsonFile -Path $testFile
        Show-Result "Roundtrip-Integrität (Lesen=Schreiben)" ($roundTrip.Count -eq 2 -and $roundTrip[1].Name -eq "Beta")

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
    Write-Host "✅ TESTS ABGESCHLOSSEN" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
}

# ------------------------------------------------------------
# ▶️ Test starten
# ------------------------------------------------------------
Test-LibJson
