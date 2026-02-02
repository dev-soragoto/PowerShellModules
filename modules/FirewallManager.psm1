# FirewallManager.psm1 - Firewall Port Management Module

<#
.SYNOPSIS
    Open firewall port for TCP and UDP access

.DESCRIPTION
    Adds inbound firewall rules for the specified port, supporting both TCP and UDP protocols

.PARAMETER Port
    Port number to open

.EXAMPLE
    open-port -Port 8080
    Open port 8080

.EXAMPLE
    open-port 3000
    Open port 3000
#>
function Open-FirewallPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$Port
    )
    
    # 检查是否以管理员身份运行 / Check for administrator privileges
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $IsAdmin) {
        Write-Host "This operation requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
        return
    }
    
    try {
        # 定义防火墙规则名称 / Define firewall rule names
        $TCPRuleName = "open-port TCP $Port"
        $UDPRuleName = "open-port UDP $Port"
        
        # 移除现有规则（如果存在）/ Remove existing rules if they exist
        Remove-NetFirewallRule -DisplayName $TCPRuleName -ErrorAction SilentlyContinue
        Remove-NetFirewallRule -DisplayName $UDPRuleName -ErrorAction SilentlyContinue
        
        # 添加 TCP 规则 / Add TCP rule
        New-NetFirewallRule -DisplayName $TCPRuleName -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow | Out-Null
        
        # 添加 UDP 规则 / Add UDP rule
        New-NetFirewallRule -DisplayName $UDPRuleName -Direction Inbound -LocalPort $Port -Protocol UDP -Action Allow | Out-Null
        
        Write-Host "Firewall rules added for port $Port (TCP/UDP)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to open port ${Port}: $_"
    }
}

<#
.SYNOPSIS
    Close firewall port by removing rules

.DESCRIPTION
    Removes firewall rules created by open-port. Omit port to remove all open-port rules

.PARAMETER Port
    Port number to close (omit to close all)

.EXAMPLE
    close-port -Port 8080
    Close port 8080

.EXAMPLE
    close-port
    Close all ports opened by open-port
#>
function Close-FirewallPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [int]$Port
    )
    
    # 检查是否以管理员身份运行 / Check for administrator privileges
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $IsAdmin) {
        Write-Host "This operation requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
        return
    }
    
    # 如果没有指定端口，删除所有由 open-port 创建的规则 / Remove all rules if not specified
    if (-not $Port) {
        Write-Host "Removing all firewall rules created by open-port..." -ForegroundColor Yellow
        
        # 获取所有匹配 open-port 模式的规则 / Get all rules matching the open-port pattern
        $TCPRules = @(Get-NetFirewallRule -DisplayName "open-port TCP *" -ErrorAction SilentlyContinue)
        $UDPRules = @(Get-NetFirewallRule -DisplayName "open-port UDP *" -ErrorAction SilentlyContinue)
        
        $AllRules = $TCPRules + $UDPRules
        
        if ($AllRules.Count -eq 0) {
            Write-Host "No rules created by open-port found" -ForegroundColor Yellow
            return
        }
        
        # 提取端口号并删除规则 / Extract port numbers and remove rules
        $Ports = @()
        foreach ($Rule in $AllRules) {
            if ($Rule.DisplayName -match 'open-port (TCP|UDP) (\d+)') {
                $PortNum = [int]$Matches[2]
                if ($Ports -notcontains $PortNum) {
                    $Ports += $PortNum
                }
            }
        }
        
        Write-Host "Found $($Ports.Count) open port(s): $($Ports -join ', ')" -ForegroundColor Cyan
        
        # 删除每个端口的规则 / Remove rules for each port
        foreach ($P in $Ports) {
            try {
                Remove-NetFirewallRule -DisplayName "open-port TCP $P" -ErrorAction SilentlyContinue
                Remove-NetFirewallRule -DisplayName "open-port UDP $P" -ErrorAction SilentlyContinue
                Write-Host "Firewall rules removed for port $P (TCP/UDP)" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to remove rules for port ${P}: $_"
            }
        }
        
        Write-Host "All firewall rules created by open-port have been removed" -ForegroundColor Green
    }
    else {
        # 删除指定端口的规则 / Remove rules for specific port
        try {
            Remove-NetFirewallRule -DisplayName "open-port TCP $Port" -ErrorAction SilentlyContinue
            Remove-NetFirewallRule -DisplayName "open-port UDP $Port" -ErrorAction SilentlyContinue
            Write-Host "Firewall rules removed for port $Port (TCP/UDP)" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to close port ${Port}: $_"
        }
    }
}

# 导出函数和别名 / Export functions and aliases
Export-ModuleMember -Function Open-FirewallPort, Close-FirewallPort 
