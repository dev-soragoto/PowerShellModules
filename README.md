# PowerShell Modules

个人使用的一些powershell脚本

1. Copilot 
    - 封装 Github Copilot Cli 增加 session log 等删除
2. FirewallManager
    - 方便的开关端口
3. Sudo
    - Sudo for windows 的封装，会加载 $PROFILE
4. WSLPortMapping
    - 映射 WSL 端口到 windows ，在 WSL 为 NAT 网络模式时使用

**Tips:**

若使用Git做同步,在使用前请运行,这样能保证你不会把敏感信息 commit 到仓库

```
git config core.hooksPath .githooks
```