# Fedora VM 自动化部署脚本

这个项目提供了自动化脚本，用于在 macOS 上使用 VirtualBox 和 Vagrant 部署 Fedora 虚拟机。

## 前提条件

- macOS 操作系统
- VirtualBox 7.1.10 或更高版本
- Vagrant 最新版本
- 至少 20GB 可用磁盘空间
- 稳定的网络连接

## 快速开始

1. 克隆此仓库：
   ```bash
   git clone <repository-url>
   cd fedora-vm
   ```

2. 给脚本添加执行权限：
   ```bash
   chmod +x setup.sh
   ```

3. 运行自动化脚本：
   ```bash
   ./setup.sh
   ```

## 脚本功能

脚本会自动执行以下操作：

1. 检查必要的软件（VirtualBox 和 Vagrant）是否已安装
2. 下载 Fedora Server ISO 文件并验证其完整性
3. 创建并配置 VirtualBox 虚拟机
4. 创建 Vagrantfile 配置文件

## 手动步骤

脚本执行完成后，需要手动完成以下步骤：

1. 启动虚拟机并完成 Fedora 安装：
   - 使用 VirtualBox 启动虚拟机
   - 按照安装向导完成 Fedora 安装
   - 创建 vagrant 用户（用户名：vagrant，密码：vagrant）
   - 确保 vagrant 用户具有 sudo 权限

2. 安装完成后，打包虚拟机为 Vagrant box：
   ```bash
   vagrant package --base fedora41-vagrant --output fedora41.box
   ```

3. 添加 box 到 Vagrant：
   ```bash
   vagrant box add fedora41 fedora41.box
   ```

4. 启动虚拟机：
   ```bash
   vagrant up
   ```

## 网络配置

- 虚拟机使用 DHCP 自动获取 IP 地址
- 私有网络配置在 192.168.56.0/24 网段
- 可以通过 `vagrant ssh` 连接到虚拟机

## 故障排除

1. 如果遇到 VirtualBox 权限问题：
   - 检查系统偏好设置 > 安全性与隐私 > 通用
   - 允许 Oracle 软件运行

2. 如果网络连接失败：
   - 检查 VirtualBox 网络设置
   - 确保 Host-Only 网络适配器已启用

3. 如果 Vagrant 命令失败：
   - 运行 `VAGRANT_LOG=info vagrant up` 查看详细日志
   - 检查 VirtualBox 和 Vagrant 版本兼容性

## 注意事项

- 确保有足够的磁盘空间（至少 20GB）
- 保持稳定的网络连接
- 建议使用 Fedora Server 版本以获得最佳性能
- 安装过程中请勿关闭虚拟机

## 许可证

MIT License 