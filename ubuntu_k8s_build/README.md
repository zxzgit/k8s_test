# multipass 虚拟机安装
本测试使用 multipass 来创建虚拟机器
````
./multipassCreateInstance.sh master
./multipassCreateInstance.sh node-1
````

# 主节点操作
## 安装k8s相关软件
````
./k8s_ini.sh
````

## 主节点建立集群
````
./kubeadm_do_init.sh
````

## 安装dashboard
````
// 安装 kubernetes/dashboard， 2.7是旧的版本了，新版要配置 ingress, 文件下载地址：https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml, 里面我设置访问端口为 30001 
kubectl apply -f kubernetes-dashboard.yaml 

// 生成指定用户的token, kubernetes-dashboard 为部署里面的一个默认用户，这个token在登陆的时候使用
// 默认配置这个用户没啥权限，手动去修改 kind: ClusterRoleBinding 中的 roleRef.name: cluster-admin # zxz修改，用这个角色 cluster-admin 权限大一点，资料：https://zhuanlan.zhihu.com/p/530289298
kubectl create token kubernetes-dashboard -n kubernetes-dashboard 
````

# 子节点操作

## 安装k8s相关软件

````
./k8s_ini.sh
````

## 加入集群
````
kubeadm join 192.168.13.141:6443 --token r9t8e3.nzsxr2k4bdjtw5t9 \
    --discovery-token-ca-cert-hash sha256:1fe4f2d46e552f374919102d10061ceb2100008154b6ef9060ee73db7b37d55b
````


# 测试安装部署
````
kubectl apply -f run-my-nginx.yaml
````



