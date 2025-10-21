# ============================================================
# Library: Lib_PathManager.ps1
# Version: LIB_V1.0.0
# Zweck:   Ermittelt und verwaltet die Basis- und Unterordnerpfade des Site Managers
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Get-ProjectRoot, Get-PathMap, Get-PathConfig, Get-PathLogs, Get-PathBackup, Get-PathTemplates
#   Description: Erkennt automatisch den Site Manager Root-Ordner und liefert zentrale Pfadfunktionen
#   Category: Core
#   Tags: Path, Root, Structure, Framework
#   Dependencies: (none)
# ============================================================

# ------------------------------------------------------------
# 🧭 Funktion: Get-ProjectRoot
# Zweck:
#   Findet den obersten Ordner des Site Managers anhand der typischen Struktur.
# Rückgabe:
#   Vollständiger Pfad des Root-Verzeichnisses oder $null bei Fehler.
# ------------------------------------------------------------
function Get-ProjectRoot {
    param([string]$StartPath = $PSScriptRoot)

    try {
        $current = Resolve-Path $StartPath -ErrorAction Stop
        while ($current -and -not (Test-Path (Join-Path $current "01_Config"))) {
            $parent = Split-Path $current
            if ($parent -eq $current) { return $null }  # Root erreicht
            $current = $parent
        }
        return $current
    }
    catch {
        Write-Host "❌ Fehler beim Ermitteln des Projekt-Roots: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# ------------------------------------------------------------
# 📁 Funktion: Get-PathMap
# Zweck:
#   Gibt ein Objekt mit allen relevanten Pfaden zurück.
# Rückgabe:
#   PSCustomObject mit Root-, Config-, Template-, Log- und Backup-Pfaden.
# ------------------------------------------------------------
function Get-PathMap {
    $root = Get-ProjectRoot
    if (-not $root) { throw "❌ Projekt-Root konnte nicht erkannt werden." }

    return [PSCustomObject]@{
        Root       = $root
        Config     = Join-Path $root "01_Config"
        Templates  = Join-Path $root "02_Templates"
        Scripts    = Join-Path $root "03_Scripts"
        Logs       = Join-Path $root "04_Logs"
        Backup     = Join-Path $root "05_Backup"
    }
}

# ------------------------------------------------------------
# 🔧 Hilfsfunktionen für gezielten Zugriff
# ------------------------------------------------------------
function Get-PathConfig    { (Get-PathMap).Config }
function Get-PathLogs      { (Get-PathMap).Logs }
function Get-PathBackup    { (Get-PathMap).Backup }
function Get-PathTemplates { (Get-PathMap).Templates }
