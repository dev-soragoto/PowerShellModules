# WSLPortMapping.psm1 - WSL Port Mapping Management Module

<#
.SYNOPSIS
    Add WSL port mapping to forward Windows ports to WSL

.DESCRIPTION
    Automatically retrieves WSL IP address, creates port mappings (IPv4/IPv6), and configures firewall rules

.PARAMETER Port
    Target port in WSL

.PARAMETER ListenPort
    Windows listening port (defaults to Port)

.PARAMETER DisableIPv6
    Disable IPv6 mapping

.EXAMPLE
    Add-WSLPortMapping -Port 8080
    Map Windows:8080 -> WSL:8080

.EXAMPLE
    Add-WSLPortMapping -Port 3000 -ListenPort 80
    Map Windows:80 -> WSL:3000

.EXAMPLE
    Add-WSLPortMapping -Port 8080 -DisableIPv6
    Create IPv4 mapping only
#>
function Add-WSLPortMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$Port,
        
        [Parameter(Position = 1)]
        [int]$ListenPort,
        
        [Parameter()]
        [switch]$DisableIPv6
    )
    
    # 如果未指定监听端口，则使用相同的端口 / Use same port if not specified
    if (-not $ListenPort) {
        $ListenPort = $Port
    }
    
    # 获取 WSL IP 地址（从 eth0 网卡获取）/ Get WSL IP address from eth0
    try {
        $WSLIp = wsl ip -4 addr show eth0 | Select-String "inet\s" | ForEach-Object { 
            $_.Line.Trim().Split()[1].Split('/')[0] 
        }
        
        if (-not $WSLIp) {
            throw "Unable to retrieve WSL IP address"
        }
        
        Write-Host "WSL IP Address: $WSLIp" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to get WSL IP: $_"
        return
    }
    
    # 检查是否需要以管理员身份运行 / Check for administrator privileges
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $IsAdmin) {
        Write-Host "This operation requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
        return
    }
    
    try {
        # 创建 IPv4 到 IPv4 端口映射 / Create IPv4 to IPv4 port mapping
        netsh interface portproxy add v4tov4 listenport=$ListenPort listenaddr=0.0.0.0 connectport=$Port connectaddress=$WSLIp | Out-Null
        Write-Host "IPv4 Port mapping added: 0.0.0.0:${ListenPort} -> ${WSLIp}:${Port}" -ForegroundColor Green
        
        # 尝试创建 IPv6 到 IPv4 端口映射（除非明确禁用）/ Create IPv6 to IPv4 mapping (unless disabled)
        if (-not $DisableIPv6) {
            netsh interface portproxy add v6tov4 listenport=$ListenPort listenaddr=:: connectport=$Port connectaddress=$WSLIp | Out-Null
            Write-Host "IPv6 Port mapping added: [::]:${ListenPort} -> ${WSLIp}:${Port}" -ForegroundColor Green
        }
        else {
            Write-Host "IPv6 mapping disabled (skipped)" -ForegroundColor Yellow
        }
        
        # 添加防火墙规则 - TCP / Add firewall rule - TCP
        $FirewallRuleTCP = "WSL Port Mapping - TCP $ListenPort"
        Remove-NetFirewallRule -DisplayName $FirewallRuleTCP -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName $FirewallRuleTCP -Direction Inbound -LocalPort $ListenPort -Protocol TCP -Action Allow | Out-Null
        Write-Host "Firewall rule added for TCP port $ListenPort" -ForegroundColor Green
        
        # 添加防火墙规则 - UDP / Add firewall rule - UDP
        $FirewallRuleUDP = "WSL Port Mapping - UDP $ListenPort"
        Remove-NetFirewallRule -DisplayName $FirewallRuleUDP -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName $FirewallRuleUDP -Direction Inbound -LocalPort $ListenPort -Protocol UDP -Action Allow | Out-Null
        Write-Host "Firewall rule added for UDP port $ListenPort" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create port mapping: $_"
    }
}

<#
.SYNOPSIS
    移除 WSL 端口映射和防火墙规则
    Remove WSL port mapping and firewall rules

.DESCRIPTION
    移除指定端口或所有 WSL 端口映射及其防火墙规则
    Remove specified port or all WSL port mappings and their firewall rules

.PARAMETER ListenPort
    要移除的监听端口（不指定则移除所有）/ Listening port to remove (omit to remove all)

.EXAMPLE
    Remove-WSLPortMapping -ListenPort 8080
    移除端口 8080 的映射 / Remove mapping for port 8080

.EXAMPLE
    Remove-WSLPortMapping
    移除所有 WSL 端口映射 / Remove all WSL port mappings
#>
function Remove-WSLPortMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [int]$ListenPort
    )
    
    # 检查是否需要以管理员身份运行 / Check for administrator privileges
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $IsAdmin) {
        Write-Host "This operation requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
        return
    }
    
    # 如果没有指定端口，删除所有 WSL 端口映射 / Remove all WSL port mappings if not specified
    if (-not $ListenPort) {
        Write-Host "Removing all WSL port mappings..." -ForegroundColor Yellow
        
        # 从防火墙规则中收集端口（只删除我们创建的 WSL 映射）/ Collect ports from firewall rules
        $FirewallRules = Get-NetFirewallRule -DisplayName "WSL Port Mapping - TCP *" -ErrorAction SilentlyContinue
        $Ports = @()
        
        foreach ($Rule in $FirewallRules) {
            if ($Rule.DisplayName -match 'WSL Port Mapping - TCP (\d+)') {
                $Port = [int]$Matches[1]
                if ($Ports -notcontains $Port) {
                    $Ports += $Port
                }
            }
        }
        
        if ($Ports.Count -eq 0) {
            Write-Host "No WSL port mappings found" -ForegroundColor Red
            return
        }
        
        Write-Host "Found $($Ports.Count) WSL port mapping(s): $($Ports -join ', ')" -ForegroundColor Cyan
        
        # 删除每个端口的防火墙规则和映射 / Remove firewall rules and mappings for each port
        foreach ($Port in $Ports) {
            try {
                # 删除防火墙规则 / Remove firewall rules
                Remove-NetFirewallRule -DisplayName "WSL Port Mapping - TCP $Port" -ErrorAction SilentlyContinue
                Remove-NetFirewallRule -DisplayName "WSL Port Mapping - UDP $Port" -ErrorAction SilentlyContinue
                Write-Host "Firewall rules removed for port $Port" -ForegroundColor Green
                
                # 删除端口映射（IPv4 和 IPv6）/ Remove port mappings (IPv4 and IPv6)
                netsh interface portproxy delete v4tov4 listenport=$Port listenaddr=0.0.0.0 2>&1 | Out-Null
                Write-Host "IPv4 port mapping removed for port $Port" -ForegroundColor Green
                
                netsh interface portproxy delete v6tov4 listenport=$Port listenaddr=:: 2>&1 | Out-Null
                Write-Host "IPv6 port mapping removed for port $Port" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to remove mapping for port ${Port}: $_"
            }
        }
        
        Write-Host "All WSL port mappings removed successfully" -ForegroundColor Green
    }
    else {
        # 删除指定端口的映射 / Remove mapping for specific port
        try {
            # 删除端口映射（IPv4 和 IPv6）/ Remove port mappings (IPv4 and IPv6)
            netsh interface portproxy delete v4tov4 listenport=$ListenPort listenaddr=0.0.0.0 2>&1 | Out-Null
            Write-Host "IPv4 port mapping removed for port $ListenPort" -ForegroundColor Green
            
            netsh interface portproxy delete v6tov4 listenport=$ListenPort listenaddr=:: 2>&1 | Out-Null
            Write-Host "IPv6 port mapping removed for port $ListenPort" -ForegroundColor Green
            
            # 删除防火墙规则 / Remove firewall rules
            Remove-NetFirewallRule -DisplayName "WSL Port Mapping - TCP $ListenPort" -ErrorAction SilentlyContinue
            Write-Host "Firewall rule removed for TCP port $ListenPort" -ForegroundColor Green
            
            Remove-NetFirewallRule -DisplayName "WSL Port Mapping - UDP $ListenPort" -ErrorAction SilentlyContinue
            Write-Host "Firewall rule removed for UDP port $ListenPort" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to remove mapping for port ${ListenPort}: $_"
        }
    }
}

# 导出函数 / Export functions
Export-ModuleMember -Function Add-WSLPortMapping, Remove-WSLPortMapping
