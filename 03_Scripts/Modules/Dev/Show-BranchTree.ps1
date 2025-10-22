# ============================================================
# 🧩 Modul: Show-BranchTree.ps1
# Version: DEV_V1.0.0
# Zweck:   Zeigt alle lokalen & Remote-Branches mit Abhängigkeiten,
#          Merge-Status und Commit-Stand in Tabellen- und Baumform.
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# 🧭 ManifestHint:
#   ExportFunctions: Show-BranchTree
#   Description: Listet alle Git-Branches mit Herkunft, Merges und Status.
#   Category: Utility
#   Tags: Git, Branch, Tree, DevTools
#   Dependencies: (none)
# ============================================================

function Show-BranchTree {
    [CmdletBinding()]
    param(
        [switch]$VerboseOutput
    )

    try {
        # ------------------------------------------------------------
        # 📁 Projektpfad ermitteln
        # ------------------------------------------------------------
        $repoPath = Get-Location
        Write-Host "`n📁 Git Repository: $repoPath" -ForegroundColor Cyan

        # Prüfen, ob Git verfügbar ist
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "❌ Git ist nicht installiert oder nicht im PATH." -ForegroundColor Red
            return
        }

        # ------------------------------------------------------------
        # 🔄 Daten sammeln
        # ------------------------------------------------------------
        $branches = git branch -a --sort=-committerdate | ForEach-Object { $_.Trim() }
        $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
        $lastCommit = git log -1 --pretty=format:"%h %cr - %s"

        Write-Host "`n🧩 Aktueller Branch: $currentBranch" -ForegroundColor Green
        Write-Host "🕒 Letzter Commit:   $lastCommit" -ForegroundColor DarkGray

        # ------------------------------------------------------------
        # 🧱 Branch-Struktur erzeugen
        # ------------------------------------------------------------
        $branchInfo = @()
        foreach ($branch in $branches) {
            $bName = $branch.Replace("*", "").Trim()
            $commit = git log -1 $bName --pretty=format:"%h" 2>$null
            $upstream = git rev-parse --abbrev-ref "$bName@{upstream}" 2>$null
            $merged = git branch --contains $bName | Select-String "main|dev" | ForEach-Object { $_.ToString().Trim() }

            $branchInfo += [PSCustomObject]@{
                Branch     = $bName
                Upstream   = if ($upstream) { $upstream } else { "-" }
                Commit     = if ($commit) { $commit } else { "-" }
                MergedInto = if ($merged) { ($merged -join ', ') } else { "-" }
                IsCurrent  = $bName -eq $currentBranch
            }
        }

        # ------------------------------------------------------------
        # 📊 Ausgabe
        # ------------------------------------------------------------
        Write-Host "`n🪶 Branch-Übersicht:" -ForegroundColor Yellow
        Write-Host "──────────────────────────────────────────────"
        $branchInfo | Sort-Object Branch | Format-Table Branch, Upstream, Commit, MergedInto -AutoSize

        # ------------------------------------------------------------
        # 🌳 Baumansicht (optional)
        # ------------------------------------------------------------
        if ($VerboseOutput) {
            Write-Host "`n🌳 Branch-Hierarchie:" -ForegroundColor Yellow
            Write-Host "──────────────────────────────────────────────"

            git log --graph --decorate --oneline --all | ForEach-Object {
                $line = $_
                if ($line -match $currentBranch) {
                    Write-Host $line -ForegroundColor Green
                }
                else {
                    Write-Host $line -ForegroundColor DarkGray
                }
            }
        }

        Write-Host "`n✅ BranchTree abgeschlossen.`n" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Fehler in Show-BranchTree: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# ▶️ Automatischer Start bei Direktausführung
# ------------------------------------------------------------
if ($MyInvocation.InvocationName -eq "&" -or
    ($MyInvocation.MyCommand.Path -eq $PSCommandPath -and
     $MyInvocation.InvocationName -notmatch "Show-BranchTree")) {

    Show-BranchTree -VerboseOutput
}
