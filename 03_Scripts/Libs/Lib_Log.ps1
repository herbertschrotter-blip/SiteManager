# ============================================================
# 🧩 LIB_LOG – Framework Logging System
# Version: LIB_V1.0.0
# Zweck:   Zentrales Logging-System für alle Framework-Module.
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================

# ManifestHint:
#   ExportFunctions: Load-LogConfig, Initialize-LogSession, Write-FrameworkLog, Write-DebugLog, Rotate-Logs, Close-LogSession
#   Description: Zentrales Framework-Logging mit Sitzungsdateien, Logrotation und Config-Autoerstellung
#   Category: Core
#   Tags: Logging, Framework, Rotation, Config
#   Dependencies: Lib_PathManager

# ------------------------------------------------------------
# 🧠 Globale Variablen
# ------------------------------------------------------------
$global:LogConfig = @{}
$global:CurrentLogFile = $null
$global:CurrentLogSessionStart = Get-Date

# ------------------------------------------------------------
# ⚙️ Funktion: Load-LogConfig
# ------------------------------------------------------------
function Load-LogConfig {
    try {
        if (Get-Command Get-PathConfig -ErrorAction SilentlyContinue) {
            $configFolder = Get-PathConfig
        } else {
            $configFolder = Join-Path $PSScriptRoot "..\..\01_Config"
        }

        if (-not (Test-Path $configFolder)) {
            New-Item -Path $configFolder -ItemType Directory | Out-Null
        }

        $configPath = Join-Path $configFolder "Log_Config.json"

        # Defaultwerte definieren
        $defaultConfig = [ordered]@{
            Version             = "CFG_V1.0.0"
            MaxLogsPerModule    = 10
            MaxAgeDays          = 14
            RotationMode        = "Both"   # "Count", "Age" oder "Both"
            EnableDebug         = $true
            EnableConsoleOutput = $true
            DateFormat          = "yyyy-MM-dd_HHmm"
            LogLevels           = @("INFO","WARN","ERROR","DEBUG")
            LogStructure        = "[{Timestamp}] [{Level}] [{Module}] {Message}"
            IncludeSessionHeader = $true
            SessionHeaderTemplate = "Neue Log-Session für {Module} gestartet um {Timestamp}"
        }

        # Falls Config fehlt → neue anlegen
        if (-not (Test-Path $configPath)) {
            $defaultConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding utf8
            Write-Host "🆕 Log_Config.json erstellt unter $configPath" -ForegroundColor Cyan
            $global:LogConfig = $defaultConfig
            return
        }

        # Falls Config vorhanden → einlesen
        $loaded = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        $global:LogConfig = $loaded
        Write-Host "✅ Log_Config.json geladen aus $configPath" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Fehler beim Laden der Log_Config.json: $_" -ForegroundColor Red
        $global:LogConfig = $defaultConfig
    }
}

# ------------------------------------------------------------
# 🚀 Funktion: Initialize-LogSession
# ------------------------------------------------------------
function Initialize-LogSession {
    param([string]$ModuleName = "Core")

    try {
        if (Get-Command Get-PathLogs -ErrorAction SilentlyContinue) {
            $logFolder = Get-PathLogs
        } else {
            $logFolder = Join-Path $PSScriptRoot "..\..\04_Logs"
        }

        if (-not (Test-Path $logFolder)) {
            New-Item -Path $logFolder -ItemType Directory | Out-Null
        }

        # Logrotation ausführen, bevor neue Session startet
        Rotate-Logs -ModuleName $ModuleName -LogConfig $global:LogConfig

        # Neue Logdatei mit Zeitstempel anlegen
        $timestamp = Get-Date -Format $global:LogConfig.DateFormat
        $logFile = Join-Path $logFolder "$($ModuleName)_Log_$timestamp.txt"
        $global:CurrentLogFile = $logFile
        $global:CurrentLogSessionStart = Get-Date

        $header = $global:LogConfig.SessionHeaderTemplate `
                    -replace "{Module}", $ModuleName `
                    -replace "{Timestamp}", (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

        if ($global:LogConfig.IncludeSessionHeader) {
            $headerLine = "[INIT] $header"
            Out-File -FilePath $logFile -Encoding utf8 -InputObject $headerLine
        }

        if ($global:LogConfig.EnableConsoleOutput) {
            Write-Host "🧾 Logsession gestartet: $logFile" -ForegroundColor Yellow
        }

        return $logFile
    }
    catch {
        Write-Host "❌ Fehler beim Initialisieren des Logs ($ModuleName): $_" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# ✍️ Funktion: Write-FrameworkLog
# ------------------------------------------------------------
function Write-FrameworkLog {
    param(
        [string]$Message,
        [string]$Module = "Core",
        [ValidateSet("INFO","WARN","ERROR","DEBUG")]
        [string]$Level = "INFO"
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $entry = $global:LogConfig.LogStructure `
            -replace "{Timestamp}", $timestamp `
            -replace "{Level}", $Level `
            -replace "{Module}", $Module `
            -replace "{Message}", $Message

        if ($global:CurrentLogFile) {
            Add-Content -Path $global:CurrentLogFile -Value $entry
        }

        if ($global:LogConfig.EnableConsoleOutput) {
            switch ($Level) {
                "INFO"  { Write-Host $entry -ForegroundColor Gray }
                "WARN"  { Write-Host $entry -ForegroundColor Yellow }
                "ERROR" { Write-Host $entry -ForegroundColor Red }
                "DEBUG" { if ($global:LogConfig.EnableDebug) { Write-Host $entry -ForegroundColor DarkCyan } }
            }
        }
    }
    catch {
        Write-Host "❌ Fehler beim Schreiben ins Log: $_" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# 🧪 Funktion: Write-DebugLog
# ------------------------------------------------------------
function Write-DebugLog {
    param([string]$Message, [string]$Module = "Core")

    if ($global:LogConfig.EnableDebug) {
        Write-FrameworkLog -Message $Message -Module $Module -Level "DEBUG"
    }
}

# ------------------------------------------------------------
# ♻️ Funktion: Rotate-Logs
# ------------------------------------------------------------
function Rotate-Logs {
    param(
        [string]$ModuleName,
        [hashtable]$LogConfig
    )

    try {
        if (Get-Command Get-PathLogs -ErrorAction SilentlyContinue) {
            $logFolder = Get-PathLogs
        } else {
            $logFolder = Join-Path $PSScriptRoot "..\..\04_Logs"
        }

        if (-not (Test-Path $logFolder)) {
            New-Item -Path $logFolder -ItemType Directory | Out-Null
        }

        $prefix = "${ModuleName}_Log_"
        $logs = Get-ChildItem -Path $logFolder -Filter "$prefix*.txt" -File -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending

        if (-not $logs) { return }

        # Nach Alter löschen
        if ($LogConfig.RotationMode -in @("Age","Both")) {
            $cutoff = (Get-Date).AddDays(-$LogConfig.MaxAgeDays)
            $oldLogs = $logs | Where-Object { $_.LastWriteTime -lt $cutoff }
            foreach ($file in $oldLogs) {
                Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                Write-FrameworkLog -Module $ModuleName -Level "INFO" -Message "Alte Logdatei gelöscht (Alter): $($file.Name)"
            }
        }

        # Nach Anzahl löschen
        if ($LogConfig.RotationMode -in @("Count","Both")) {
            $remaining = Get-ChildItem -Path $logFolder -Filter "$prefix*.txt" -File |
                         Sort-Object LastWriteTime -Descending
            if ($remaining.Count -gt $LogConfig.MaxLogsPerModule) {
                $toDelete = $remaining | Select-Object -Skip $LogConfig.MaxLogsPerModule
                foreach ($file in $toDelete) {
                    Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                    Write-FrameworkLog -Module $ModuleName -Level "INFO" -Message "Alte Logdatei gelöscht (Anzahl): $($file.Name)"
                }
            }
        }
    }
    catch {
        Write-Host "❌ Fehler bei Logrotation ($ModuleName): $_" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# 🏁 Funktion: Close-LogSession
# ------------------------------------------------------------
function Close-LogSession {
    param([string]$ModuleName = "Core")

    try {
        if (-not $global:CurrentLogFile) { return }

        $endTime = Get-Date
        $duration = New-TimeSpan -Start $global:CurrentLogSessionStart -End $endTime
        $summary = "[CLOSE] Sitzung beendet – Dauer: {0:hh\:mm\:ss}" -f $duration

        Add-Content -Path $global:CurrentLogFile -Value $summary
        if ($global:LogConfig.EnableConsoleOutput) {
            Write-Host $summary -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ Fehler beim Schließen des Logs: $_" -ForegroundColor Red
    }
}
