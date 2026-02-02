# ============================================================
# $PROFILE 原始配置
# ============================================================

oh-my-posh init pwsh --config 'avit' | Invoke-Expression
Import-Module posh-git

# ============================================================
# 加载自定义模块 / Load Custom Modules
# ============================================================

# 修改此路径为你的模块存储位置 / Change this path to your module storage location
$ModulesPath = "C:\Users\soragoto\OneDrive\PowerShellModules\modules"

if (-not (Test-Path $ModulesPath)) {
    Write-Warning "Modules directory not found: $ModulesPath"
    Write-Warning "Please update `$ModulesPath variable or create the directory"
}
else {
    # 临时添加模块路径到 PSModulePath / Temporarily add modules path to PSModulePath
    if ($env:PSModulePath -notlike "*$ModulesPath*") {
        $env:PSModulePath = "$ModulesPath;$env:PSModulePath"
    }
    
    Import-Module "$ModulesPath\Sudo.psm1" -ErrorAction Stop
    Import-Module "$ModulesPath\Copilot.psm1" -ErrorAction Stop
    Import-Module "$ModulesPath\WSLPortMapping.psm1" -ErrorAction Stop
    Import-Module "$ModulesPath\FirewallManager.psm1" -ErrorAction Stop
}
