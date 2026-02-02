# Sudo.psm1 - Elevated Command Execution Module

<#
.SYNOPSIS
    Execute commands with elevated privileges and auto-load PowerShell Profile

.DESCRIPTION
    Wraps sudo.exe to automatically load Profile when executing commands

.PARAMETER Command
    The command and arguments to execute

.EXAMPLE
    sudo Get-Service
#>
function Invoke-ElevatedCommand {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Command
    )
    
    try {
        $CommandString = $Command -join ' '
        $ProfilePath = $PROFILE
        $ScriptBlock = ". '$ProfilePath'; $CommandString"
        
        # 获取 sudo.exe 的实际路径 / Get the actual path of sudo.exe
        $exePath = (Get-Command sudo -CommandType Application -ErrorAction Stop).Source
        
        # 使用 sudo.exe 执行命令 / Execute command with sudo.exe
        & $exePath pwsh -NoProfile -Command $ScriptBlock
    }
    catch {
        Write-Error "Failed to execute elevated command: $_"
    }
}

# 创建全局别名并强制覆盖 / Create global aliases with force override
Set-Alias -Name sudo -Value Invoke-ElevatedCommand -Scope Global -Option AllScope -Force
Set-Alias -Name sudo.exe -Value Invoke-ElevatedCommand -Scope Global -Option AllScope -Force

# 导出函数和别名 / Export function and aliases
Export-ModuleMember -Function Invoke-ElevatedCommand -Alias @('sudo', 'sudo.exe')
