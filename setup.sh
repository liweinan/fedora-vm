#!/bin/bash

# 设置错误时退出（当任何命令返回非零状态时立即退出）
set -e

# 默认代理设置
PROXY="http://localhost:7890"

# 解析命令行参数
while getopts "p:" opt; do
  case $opt in
    p)
      PROXY="$OPTARG"
      ;;
    \?)
      echo "无效的选项: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# 颜色定义（用于美化输出）
RED='\033[0;31m'    # 红色，用于错误信息
GREEN='\033[0;32m'  # 绿色，用于成功信息
YELLOW='\033[1;33m' # 黄色，用于警告信息
NC='\033[0m'        # 无颜色，用于重置颜色

# 打印带颜色的信息函数
# 用法：info "你的消息"
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# 打印带颜色的警告信息
# 用法：warn "你的警告消息"
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 打印带颜色的错误信息
# 用法：error "你的错误消息"
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必要的命令是否存在
# 检查 VirtualBox 和 Vagrant 是否已安装
check_requirements() {
    info "检查必要的软件..."
    
    # 检查 VBoxManage 命令是否存在（VirtualBox 是否安装）
    if ! command -v VBoxManage &> /dev/null; then
        error "VirtualBox 未安装"
        exit 1
    fi
    
    # 检查 vagrant 命令是否存在（Vagrant 是否安装）
    if ! command -v vagrant &> /dev/null; then
        error "Vagrant 未安装"
        exit 1
    fi
    
    info "所有必要的软件已安装"
}

# 下载 Fedora ISO 文件
# 包括下载和验证文件完整性
download_iso() {
    info "开始下载 Fedora ISO..."
    info "使用代理: $PROXY"
    
    # 创建下载目录（如果不存在）
    mkdir -p downloads
    
    # 下载 Fedora Server ISO（如果文件不存在）
    if [ ! -f "downloads/Fedora-Server-dvd-x86_64-41-1.4.iso" ]; then
        curl -x "$PROXY" -L "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41-1.4.iso" \
            -o "downloads/Fedora-Server-dvd-x86_64-41-1.4.iso"
    else
        info "ISO 文件已存在，跳过下载"
    fi
    
    # 下载并验证 SHA256 校验和
    info "验证 ISO 文件完整性..."
    curl -x "$PROXY" -L "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-41-1.4-x86_64-CHECKSUM" \
        -o "downloads/CHECKSUM"
    
    # 进入下载目录并验证文件
    cd downloads
    if ! shasum -a 256 -c CHECKSUM 2>&1 | grep -q "Fedora-Server-dvd-x86_64-41-1.4.iso: OK"; then
        error "ISO 文件校验失败"
        exit 1
    fi
    cd ..
    
    info "ISO 文件下载和验证完成"
}

# 创建 VirtualBox 虚拟机
# 配置虚拟机的硬件和网络设置
create_vm() {
    info "创建 VirtualBox 虚拟机..."
    
    # 检查并删除已存在的同名虚拟机
    if VBoxManage list vms | grep -q "fedora41-vagrant"; then
        warn "虚拟机已存在，正在删除..."
        VBoxManage unregistervm "fedora41-vagrant" --delete
    fi
    
    # 创建新的虚拟机并设置基本参数
    VBoxManage createvm --name "fedora41-vagrant" --ostype "Fedora_64" --register
    VBoxManage modifyvm "fedora41-vagrant" --memory 2048 --cpus 2
    VBoxManage modifyvm "fedora41-vagrant" --nic1 nat
    VBoxManage modifyvm "fedora41-vagrant" --nic2 hostonly --hostonlyadapter1 vboxnet0
    
    # 创建并配置虚拟硬盘
    VBoxManage createhd --filename "fedora41-vagrant.vdi" --size 40000
    VBoxManage storagectl "fedora41-vagrant" --name "SATA Controller" --add sata --controller IntelAhci
    VBoxManage storageattach "fedora41-vagrant" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "fedora41-vagrant.vdi"
    
    # 配置 ISO 安装介质
    VBoxManage storagectl "fedora41-vagrant" --name "IDE Controller" --add ide
    VBoxManage storageattach "fedora41-vagrant" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "downloads/Fedora-Server-dvd-x86_64-41-1.4.iso"
    
    info "虚拟机创建完成"
}

# 创建 Vagrantfile 配置文件
# 配置 Vagrant 虚拟机的网络和资源设置
create_vagrantfile() {
    info "创建 Vagrantfile..."
    
    # 创建 Vagrantfile 并写入配置
    cat > Vagrantfile << 'EOF'
Vagrant.configure("2") do |config|
  # 使用自定义的 Fedora box
  config.vm.box = "fedora41"
  
  # 配置私有网络，使用 DHCP
  config.vm.network "private_network", type: "dhcp"
  
  # 配置 VirtualBox 提供者
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"  # 分配 2GB 内存
    vb.cpus = 2         # 分配 2 个 CPU 核心
  end
  
  # 配置共享文件夹
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
end
EOF
    
    info "Vagrantfile 创建完成"
}

# 显示使用帮助
show_help() {
    echo "用法: $0 [-p proxy_url]"
    echo "选项:"
    echo "  -p proxy_url    设置代理服务器 (默认: http://localhost:7890)"
    echo "  -h             显示此帮助信息"
    exit 0
}

# 主函数：执行所有步骤
main() {
    info "开始自动化安装流程..."
    
    # 按顺序执行各个步骤
    check_requirements    # 检查环境
    download_iso         # 下载 ISO
    create_vm           # 创建虚拟机
    create_vagrantfile  # 创建配置文件
    
    # 显示后续步骤说明
    info "基础环境设置完成"
    info "请按照以下步骤继续："
    info "1. 启动虚拟机并完成 Fedora 安装"
    info "2. 安装完成后，运行 'vagrant package' 命令打包 box"
    info "3. 使用 'vagrant box add' 添加 box"
    info "4. 运行 'vagrant up' 启动虚拟机"
}

# 处理帮助参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
fi

# 执行主函数
main 