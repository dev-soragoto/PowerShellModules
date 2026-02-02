# Copilot.psm1 - GitHub Copilot CLI Extension Module

<#
.SYNOPSIS
    Extends GitHub Copilot CLI with data cleanup capabilities

.DESCRIPTION
    Provides 'copilot rm' subcommand to clean session, log, and history data

.PARAMETER Command
    Main command (e.g., rm)

.PARAMETER SubCommand
    Subcommand (e.g., session, log, history)

.PARAMETER RemainingArgs
    Additional arguments

.EXAMPLE
    copilot rm session
    Remove Copilot session data

.EXAMPLE
    copilot rm log
    Remove Copilot logs

.EXAMPLE
    copilot rm history
    Remove command history
#>
function Invoke-Copilot {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Command,
        
        [Parameter(Position = 1)]
        [string]$SubCommand,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$RemainingArgs
    )
    
    # 处理 'rm' 命令 / Handle 'rm' command
    if ($Command -eq 'rm') {
        switch ($SubCommand) {
            'session' {
                Write-Host "Removing Copilot session data..." -ForegroundColor Yellow
                $SessionPath = "$env:USERPROFILE\.copilot\session-state"
                if (Test-Path $SessionPath) {
                    Remove-Item -Recurse -Force $SessionPath
                    Write-Host "Successfully removed session data" -ForegroundColor Green
                }
                else {
                    Write-Host "Session directory does not exist" -ForegroundColor Red
                }
                return
            }
            'log' {
                Write-Host "Removing Copilot log data..." -ForegroundColor Yellow
                $LogPath = "$env:USERPROFILE\.copilot\logs"
                if (Test-Path $LogPath) {
                    Remove-Item -Recurse -Force $LogPath
                    Write-Host "Successfully removed log data" -ForegroundColor Green
                }
                else {
                    Write-Host "Log directory does not exist" -ForegroundColor Red
                }
                return
            }
            'history' {
                Write-Host "Removing Copilot command history..." -ForegroundColor Yellow
                $HistoryPath = "$env:USERPROFILE\.copilot\command-history-state.json"
                if (Test-Path $HistoryPath) {
                    Remove-Item -Force $HistoryPath
                    Write-Host "Successfully removed command history" -ForegroundColor Green
                }
                else {
                    Write-Host "Command history file does not exist" -ForegroundColor Red
                }
                return
            }
            default {
                Write-Host "Unknown subcommand: $SubCommand" -ForegroundColor Red
                Write-Host "Available subcommands: session, log, history" -ForegroundColor Yellow
                return
            }
        }
    }
    
    # 对于其他命令，调用原始 copilot.exe / For other commands, call original copilot.exe
    try {
        $exePath = (Get-Command copilot -CommandType Application -ErrorAction Stop).Source
        & $exePath @args
    }
    catch {
        Write-Error "Failed to execute copilot command: $_"
    }
}

# 导出函数和别名 / Export function and alias
Set-Alias -Name copilot -Value Invoke-Copilot -Scope Global -Option AllScope -Force
Set-Alias -Name copilot.exe -Value Invoke-Copilot -Scope Global -Option AllScope -Force

Export-ModuleMember -Function Invoke-Copilot -Alias @('copilot', 'copilot.exe')
