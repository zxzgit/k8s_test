#!/bin/sh

log_pre="[k8s 集群初始化]"
doLog(){
  echo ${log_pre}${1} # 参数获取 通过 $1 , $2
}
doLog "执行-开始"

CURRENT_DIR=$(cd $(dirname $0); pwd)
doLog "当前目录:${CURRENT_DIR}"

# 资料：https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
doLog "重置集群(要再次运行 kubeadm init，你必须首先卸载集群)"
kubeadm reset

# 设定master节点ip
#doLog "修改/etc/hosts"
#echo "192.168.64.21 master" >> /etc/hosts

# 应对 kubeadm init 的时候过不去，通过 systemctl status kubelet 查看 failed to pull image \"registry.k8s.io/pause:3.6\" 相关报错的解决，镜像拉取错误
#ctr images pull registry.aliyuncs.com/google_containers/pause:3.9
#ctrctr -n k8s.io i tag registry.aliyuncs.com/google_containers/pause:3.9 registry.k8s.io/pause:3.6

# 事先拉取kubeadm需要的镜像, 可以去掉, 有网络 init 的时候会自己拉， 配合 --image-repository  拉取指定仓库，google源国内无法访问
#doLog "预先拉取kubeadm需要的镜像"
#kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers

# 初始化集群节点, kubernetes-version 为 kubeadm version 中的 GitVersion, apiserver-advertise-address 如果不填写默认是本机
# 如果安装失败 kubeadm reset 进行重置,https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
doLog "创建集群"
kubeadm init \
--image-repository registry.aliyuncs.com/google_containers \
--service-cidr=10.1.0.0/16 \
--pod-network-cidr=10.244.0.0/16 \
--v=5 \
--node-name=master

# root 用户执行, 使用root用户执行，支持使用kubectl命令
doLog "root 用户 添加 KUBECONFIG 环境变量"

# 如果不设置这个环境变量 root 用户执行 kubectl 会报错 The connection to the server localhost:8080 was refused - did you specify the right host or port?
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/environment
chmod -R 777 /etc/kubernetes/admin.conf

#doLog "切换用户到 ubuntu"
#su ubuntu

# 要使非 root 用户可以运行 kubectl，请运行以下命令， 它们也是 kubeadm init 输出的一部分：，否则无法执行 kubectl
doLog "复制 /etc/kubernetes/admin.conf 到用户 目录"
kubectl_user_home="/home/ubuntu"
mkdir -p ${kubectl_user_home}/.kube
sudo cp -i /etc/kubernetes/admin.conf ${kubectl_user_home}/.kube/config
sudo chown -R 777 ${kubectl_user_home}/.kube/config

# 安装fannel，部署一个基于 Pod 网络插件的 容器网络接口 (CNI) https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network
doLog "安装fannel"
# 相关项目：https://github.com/flannel-io/flannel, 这个国内下载不稳定，可以事先下载好
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 判断是否事先下载好了
kubeFlannelFile="${CURRENT_DIR}/kube-flannel.yml"
(if [ -f $kubeFlannelFile ]; then (kubectl apply -f $kubeFlannelFile ); else (kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml) ; fi)

doLog "执行-结束"