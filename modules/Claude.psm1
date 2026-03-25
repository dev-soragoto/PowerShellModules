# Claude.psm1 - Claude Code CLI Extension Module

<#
.SYNOPSIS
    Extends Claude Code CLI with data cleanup capabilities

.DESCRIPTION
    Provides 'claude rm' subcommand to clean session, history, projects, and cache data

.PARAMETER Command
    Main command (e.g., rm)

.PARAMETER SubCommand
    Subcommand (e.g., session, history, projects, cache, all)

.PARAMETER RemainingArgs
    Additional arguments

.EXAMPLE
    claude rm session
    Remove Claude Code session data

.EXAMPLE
    claude rm history
    Remove Claude Code command history

.EXAMPLE
    claude rm projects
    Remove Claude Code project conversation histories

.EXAMPLE
    claude rm cache
    Remove Claude Code cache data

.EXAMPLE
    claude rm all
    Remove all Claude Code local data
#>
function Invoke-Claude {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$SubCommand,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$RemainingArgs
    )

    $ClaudeHome = "$env:USERPROFILE\.claude"

    # 处理 'rm' 命令 / Handle 'rm' command
    if ($Command -eq 'rm') {
        switch ($SubCommand) {
            'session' {
                Write-Host "Removing Claude Code session data..." -ForegroundColor Yellow
                $Path = "$ClaudeHome\sessions"
                if (Test-Path $Path) {
                    Remove-Item -Recurse -Force "$Path\*"
                    Write-Host "Successfully removed session data" -ForegroundColor Green
                }
                else {
                    Write-Host "Sessions directory does not exist" -ForegroundColor Red
                }
                return
            }
            'history' {
                Write-Host "Removing Claude Code command history..." -ForegroundColor Yellow
                $Path = "$ClaudeHome\history.jsonl"
                if (Test-Path $Path) {
                    Remove-Item -Force $Path
                    Write-Host "Successfully removed command history" -ForegroundColor Green
                }
                else {
                    Write-Host "History file does not exist" -ForegroundColor Red
                }
                return
            }
            'projects' {
                Write-Host "Removing Claude Code project conversation histories..." -ForegroundColor Yellow
                $Path = "$ClaudeHome\projects"
                if (Test-Path $Path) {
                    Remove-Item -Recurse -Force "$Path\*"
                    Write-Host "Successfully removed project histories" -ForegroundColor Green
                }
                else {
                    Write-Host "Projects directory does not exist" -ForegroundColor Red
                }
                return
            }
            'cache' {
                Write-Host "Removing Claude Code cache data..." -ForegroundColor Yellow
                $Path = "$ClaudeHome\cache"
                if (Test-Path $Path) {
                    Remove-Item -Recurse -Force "$Path\*"
                    Write-Host "Successfully removed cache data" -ForegroundColor Green
                }
                else {
                    Write-Host "Cache directory does not exist" -ForegroundColor Red
                }
                return
            }
            'all' {
                Write-Host "Removing all Claude Code local data..." -ForegroundColor Yellow
                $Targets = @(
                    @{ Path = "$ClaudeHome\sessions\*"; Label = "sessions" },
                    @{ Path = "$ClaudeHome\history.jsonl"; Label = "history" },
                    @{ Path = "$ClaudeHome\projects\*"; Label = "projects" },
                    @{ Path = "$ClaudeHome\cache\*"; Label = "cache" }
                )
                foreach ($Target in $Targets) {
                    if (Test-Path $Target.Path) {
                        Remove-Item -Recurse -Force $Target.Path
                        Write-Host "  Removed $($Target.Label)" -ForegroundColor Green
                    }
                    else {
                        Write-Host "  Skipped $($Target.Label) (not found)" -ForegroundColor DarkGray
                    }
                }
                Write-Host "Done." -ForegroundColor Green
                return
            }
            default {
                Write-Host "Unknown subcommand: $SubCommand" -ForegroundColor Red
                Write-Host "Available subcommands: session, history, projects, cache, all" -ForegroundColor Yellow
                return
            }
        }
    }

    # 对于其他命令，调用原始 claude.exe / For other commands, call original claude.exe
    try {
        $exePath = (Get-Command claude -CommandType Application -ErrorAction Stop).Source
        & $exePath $Command $SubCommand @RemainingArgs
    }
    catch {
        Write-Error "Failed to execute claude command: $_"
    }
}

# 导出函数和别名 / Export function and alias
Set-Alias -Name claude -Value Invoke-Claude -Scope Global -Option AllScope -Force

Export-ModuleMember -Function Invoke-Claude -Alias @('claude')

