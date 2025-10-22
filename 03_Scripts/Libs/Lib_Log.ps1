# ============================================================
# 🧩 LIB_LOG – Framework Logging System (Single-Active Lock Mode)
# Version: LIB_V1.2.0
# Zweck:   Zentrales Logging-System mit Exklusiv-Zugriff (Lock)
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Load-LogConfig, Initialize-LogSession, Write-FrameworkLog, Write-DebugLog, Rotate-Logs, Close-LogSession, Lock-LogSystem, Unlock-LogSystem
#   Description: Framework-Logging mit exklusivem Modulzugriff (Lock-System) und Logrotation
#   Category: Core
#   Tags: Logging, Framework, Lock, Config, Rotation, SiteManager
#   Dependencies: Lib_PathManager
# ============================================================


# ------------------------------------------------------------
# 🧠 Globale Variablen
# ------------------------------------------------------------
$global:LogConfig = @{}
$global:ActiveLogSessions = @{}   # Liste aktiver Sessions (normalerweise nur 1)
$global:LogSystemLockedBy = $null # 🧩 Nur ein Modul darf aktiv loggen


# ------------------------------------------------------------
# 🔒 Funktionen: Lock-Management
# ------------------------------------------------------------
function Lock-LogSystem {
    param([string]$ModuleName)

    if ($global:LogSystemLockedBy -and $global:LogSystemLockedBy -ne $ModuleName) {
        Write-Host "⚠️ Logging aktuell gesperrt durch Modul: $($global:LogSystemLockedBy)" -ForegroundColor Yellow
        return $false
    }

    $global:LogSystemLockedBy = $ModuleName
    Write-Host "🔒 LogSystem exklusiv gesperrt durch: $ModuleName" -ForegroundColor Cyan
    return $true
}

function Unlock-LogSystem {
    param([string]$ModuleName)

    if ($global:LogSystemLockedBy -eq $ModuleName) {
        $global:LogSystemLockedBy = $null
        Write-Host "🔓 LogSystem-Freigabe durch: $ModuleName" -ForegroundColor Green
    }
}


# ------------------------------------------------------------
# ⚙️ Funktion: Load-LogConfig (mit automatischer Hashtable-Umwandlung)
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

        # Standardwerte definieren
        $defaultConfig = [ordered]@{
            Version              = "CFG_V1.2.0"
            MaxLogsPerModule     = 10
            MaxAgeDays           = 14
            RotationMode         = "Both"
            EnableDebug          = $true
            EnableConsoleOutput  = $true
            DateFormat           = "yyyy-MM-dd_HHmm_ss"
            LogLevels            = @("INFO","WARN","ERROR","DEBUG")
            LogStructure         = "[{Timestamp}] [{Level}] [{Module}] {Message}"
            IncludeSessionHeader = $true
            SessionHeaderTemplate= "Neue Log-Session für {Module} gestartet um {Timestamp}"
        }

        if (-not (Test-Path $configPath)) {
            $defaultConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding utf8
            Write-Host "🆕 Log_Config.json erstellt unter $configPath" -ForegroundColor Cyan
            $global:LogConfig = $defaultConfig
            return
        }

        $loaded = Get-Content -Path $configPath -Raw | ConvertFrom-Json

        # PSCustomObject → Hashtable
        $hashConfig = @{}
        foreach ($prop in $loaded.PSObject.Properties) {
            $hashConfig[$prop.Name] = $prop.Value
        }

        $global:LogConfig = $hashConfig
        Write-Host "✅ Log_Config.json geladen und in Hashtable umgewandelt." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Fehler beim Laden der Log_Config.json: $_" -ForegroundColor Red
        $global:LogConfig = $defaultConfig
    }
}


# ------------------------------------------------------------
# 🚀 Funktion: Initialize-LogSession (mit Lock-Prüfung)
# ------------------------------------------------------------
function Initialize-LogSession {
    param([string]$ModuleName = "Core")

    try {
        if (-not (Lock-LogSystem -ModuleName $ModuleName)) {
            Write-Host "❌ LogSession für $ModuleName nicht gestartet – System belegt." -ForegroundColor Red
            return
        }

        if (Get-Command Get-PathLogs -ErrorAction SilentlyContinue) {
            $logFolder = Get-PathLogs
        } else {
            $logFolder = Join-Path $PSScriptRoot "..\..\04_Logs"
        }

        if (-not (Test-Path $logFolder)) {
            New-Item -Path $logFolder -ItemType Directory | Out-Null
        }

        Rotate-Logs -ModuleName $ModuleName -LogConfig $global:LogConfig

        $timestamp = Get-Date -Format $global:LogConfig.DateFormat
        $logFile = Join-Path $logFolder "$($ModuleName)_Log_$timestamp.txt"

        $sessionHeader = $global:LogConfig.SessionHeaderTemplate `
            -replace "{Module}", $ModuleName `
            -replace "{Timestamp}", (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

        if ($global:LogConfig.IncludeSessionHeader) {
            "[INIT] $sessionHeader" | Out-File -FilePath $logFile -Encoding utf8
        }

        $global:ActiveLogSessions[$ModuleName] = @{
            File   = $logFile
            Start  = Get-Date
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
        # Falls kein Lock für dieses Modul → ignorieren
        if ($global:LogSystemLockedBy -and $global:LogSystemLockedBy -ne $Module) {
            Write-Host "⚠️ Modul '$Module' darf derzeit nicht loggen (System belegt durch $($global:LogSystemLockedBy))." -ForegroundColor DarkYellow
            return
        }

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $entry = $global:LogConfig.LogStructure `
            -replace "{Timestamp}", $timestamp `
            -replace "{Level}", $Level `
            -replace "{Module}", $Module `
            -replace "{Message}", $Message

        if ($global:ActiveLogSessions.ContainsKey($Module)) {
            $file = $global:ActiveLogSessions[$Module].File
            Add-Content -Path $file -Value $entry
        } else {
            $fallback = Join-Path (Join-Path $PSScriptRoot "..\..\04_Logs") "Fallback_Log.txt"
            Add-Content -Path $fallback -Value $entry
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
        Write-Host "❌ Fehler beim Schreiben ins Log ($Module): $_" -ForegroundColor Red
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

        if ($LogConfig.RotationMode -in @("Age","Both")) {
            $cutoff = (Get-Date).AddDays(-$LogConfig.MaxAgeDays)
            $oldLogs = $logs | Where-Object { $_.LastWriteTime -lt $cutoff }
            foreach ($file in $oldLogs) {
                Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                Write-FrameworkLog -Module $ModuleName -Level "INFO" -Message "Alte Logdatei gelöscht (Alter): $($file.Name)"
            }
        }

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
        if (-not $global:ActiveLogSessions.ContainsKey($ModuleName)) { return }

        $session = $global:ActiveLogSessions[$ModuleName]
        $endTime = Get-Date
        $duration = New-TimeSpan -Start $session.Start -End $endTime
        $summary = "[CLOSE] Sitzung beendet – Dauer: {0:hh\\:mm\\:ss}" -f $duration

        Add-Content -Path $session.File -Value $summary
        if ($global:LogConfig.EnableConsoleOutput) {
            Write-Host $summary -ForegroundColor Green
        }

        $global:ActiveLogSessions.Remove($ModuleName)
        Unlock-LogSystem -ModuleName $ModuleName
    }
    catch {
        Write-Host "❌ Fehler beim Schließen des Logs ($ModuleName): $_" -ForegroundColor Red
    }
}
