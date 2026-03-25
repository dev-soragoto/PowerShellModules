# PowerShell Modules

个人使用的一些powershell脚本

1. Claude
    - 封装 Claude Code Cli，增加 session、history、project、cache 等数据清理功能
2. Copilot
    - 封装 Github Copilot Cli，增加 session、log、history 等数据清理功能
3. FirewallManager
    - 方便地开关防火墙端口（支持 TCP / UDP）
4. Sudo
    - Sudo for Windows 的封装，执行时会自动加载 $PROFILE
5. WSLPortMapping
    - 映射 WSL 端口到 Windows，在 WSL 为 NAT 网络模式时使用，自动配置端口代理与防火墙规则

**Tips:**

若使用Git做同步,在使用前请运行,这样能保证你不会把敏感信息 commit 到仓库

```
git config core.hooksPath .githooks
```