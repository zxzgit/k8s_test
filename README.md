# k8s学习记录
## ubuntu安装处理（通过 multipass 安装虚拟机模拟集群节点）
到项目 `ubuntu_k8s_build` 目录中

---
### 1、在本机执行创建master和node1两个虚拟机

- 该脚本会通过 `multipass`创建虚拟机（记得先安装multipass软件），执行下面指令建立两个虚拟机，并把 项目目录 映射到 `/multipass/share`
````
// 建立master虚拟机主节点
> ./multipassCreateInstance.sh master

// 建立node1虚拟机子节点
> ./multipassCreateInstance.sh node1
````

---
### 2、在本机执行创建两个虚拟机中都执行如下指令
- 进入 master 和 node1 安装k8s相关软件
````
> sudo passwd root // 设置密码
> su // root用户登陆

> cd /multipass/share/ubuntu_k8s_build
> ./k8s_ini.sh // 该脚本执行安装k8s相关软件
````


- 在node1节点执行如下指令，目的是使用crictl命令之前，需要先配置`/etc/crictl.yaml`如下：
````
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
````


---
### 3、master节点安装集群
- master 节点安装集群， 在master下执行如下指令，建立集群
````
> kubeadm_do_init.sh
````

- 记录输出结果 `kubeadm join XXX` ,这个要拿到子节点中执行，用于子节点加入集群

- 也可以在master节点上执行 `kubectl create token kubernetes-dashboard -n kubernetes-dashboard` 生成token

---
### 4、node1执行节点加入集群
- 将 输出结果中,拿到子节点 node1 中执行
````
> kubeadm join 192.168.64.31:6443 --token t6whvx.yri66ydbepjhm7rh \
	--discovery-token-ca-cert-hash sha256:21ba9f10b307012c7509f259eabe33acd4c1355d7e258a2689e0435fff9f1833
````

- 在master 节点中用非root用户执行如下指令查看集群节点信息
````
> kubectl get node 
NAME     STATUS   ROLES           AGE     VERSION
master   Ready    control-plane   4h34m   v1.28.2
node1    Ready    <none>          4h33m   v1.28.2
````

---
### 5、尝试部署应用
- 在master节点执行，部署试例应用
````
> cp run-my-nginx.example.yaml run-my-nginx.yaml
> kubectl apply -f run-my-nginx.yaml
````

- 查看部署对象信息
````
> kubectl get svc,deploy,pod
NAME                       TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
service/kubernetes         ClusterIP   10.1.0.1      <none>        443/TCP          4h2m
service/my-nginx-service   NodePort    10.1.95.237   <none>        8082:30080/TCP   119m
// 本机可以通过node节点：http://<nodeIp>:30080/ 访问（任何节点都可以）
//  虚拟机内可以通过：curl 127.0.0.1:30080 访问，curl 127.0.0.1:30080/www/index.html 访问映射目录文件

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-nginx-deployment   2/2     2            2           119m

NAME                                       READY   STATUS    RESTARTS   AGE
pod/my-nginx-deployment-785d79786d-2s7dx   1/1     Running   0          119m
pod/my-nginx-deployment-785d79786d-hg6mz   1/1     Running   0          119m
````

尝试请求nginx服务检测是否正常
````
> curl 127.0.0.1:30080
> curl 127.0.0.1:30080/www/index.html 映射目录文件
````

---
### 6、监控面板安装
- 在master节点执行，安装监控面板
````
> kubectl apply -f kubernetes-dashboard.yaml 

> kubectl get pod,svc -n kubernetes-dashboard
kubectl get pod,svc -n kubernetes-dashboard
NAME                                             READY   STATUS    RESTARTS   AGE
pod/dashboard-metrics-scraper-5657497c4c-vj8ht   1/1     Running   0          12m
pod/kubernetes-dashboard-78f87ddfc-6qb4w         1/1     Running   0          12m

NAME                                TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)         AGE
service/dashboard-metrics-scraper   ClusterIP   10.1.83.78    <none>        8000/TCP        12m
service/kubernetes-dashboard        NodePort    10.1.238.11   <none>        443:30001/TCP   12m 

// - 本机请求：https://<节点ip(master和主节点都可以)>:30001/ 
// - 这里注意用https， 访问需要用 kubectl create token kubernetes-dashboard -n kubernetes-dashboard 生成token,在页面输入 

> kubectl create token kubernetes-dashboard -n kubernetes-dashboard // 生成token,用于 dashboard 页面访问输入
````

---
