# ============================================================
# Library: Lib_Json.ps1
# Version: LIB_V1.1.0
# Zweck:   JSON-Utility mit optionalem Logging & Backup
# Autor:   Herbert Schrotter
# Datum:   21.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Get-JsonFile, Save-JsonFile, Add-JsonEntry, Update-JsonValue, Remove-JsonEntry
#   Description: Einheitliche JSON-Verarbeitung (Lesen, Schreiben, Validieren, Backup, Logging)
#   Category: Core
#   Tags: JSON, Config, Backup, Logging
#   Dependencies: (none)
# ============================================================

# ------------------------------------------------------------
# ⚙️ Parameterdatei laden oder Standardwerte setzen
# ------------------------------------------------------------
$JsonConfigPath = "$PSScriptRoot\..\..\01_Config\Json_Config.json"

if (Test-Path $JsonConfigPath) {
    try {
        $JsonSettings = Get-Content $JsonConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "⚠️ Fehler beim Laden der Json_Config.json, Standardwerte werden verwendet." -ForegroundColor Yellow
        $JsonSettings = @{}
    }
} else {
    $JsonSettings = @{}
}

# Standardwerte bei fehlenden Einträgen ergänzen
if (-not $JsonSettings.DefaultDepth)   { $JsonSettings.DefaultDepth   = 8 }
if (-not $JsonSettings.Encoding)       { $JsonSettings.Encoding       = 'utf8' }
if (-not $JsonSettings.AutoBackup)     { $JsonSettings.AutoBackup     = $false }
if (-not $JsonSettings.BackupFolder)   { $JsonSettings.BackupFolder   = '05_Backup\Json' }
if (-not $JsonSettings.CreateIfMissing){ $JsonSettings.CreateIfMissing= $true }
if (-not $JsonSettings.EnableLogging)  { $JsonSettings.EnableLogging  = $false }
if (-not $JsonSettings.LogFolder)      { $JsonSettings.LogFolder      = '04_Logs' }
if (-not $JsonSettings.LogFile)        { $JsonSettings.LogFile        = 'Json_Log.txt' }
if (-not $JsonSettings.ShowErrors)     { $JsonSettings.ShowErrors     = $true }

# ------------------------------------------------------------
# 🧾 Hilfsfunktion: Write-JsonLog
# ------------------------------------------------------------
function Write-JsonLog {
    param(
        [string]$Action,
        [string]$Path
    )
    if (-not $JsonSettings.EnableLogging) { return }
    try {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $logLine = "[$timestamp] $Action → $Path"
        $logPath = "$PSScriptRoot\..\..\$($JsonSettings.LogFolder)\$($JsonSettings.LogFile)"
        Add-Content -Path $logPath -Value $logLine
    } catch {
        # kein Abbruch bei Loggingfehler
    }
}

# ------------------------------------------------------------
# 📖 Funktion: Get-JsonFile
# ------------------------------------------------------------
function Get-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$CreateIfMissing
    )
    try {
        if (-not (Test-Path $Path)) {
            if ($CreateIfMissing -or $JsonSettings.CreateIfMissing) {
                @() | ConvertTo-Json -Depth $JsonSettings.DefaultDepth | Set-Content -Path $Path -Encoding $JsonSettings.Encoding
                Write-JsonLog "CREATE" $Path
            } else {
                throw "Datei nicht gefunden: ${Path}"
            }
        }
        $content = Get-Content $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) { return @() }
        $json = $content | ConvertFrom-Json -ErrorAction Stop
        Write-JsonLog "READ" $Path
        return ,$json
    }
    catch {
        if ($JsonSettings.ShowErrors) {
            Write-Host "❌ Fehler beim Lesen von ${Path}: $($_.Exception.Message)" -ForegroundColor Red
        }
        return @()
    }
}

# ------------------------------------------------------------
# 💾 Funktion: Save-JsonFile
# ------------------------------------------------------------
function Save-JsonFile {
    param(
        [Parameter(Mandatory)][object]$Data,
        [Parameter(Mandatory)][string]$Path
    )
    try {
        $dir = Split-Path $Path
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $Data | ConvertTo-Json -Depth $JsonSettings.DefaultDepth | Set-Content -Path $Path -Encoding $JsonSettings.Encoding
        Write-JsonLog "WRITE" $Path
    }
    catch {
        if ($JsonSettings.ShowErrors) {
            Write-Host "❌ Fehler beim Schreiben von ${Path}: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# ------------------------------------------------------------
# ➕ Funktion: Add-JsonEntry
# ------------------------------------------------------------
function Add-JsonEntry {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object]$Entry
    )
    try {
        $jsonData = Get-JsonFile -Path $Path -CreateIfMissing
        if (-not ($jsonData -is [System.Collections.IEnumerable]) -or ($jsonData -is [string])) { $jsonData = @($jsonData) }
        if ($jsonData.Count -eq 0 -or ($jsonData.Count -eq 1 -and -not $jsonData[0])) { $jsonData = @() }
        $jsonData += $Entry
        Save-JsonFile -Data $jsonData -Path $Path
        Write-JsonLog "ADD" $Path
    }
    catch {
        if ($JsonSettings.ShowErrors) {
            Write-Host "❌ Fehler beim Hinzufügen zu ${Path}: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# ------------------------------------------------------------
# 🔄 Funktion: Update-JsonValue
# ------------------------------------------------------------
function Update-JsonValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][object]$Value
    )
    try {
        $json = Get-JsonFile -Path $Path -CreateIfMissing
        if ($null -eq $json) { $json = @{} }
        if ($json.PSObject.Properties.Name -contains $Key) { $json.$Key = $Value }
        else { Add-Member -InputObject $json -NotePropertyName $Key -NotePropertyValue $Value }
        Save-JsonFile -Data $json -Path $Path
        Write-JsonLog "UPDATE:$Key" $Path
    }
    catch {
        if ($JsonSettings.ShowErrors) {
            Write-Host "❌ Fehler beim Aktualisieren von ${Path}: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# ------------------------------------------------------------
# ❌ Funktion: Remove-JsonEntry
# ------------------------------------------------------------
function Remove-JsonEntry {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Value
    )
    try {
        $jsonData = Get-JsonFile -Path $Path -CreateIfMissing
        if (-not ($jsonData -is [System.Collections.IEnumerable])) {
            Write-Host "⚠️ JSON-Datei enthält keine Liste: ${Path}" -ForegroundColor Yellow
            return
        }
        $beforeCount = $jsonData.Count
        $jsonData = $jsonData | Where-Object { $_.$Key -ne $Value }
        $afterCount = $jsonData.Count
        Save-JsonFile -Data $jsonData -Path $Path
        Write-JsonLog "REMOVE:$($beforeCount - $afterCount)" $Path
    }
    catch {
        if ($JsonSettings.ShowErrors) {
            Write-Host "❌ Fehler beim Entfernen aus ${Path}: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
