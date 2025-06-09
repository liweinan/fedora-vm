#!/bin/bash

# 设置错误时退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 打印带颜色的信息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必要的命令是否存在
check_requirements() {
    info "检查必要的软件..."
    
    if ! command -v VBoxManage &> /dev/null; then
        error "VirtualBox 未安装"
        exit 1
    fi
    
    if ! command -v vagrant &> /dev/null; then
        error "Vagrant 未安装"
        exit 1
    fi
    
    info "所有必要的软件已安装"
}

# 下载 Fedora ISO
download_iso() {
    info "开始下载 Fedora ISO..."
    
    # 创建下载目录
    mkdir -p downloads
    
    # 下载 Fedora Server ISO
    if [ ! -f "downloads/Fedora-Server-dvd-x86_64-41-1.4.iso" ]; then
        curl -L "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41-1.4.iso" \
            -o "downloads/Fedora-Server-dvd-x86_64-41-1.4.iso"
    else
        info "ISO 文件已存在，跳过下载"
    fi
    
    # 验证 SHA256
    info "验证 ISO 文件完整性..."
    curl -L "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-41-1.4-x86_64-CHECKSUM" \
        -o "downloads/CHECKSUM"
    
    cd downloads
    if ! shasum -a 256 -c CHECKSUM 2>&1 | grep -q "Fedora-Server-dvd-x86_64-41-1.4.iso: OK"; then
        error "ISO 文件校验失败"
        exit 1
    fi
    cd ..
    
    info "ISO 文件下载和验证完成"
}

# 创建 VirtualBox 虚拟机
create_vm() {
    info "创建 VirtualBox 虚拟机..."
    
    # 检查虚拟机是否已存在
    if VBoxManage list vms | grep -q "fedora41-vagrant"; then
        warn "虚拟机已存在，正在删除..."
        VBoxManage unregistervm "fedora41-vagrant" --delete
    fi
    
    # 创建新的虚拟机
    VBoxManage createvm --name "fedora41-vagrant" --ostype "Fedora_64" --register
    VBoxManage modifyvm "fedora41-vagrant" --memory 2048 --cpus 2
    VBoxManage modifyvm "fedora41-vagrant" --nic1 nat
    VBoxManage modifyvm "fedora41-vagrant" --nic2 hostonly --hostonlyadapter1 vboxnet0
    
    # 创建虚拟硬盘
    VBoxManage createhd --filename "fedora41-vagrant.vdi" --size 40000
    VBoxManage storagectl "fedora41-vagrant" --name "SATA Controller" --add sata --controller IntelAhci
    VBoxManage storageattach "fedora41-vagrant" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "fedora41-vagrant.vdi"
    
    # 添加 ISO
    VBoxManage storagectl "fedora41-vagrant" --name "IDE Controller" --add ide
    VBoxManage storageattach "fedora41-vagrant" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "downloads/Fedora-Server-dvd-x86_64-41-1.4.iso"
    
    info "虚拟机创建完成"
}

# 创建 Vagrantfile
create_vagrantfile() {
    info "创建 Vagrantfile..."
    
    cat > Vagrantfile << 'EOF'
Vagrant.configure("2") do |config|
  config.vm.box = "fedora41"
  config.vm.network "private_network", type: "dhcp"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
end
EOF
    
    info "Vagrantfile 创建完成"
}

# 主函数
main() {
    info "开始自动化安装流程..."
    
    check_requirements
    download_iso
    create_vm
    create_vagrantfile
    
    info "基础环境设置完成"
    info "请按照以下步骤继续："
    info "1. 启动虚拟机并完成 Fedora 安装"
    info "2. 安装完成后，运行 'vagrant package' 命令打包 box"
    info "3. 使用 'vagrant box add' 添加 box"
    info "4. 运行 'vagrant up' 启动虚拟机"
}

# 执行主函数
main 