#!/bin/sh
instanceName=$1 # 传入一个参数作为要创建的服务器名称，如果存在则先删除
multipass delete $instanceName && multipass purge
multipass launch --name $instanceName --cpus 4 --disk 20G --memory 8G && multipass mount /Users/mizheng/multipass/share $instanceName:/multipass/share