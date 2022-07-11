> # Configure a nodepool with HugePage support.




<br />

- In kubernetes to enable HugePages you add in kubelet `conf --feature-gates=HugePages=true`

- In OpenShift you use node tunning operator 

- But in AKS seems that there is no direct solution.



<br />

The only official Azure Hugepage doc is about `transparentHugePage` (https://docs.microsoft.com/en-us/azure/aks/custom-node-configuration), from my tests looks like it is not sufficient because in the article it's saying to set `Transparent HugePages` but Transparent HugePages and HugePages are two different things.

<br />

If you describe the node after you enabled the Transparent HugePages as the article said and by the way on most Linux system it’s already enabled, the HugePages value is still 0 that means that even with Transparent activated the HugePages are still not enabled:
<br />

![](\pics\Capture.JPG)

 

In this case if you will create a pod asking :

```yaml
    resources:
     limits:
        hugepages-2Mi: 100Mi
```
<br />

This pod will fail with Insufficient HugePages  because we  have hugepages 0 on the node (means not enabled)
<br />

 
<br />

> ### Manual temporary workaround is to:
<br />

Enter on the node, once inside the node I applied the fallowing commands:


```
mkdir -p /mnt/huge                                                             
mount -t hugetlbfs nodev /mnt/huge                                               
echo 1024 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages                                                               
cat  /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages 
```

Then you will have:
![](\pics\Capture2.JPG)

<br />
<br />

> Or add below value in `/etc/sysctl.conf` and reload configuration by issuing `sysctl -p` command

<br />
<br />

<br />
<br />


> ## To automate things and not worry about node scale or node updates use daemonsets:
<br />
<br />


```yaml
cat <<EOF > sshNode.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: privileged
spec:
  selector:
    matchLabels:
      name: privileged-container
  template:
    metadata:
      labels:
        name: privileged-container
    spec:
      containers:
      - name: busybox
        image: busybox
        command: ["/bin/sh","-c"]
        args: ["mkdir -p host/mnt/huge; mount -t hugetlbfs nodev host/mnt/huge; echo 1024 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages"]
        resources:
          limits:
            cpu: 200m
            memory: 100Mi
          requests:
            cpu: 100m
            memory: 50Mi
        stdin: true
        securityContext:
          privileged: true
        volumeMounts:
        - name: host-root-volume
          mountPath: /host
          readOnly: false
      volumes:
      - name: host-root-volume
        hostPath:
          path: /
      hostNetwork: true
      hostPID: true
      restartPolicy: Always
EOF

```




<br />

To finally enable the the HugePages on the nodes enter on each node and do:

```bash
systemctl daemon-reload

systemctl restart kubelet
```
<br />

You need to restart the nodes via cli or from the portal, for the HugePages to be enabled on the nodes.