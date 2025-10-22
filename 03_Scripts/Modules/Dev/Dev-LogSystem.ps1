# ============================================================
# 🧩 DEV-MODUL – LogSystem-Testfunktionen
# Version: DEV_V1.4.0
# Zweck:   Testfunktionen für Lib_Log.ps1 – steuerbar über Lib_Menu.ps1
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================

# ManifestHint:
#   ExportFunctions: Test-LoadConfig, Test-InitSession, Test-WriteLogs, Test-Rotate, Test-ListLogs
#   Description: Entwicklungsmodul zur Prüfung der Logging-Library, vollständig steuerbar über Lib_Menu.
#   Category: DevTools
#   Tags: Logging, Menu, Test, Rotation, Config
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
# ------------------------------------------------------------
# 🧩 Testfunktion: Config laden und anzeigen (fix für Join-Path)
# ------------------------------------------------------------
function Test-LoadConfig {
    Write-FrameworkLog -Module "DevLogSystem" -Message "Config laden"
    Load-LogConfig

    if ($global:LogConfig) {
        Write-Host "`n📄 Aktuelle Log-Konfiguration geladen:" -ForegroundColor Cyan

        # Pfad zur Config ermitteln (korrekt ohne Inline-if)
        if (Get-Command Get-PathConfig -ErrorAction SilentlyContinue) {
            $configBase = Get-PathConfig
        }
        else {
            $configBase = Join-Path $PSScriptRoot "..\..\01_Config"
        }

        $configPath = Join-Path $configBase "Log_Config.json"

        # Konsolenausgabe der Werte
        Write-Host ("📁 Pfad:              " + $configPath) -ForegroundColor DarkGray
        Write-Host ("🗓️  Version:           " + $global:LogConfig.Version) -ForegroundColor White
        Write-Host ("🔢 MaxLogsPerModule:  " + $global:LogConfig.MaxLogsPerModule) -ForegroundColor White
        Write-Host ("📆 MaxAgeDays:        " + $global:LogConfig.MaxAgeDays) -ForegroundColor White
        Write-Host ("🔁 RotationMode:      " + $global:LogConfig.RotationMode) -ForegroundColor White
        Write-Host ("💬 LogStructure:      " + $global:LogConfig.LogStructure) -ForegroundColor White
        Write-Host ("💡 EnableDebug:       " + $global:LogConfig.EnableDebug) -ForegroundColor White
        Write-Host ("🖥️  ConsoleOutput:     " + $global:LogConfig.EnableConsoleOutput) -ForegroundColor White
    }
    else {
        Write-Host "❌ Keine Log-Konfiguration gefunden oder nicht geladen." -ForegroundColor Red
    }
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

# ------------------------------------------------------------
# 🧩 Testfunktion: Rotation mit Dummy-Logs aus Config + Zeitabstand
# ------------------------------------------------------------
function Test-Rotate {
    Write-Host "`n♻️ Starte Rotationstest (Dummy-Logs + echte Rotation)..." -ForegroundColor Yellow

    # 1️⃣ Prüfen, ob Config geladen wurde
    if (-not $global:LogConfig) {
        Write-Host "⚠️ Keine LogConfig gefunden – bitte zuerst Menüpunkt 1 'Config laden' ausführen." -ForegroundColor Red
        return
    }

    # 2️⃣ Log-Verzeichnis bestimmen
    if (Get-Command Get-PathLogs -ErrorAction SilentlyContinue) {
        $logFolder = Get-PathLogs
    } else {
        $logFolder = Join-Path $PSScriptRoot "..\..\04_Logs"
    }

    if (-not (Test-Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory | Out-Null
    }

    # 3️⃣ MaxLogsPerModule aus Config übernehmen
    $maxLogs = [int]$global:LogConfig.MaxLogsPerModule
    $totalLogs = $maxLogs + 3
    $prefix = "DevLogSystem_Log_"

    Write-Host "🧱 Erstelle $totalLogs Dummy-Logs (MaxLogs=$maxLogs + 3 extra)..." -ForegroundColor Cyan

    # 4️⃣ Dummy-Dateien mit 1-Minuten-Abstand erzeugen
    $baseTime = (Get-Date).AddMinutes(-$totalLogs)
    for ($i = 1; $i -le $totalLogs; $i++) {
        $timestamp = $baseTime.AddMinutes($i).ToString($global:LogConfig.DateFormat)
        $dummyFile = Join-Path $logFolder "$prefix$timestamp.txt"
        "Dummy-Testeintrag Nr. $i" | Out-File -FilePath $dummyFile -Encoding utf8
    }

    # 5️⃣ Überblick vor der Rotation
    $beforeFiles = Get-ChildItem -Path $logFolder -Filter "$prefix*.txt" | Sort-Object LastWriteTime
    $beforeCount = $beforeFiles.Count

    Write-Host "`n📂 Vor der Rotation:" -ForegroundColor White
    Write-Host "   Dateien gefunden: $beforeCount" -ForegroundColor Gray
    if ($beforeCount -le $totalLogs) {
        Write-Host "   Dummy-Logs erstellt bis: $($beforeFiles[-1].Name)" -ForegroundColor DarkGray
    }

    # 6️⃣ Rotation starten
    Write-Host "`n🌀 Führe Rotation (Config-basiert, MaxLogs=$maxLogs) aus..." -ForegroundColor Yellow
    Rotate-Logs -ModuleName "DevLogSystem" -LogConfig $global:LogConfig

    # 7️⃣ Überblick nach der Rotation
    Start-Sleep -Seconds 1
    $afterFiles = Get-ChildItem -Path $logFolder -Filter "$prefix*.txt" | Sort-Object LastWriteTime
    $afterCount = $afterFiles.Count
    $deletedCount = $beforeCount - $afterCount

    Write-Host "`n✅ Rotation abgeschlossen." -ForegroundColor Green
    Write-Host "📉 Gelöschte Dateien: $deletedCount" -ForegroundColor White
    Write-Host "📁 Verbleibend: $afterCount (Soll: $maxLogs)" -ForegroundColor White

    if ($deletedCount -gt 0) {
        Write-Host "`n🧾 Gelöschte Dateien:" -ForegroundColor DarkGray
        foreach ($log in ($beforeFiles | Select-Object -First $deletedCount)) {
            Write-Host "   ❌ $($log.Name)" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
}

# ------------------------------------------------------------
# 🧩 Testfunktion: Logdateien im Verzeichnis auflisten
# ------------------------------------------------------------
function Test-ListLogs {
    Write-Host "`n📂 Liste der vorhandenen Logdateien für DevLogSystem..." -ForegroundColor Yellow

    # 1️⃣ Logverzeichnis ermitteln
    if (Get-Command Get-PathLogs -ErrorAction SilentlyContinue) {
        $logFolder = Get-PathLogs
    } else {
        $logFolder = Join-Path $PSScriptRoot "..\..\04_Logs"
    }

    if (-not (Test-Path $logFolder)) {
        Write-Host "❌ Kein Logverzeichnis gefunden unter: $logFolder" -ForegroundColor Red
        return
    }

    # 2️⃣ Dateien abrufen
    $logs = Get-ChildItem -Path $logFolder -Filter "DevLogSystem_Log_*.txt" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending

    if (-not $logs) {
        Write-Host "⚠️ Keine Logdateien gefunden im Ordner: $logFolder" -ForegroundColor DarkYellow
        return
    }

    # 3️⃣ Ausgabe
    Write-Host ""
    Write-Host ("{0,-40} {1,12} {2,22} {3,22}" -f "📄 Dateiname", "Größe (KB)", "Erstellt am", "Geändert am") -ForegroundColor Cyan
    Write-Host ("".PadRight(100,"-")) -ForegroundColor DarkGray

    $latest = $logs | Select-Object -First 1

    foreach ($file in $logs) {
        $sizeKB = [math]::Round($file.Length / 1KB, 1)
        $line = "{0,-40} {1,12:N1} {2,22} {3,22}" -f $file.Name, $sizeKB, $file.CreationTime.ToString("yyyy-MM-dd HH:mm:ss"), $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")

        if ($file.FullName -eq $latest.FullName) {
            Write-Host $line -ForegroundColor Green   # neueste Datei grün
        } else {
            Write-Host $line -ForegroundColor White
        }
    }

    Write-Host "`n✅ Insgesamt $($logs.Count) Logdateien gefunden." -ForegroundColor Green
}
