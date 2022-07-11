

> # Change sysctl kernel parameter on the worker node





You can change the default settings for the Linux kernel `sysctl` parameters on worker nodes  by applying a custom [Kubernetes DaemonSet](https://nam06.safelinks.protection.outlook.com/?url=https%3A%2F%2Fkubernetes.io%2Fdocs%2Fconcepts%2Fworkloads%2Fcontrollers%2Fdaemonset%2F&data=04|01|andra.necula%40microsoft.com|2fcf29a4d4304106a08208d8ccf5693d|72f988bf86f141af91ab2d7cd011db47|1|0|637484701866203068|Unknown|TWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D|1000&sdata=KRWbAQRfxYNc%2BkEyMsHqaFuypSzUo0x%2B4%2BJSZCRnZfk%3D&reserved=0) with an [initContainer](https://nam06.safelinks.protection.outlook.com/?url=https%3A%2F%2Fkubernetes.io%2Fdocs%2Fconcepts%2Fworkloads%2Fpods%2Finit-containers%2F&data=04|01|andra.necula%40microsoft.com|2fcf29a4d4304106a08208d8ccf5693d|72f988bf86f141af91ab2d7cd011db47|1|0|637484701866203068|Unknown|TWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D|1000&sdata=ffEKKpcVoEbRkOv3ETRBxr0ZudUTXWGcR%2F5QwE49vCw%3D&reserved=0) to your cluster. 

The daemon set modifies the settings for all existing worker nodes and applies the settings to any new worker nodes that are provisioned in the cluster. The `init container` makes sure that these modifications occur before other pods are scheduled on the worker node. No pods are affected.



```yaml
 apiVersion: apps/v1
 kind: DaemonSet
 metadata:
   name: kernel-optimization
   namespace: kube-system
   labels:
     tier: management
     app: kernel-optimization
 spec:
   selector:
     matchLabels:
       name: kernel-optimization
   template:
     metadata:
       labels:
         name: kernel-optimization
     spec:
       hostNetwork: true
       hostPID: true
       hostIPC: true
       initContainers:
         - command:
             - sh
             - -c
             - sysctl -w net.ipv4.ip_local_port_range="1025 65535"; sysctl -w net.core.somaxconn=65535 >> /etc/sysctl.conf; sysctl -p;
           image: alpine:3.6
           imagePullPolicy: IfNotPresent
           name: sysctl
           resources: {}
           securityContext:
             privileged: true
             capabilities:
               add:
                 - NET_ADMIN
           volumeMounts:
             - name: modifysys
               mountPath: /sys
       containers:
         - resources:
             requests:
               cpu: 0.01
           image: alpine:3.6
           name: sleepforever
           command: ["/bin/sh", "-c"]
           args:
             - >
               while true; do
                 sleep 100000;
               done
       volumes:
         - name: modifysys
           hostPath:
             path: /sys
```



```bash
kubectl apply -f worker-node-kernel-settings.yaml
```







 Avoid `forbidden sysctl: "net.core.somaxconn" not whitelisted`  use **init containers**



The usage of init container can refer to: [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

The advantage of using init container is that there is no need to change the configuration of kubelet, but this init container needs to be configured with privilege permissions.

The following is an example of starting a Pod:

```yaml
cat <<EOF > pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-sysctl-init
  namespace: default
spec:
  containers:
  - image: nginx
    imagePullPolicy: Always
    name: nginx
    ports:
    - containerPort: 80
      protocol: TCP
  initContainers:
  - image: busybox
    command:
    - sh
    - -c
    - echo 65535 > /proc/sys/net/core/somaxconn
    imagePullPolicy: Always
    name: setsysctl
    securityContext:
      privileged: true

EOF
```







Additional reading:

https://bbotte.github.io/service_config/adjust-the-kernel-parameters-of-the-pod-on-kubernetes.html

https://www.cnblogs.com/sunsky303/p/11090540.html

https://medium.com/daimler-tss-tech/tuning-network-sysctls-in-docker-and-kubernetes-766e05da4ff2

https://programmerclick.com/article/2827413992/

https://coderoad.ru/51508493/Kubernetes-Kops-%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%B8%D1%82%D1%8C-%D1%84%D0%BB%D0%B0%D0%B3-sysctl-%D0%BD%D0%B0-kubelet

https://cloud.ibm.com/docs/containers?topic=containers-kernel&locale=zh-TW