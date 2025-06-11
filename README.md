# Fedora VM 自动化安装工具

这是一个用于自动化安装 Fedora 虚拟机的工具脚本。该脚本可以帮助您快速设置和配置 Fedora 虚拟机环境，支持不同架构（x86_64 和 aarch64）的安装。

## 功能特点

- 支持 x86_64 和 aarch64 架构
- 自动下载和验证 Fedora ISO 文件
- 自动创建和配置 VirtualBox 虚拟机
- 自动生成 Vagrant 配置文件
- 支持代理设置
- 详细的进度和错误提示

## 系统要求

- VirtualBox
- Vagrant
- Bash 环境
- 足够的磁盘空间（建议至少 50GB）
- 稳定的网络连接

## 安装步骤

1. 确保已安装 VirtualBox 和 Vagrant
2. 克隆或下载此仓库
3. 给脚本添加执行权限：
   ```bash
   chmod +x setup.sh postinstall.sh
   ```

## 使用方法

### 基本用法

1. 运行 setup.sh 创建虚拟机：
   ```bash
   ./setup.sh
   ```

2. 完成 Fedora 安装后，运行 postinstall.sh 进行后续配置：
   ```bash
   ./postinstall.sh
   ```

### 高级用法

setup.sh 参数说明：
```bash
./setup.sh -p <proxy_url> -a <architecture>
```

参数说明：
- `-p`: 设置代理服务器（默认：http://localhost:7890）
- `-a`: 设置目标架构（可选值：x86_64, aarch64，默认：x86_64）
- `-h`: 显示帮助信息

postinstall.sh 会自动检测系统架构并执行相应的配置。

示例：
```bash
# 使用自定义代理下载 ARM 架构的 Fedora
./setup.sh -p http://your-proxy:port -a aarch64

# 仅指定架构
./setup.sh -a aarch64

# 仅指定代理
./setup.sh -p http://your-proxy:port
```

## 完整安装流程

### 1. 初始设置

运行 setup.sh 脚本：

对于 ARM Mac：
```bash
./setup.sh -a aarch64
```

对于 x86_64 Mac：
```bash
./setup.sh -a x86_64
# 或者直接运行（因为 x86_64 是默认值）
./setup.sh
```

### 2. 安装 Fedora

1. 打开 VirtualBox
2. 启动名为 "fedora41-vagrant" 的虚拟机
3. 按照 Fedora 安装向导完成安装：
   - 选择语言和键盘布局
   - 配置网络（建议使用 DHCP）
   - 创建用户（建议创建 vagrant 用户）
   - 设置 root 密码
   - 完成安装

### 3. 配置 Vagrant

安装完成后，在虚拟机中执行以下命令：

```bash
# 安装 Vagrant 公钥
mkdir -p /home/vagrant/.ssh
curl -k https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub > /home/vagrant/.ssh/authorized_keys
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# 配置 sudo 权限
echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant
```

### 4. 运行自动化配置脚本

在主机上运行 postinstall.sh 脚本，它会自动执行以下操作：
- 创建 Host-Only 网络接口
- 打包虚拟机
- 添加 box
- 启动虚拟机

```bash
./postinstall.sh
```

脚本会自动检测系统架构并执行相应的配置。

## 注意事项

- 对于 ARM 架构的 Mac（如 M1/M2/M3），必须使用 `-a aarch64` 参数
- 对于 Intel 架构的 Mac，可以使用 `-a x86_64` 参数或直接使用默认值
- 确保有足够的磁盘空间和内存
- 下载过程可能需要较长时间，取决于网络状况
- 如果使用代理，请确保代理服务器可用
- 必须创建 vboxnet0 网络接口，否则虚拟机网络将无法正常工作
- 确保 vagrant 用户具有正确的权限和 SSH 配置

## 故障排除

### 常见问题

1. "Interface vboxnet0 doesn't seem to exist"
   - 运行 `VBoxManage hostonlyif create` 创建接口
   - 运行 `VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0` 配置接口

2. "Box 'fedora41' could not be found"
   - 确保已完成 Fedora 安装
   - 确保已正确打包和添加 box
   - 检查 box 文件路径是否正确
   - 使用 `vagrant box list` 确认 box 是否已添加
   - 如果问题仍然存在，尝试使用完整路径：
     ```bash
     vagrant box add --name fedora41 --provider virtualbox --architecture aarch64 "$(pwd)/fedora41.box"
     ```

3. SSH 连接失败
   - 检查 vagrant 用户的 SSH 配置
   - 确保 authorized_keys 文件权限正确

4. 网络连接问题
   - 检查 VirtualBox 网络设置
   - 确保 vboxnet0 接口配置正确

## 许可证

MIT License 