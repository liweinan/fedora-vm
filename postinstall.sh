#!/bin/bash

# 设置错误时退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 打印带颜色的信息函数
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

# 创建 Host-Only 网络接口
create_hostonly_network() {
    info "创建 Host-Only 网络接口..."
    
    # 检查 vboxnet0 是否存在
    if ! VBoxManage list hostonlyifs | grep -q "vboxnet0"; then
        info "创建 vboxnet0 接口..."
        VBoxManage hostonlyif create
        VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
    else
        info "vboxnet0 接口已存在"
    fi
}

# 打包和添加 box
package_and_add_box() {
    info "开始打包和添加 box..."
    
    # 获取当前架构
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        BOX_ARCH="aarch64"
    else
        BOX_ARCH="x86_64"
    fi
    
    # 关闭虚拟机
    info "关闭虚拟机..."
    VBoxManage controlvm fedora41-vagrant poweroff || true
    
    # 打包虚拟机
    info "打包虚拟机..."
    vagrant package --base fedora41-vagrant --output fedora41.box
    
    # 添加 box
    info "添加 box..."
    vagrant box add --name fedora41 --provider virtualbox --architecture "$BOX_ARCH" --force "$(pwd)/fedora41.box"
    
    # 验证 box 是否添加成功
    if vagrant box list | grep -q "fedora41"; then
        info "Box 添加成功"
    else
        error "Box 添加失败"
        exit 1
    fi
}

# 启动虚拟机
start_vm() {
    info "启动虚拟机..."
    vagrant up
}

# 显示使用帮助
show_help() {
    echo "用法: $0"
    echo "此脚本用于自动化执行 Fedora 安装后的配置步骤"
    echo "包括："
    echo "  1. 创建 Host-Only 网络接口"
    echo "  2. 打包虚拟机"
    echo "  3. 添加 box"
    echo "  4. 启动虚拟机"
    exit 0
}

# 主函数
main() {
    # 处理帮助参数
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
    fi
    
    info "开始执行安装后配置..."
    
    # 按顺序执行各个步骤
    check_requirements
    create_hostonly_network
    package_and_add_box
    start_vm
    
    info "配置完成！"
    info "您现在可以使用 'vagrant ssh' 连接到虚拟机"
}

# 执行主函数
main "$@" 