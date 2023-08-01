#!/bin/sh
log_pre="[k8s安装]"
doLog(){
  echo ${log_pre}${1} # 参数获取 通过 $1 , $2
}
doLog "开始安装" # 参数传递

# 请以root权限执行该脚本
# 如果未设置root密码，使用如下语句设置,设置完之后登陆root, 执行该脚本
# sudo passwd root

# 关闭swap
doLog "关闭swap"
swapoff -a

# 永久关闭swap
doLog "永久关闭swap处理"
sed -ri 's/.swap./#&/' /etc/fstab

# k8s安装镜像源

# 1.使得 apt 支持 ssl 传输
doLog "apt-transport-https 安装"
apt-get install -y apt-transport-https

# 2.下载 gpg 密钥
doLog "下载 gpg 密钥"
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -

# 3.添加 k8s 镜像源
doLog "添加 k8s 镜像源"
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

# 更新包
doLog "更新包"
apt-get update

# 安装docker，安装的docker的同时会安装 containerd
doLog "docker 安装"

apt install docker.io -y
docker --version

doLog "docker 启动"
systemctl restart docker

# containerd 配置设置
doLog "containerd 配置处理"

rm -rf /etc/containerd && mkdir /etc/containerd && containerd config default > /etc/containerd/config.toml

# -  修改 containerd 的 config.toml 中 SystemdCgroup = true, 修改 sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.9, 不修改 containerd 无法正常使用k8s启动不了
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's/"registry.k8s.io\/pause:3.6"/"registry.aliyuncs.com\/google_containers\/pause:3.9"/' /etc/containerd/config.toml

doLog "containerd 重启"
systemctl restart containerd

# 4.更新源列表
#doLog "再次更新包"
#apt-get update

# 5.安装 kubectl，kubeadm以及 kubelet, 指定安装版本：apt-get install -y kubeadm=1.24.3-00 kubectl=1.24.3-00 kubelet=1.24.3-00
doLog "安装 kubelet kubeadm kubectl"
apt-get install -y kubelet kubeadm kubectl

# 设置开机启动 kubectl
doLog "启动 kubectl"
systemctl enable --now kubelet

# todo 拉取kubeadm需要的镜像, 是不是可以去掉
doLog "预先拉取kubeadm需要的镜像"
kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers

doLog "设置 kubernetes.conf 的net"
tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF