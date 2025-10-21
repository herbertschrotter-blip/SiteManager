# ============================================================
# Modul: Test-LibJson.ps1
# Version: DEV_V1.6.0
# Zweck:   Vollständiger manueller Test für Lib_Json.ps1 (alle 9 Haupttests)
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Test-LibJson
#   Description: Vollständiger Test aller JSON-Funktionen (Write, Read, Modify, Validate, Performance)
#   Category: Dev
#   Tags: JSON, Test, Developer, IO, Performance, Validation
#   Dependencies: Lib_Json.ps1, Lib_PathManager.ps1
# ============================================================

# ------------------------------------------------------------
# 🔧 Libraries laden
# ------------------------------------------------------------
$libJsonPath        = "$PSScriptRoot\..\..\Libs\Lib_Json.ps1"
$libPathManagerPath = "$PSScriptRoot\..\..\Libs\Lib_PathManager.ps1"

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

# ------------------------------------------------------------
# ⚙️ Pfade
# ------------------------------------------------------------
$testFolder = if ($paths) { Join-Path $paths.Config "Tests" } else { "$PSScriptRoot\Tests" }
$testFile   = Join-Path $testFolder "Json_Test.json"
$logPath    = if ($paths) { Join-Path $paths.Logs "Json_Log.txt" } else { "$PSScriptRoot\Json_Log.txt" }

if (-not (Test-Path $testFolder)) { New-Item -ItemType Directory -Path $testFolder -Force | Out-Null }

# ------------------------------------------------------------
# 🧩 Hilfsfunktionen
# ------------------------------------------------------------
function Show-Result {
    param([string]$Test, [bool]$Success)
    if ($Success) {
        Write-Host ("✅ " + $Test) -ForegroundColor Green
    } else {
        Write-Host ("❌ " + $Test) -ForegroundColor Red
    }
}

function Check-Abort {
    param([string]$Msg = "Weiter mit [ENTER] oder 'q' zum Abbrechen")
    $input = Read-Host "❓ $Msg"
    if ($input -eq 'q' -or $input -eq 'Q') {
        Write-Host "🛑 Testvorgang abgebrochen durch Benutzer." -ForegroundColor Yellow
        exit
    }
}

function Show-Raw {
    param([string]$Path)
    Write-Host "`n📄 RAW-Inhalt:" -ForegroundColor Gray
    try {
        $raw = Get-Content -Path $Path -Raw -ErrorAction Stop
        Write-Host $raw -ForegroundColor DarkCyan
    } catch {
        Write-Host "⚠️ Konnte RAW-Inhalt nicht lesen: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------
# 🧪 TESTSUITE – 9 Schritte
# ------------------------------------------------------------
function Test-LibJson {
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "🧩 KOMPLETTER FUNKTIONSTEST DER LIB_JSON.PS1" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan

    # Vorbereitung
    if (Test-Path $testFile) { Remove-Item $testFile -Force }
    if (Test-Path $logPath)  { Remove-Item $logPath  -Force }

    # 1️⃣ Datei erstellen (mit Dummy)
    $initData = @(@{ Init = "true"; Zeit = (Get-Date).ToString("HH:mm:ss") })
    Save-JsonFile -Data $initData -Path $testFile
    Show-Result "Datei erstellt" (Test-Path $testFile)
    Start-Sleep -Milliseconds 500
    Show-Raw $testFile
    Check-Abort

    # 2️⃣ Datei lesen
    $data = Get-JsonFile -Path $testFile
    Show-Result "Datei lesbar" ($data -is [array] -and $data.Count -gt 0)
    Check-Abort

    # 3️⃣ Dummy löschen
    Remove-JsonEntry -Path $testFile -Key "Init" -Value "true"
    Start-Sleep -Milliseconds 200
    $dataAfter = Get-JsonFile -Path $testFile
    Show-Result "Dummy-Eintrag gelöscht" ($dataAfter.Count -eq 0)
    Show-Raw $testFile
    Check-Abort

    # 4️⃣ Eintrag hinzufügen
    $entry = @{ Name = "ProjektX"; Wert = 123; Zeit = (Get-Date).ToString("HH:mm:ss") }
    Add-JsonEntry -Path $testFile -Entry $entry
    $data = Get-JsonFile -Path $testFile
    Show-Result "Eintrag hinzugefügt" ($data.Count -eq 1 -and $data[0].Name -eq "ProjektX")
    Show-Raw $testFile
    Check-Abort

    # 5️⃣ Wert aktualisieren
    Update-JsonValue -Path $testFile -Key "Version" -Value "1.0.0"
    $updated = Get-JsonFile -Path $testFile
    $ok = $updated | Get-Member -Name "Version" -ErrorAction SilentlyContinue
    Show-Result "Wert 'Version' hinzugefügt" ($null -ne $ok)
    Check-Abort

    # 6️⃣ Roundtrip-Integrität
    $roundTrip = Get-JsonFile -Path $testFile
    Save-JsonFile -Data $roundTrip -Path $testFile
    $reRead = Get-JsonFile -Path $testFile
    Show-Result "Roundtrip-Integrität (Lesen=Schreiben)" ($reRead.Count -eq $roundTrip.Count)
    Check-Abort

    # 7️⃣ Fehlerhafte Datei (ungültiges JSON)
    Set-Content -Path $testFile -Value "{ invalid json" -Encoding utf8
    $jsonInvalid = Get-JsonFile -Path $testFile
    Show-Result "Fehlerbehandlung bei ungültigem JSON" ($jsonInvalid.Count -eq 0)
    Check-Abort

    # 8️⃣ Automatische Erstellung bei fehlender Datei
    if (Test-Path $testFile) { Remove-Item $testFile -Force }
    $jsonNew = Get-JsonFile -Path $testFile -CreateIfMissing
    Show-Result "Leere Datei automatisch erstellt" (Test-Path $testFile)
    Check-Abort

    # 9️⃣ Performance-Test
    $okPerf = $true
    try {
        for ($i = 1; $i -le 100; $i++) {
            Add-JsonEntry -Path $testFile -Entry @{ TestNr = $i }
        }
        $count = (Get-JsonFile -Path $testFile).Count
        $okPerf = ($count -ge 100)
    } catch { $okPerf = $false }
    Show-Result "100 Schreibvorgänge erfolgreich" $okPerf

    # Abschluss
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "✅ KOMPLETTE TESTSUITE ABGESCHLOSSEN" -ForegroundColor Green
    Write-Host "📄 JSON-Datei: $testFile"
    Write-Host "🧾 Log-Datei:  $logPath"
    Write-Host "============================================" -ForegroundColor Cyan
}

# ------------------------------------------------------------
# ▶️ Test starten
# ------------------------------------------------------------
Test-LibJson
