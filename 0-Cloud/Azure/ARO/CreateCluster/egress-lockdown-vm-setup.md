

```
# move the vm setup script to the azute jumpbox vm, and with az run command run the script inside the vm
scp vm.sh  aroadmin@13.82.169.152:/home/aroadmin
scp deploy-openshift-pod.sh   aroadmin@13.82.169.152:/home/aroadmin 
scp credentials.sh  aroadmin@13.82.169.152:/home/aroadmin
az vm run-command invoke -g egresslockdown  -n ubuntu-jump --command-id RunShellScript --scripts "cd /home/aroadmin; bash vm.sh"

# this command might not work - i deed to improove it (meanwhile you can run the script from jumbox)
az vm run-command invoke -g egresslockdown  -n ubuntu-jump --command-id RunShellScript --scripts "cd /home/aroadmin; bash deploy-openshift-pod.sh "


```



# If you use linux OS on local vm

```
# ssh to azure VM, use -D 8888 to create a port tunneling to your local linux machine
ssh -i .ssh/id_rsa   aroadmin@13.82.169.152 -D 8888 -vv

curl -x socks5h://localhost:8888 https://console-openshift-console.apps.uxmpmvde.eastus.aroapp.io/

or
export ALL_PROXY=socks5h://localhost:8888
curl https://console-openshift-console.apps.uxmpmvde.eastus.aroapp.io/

https://console-openshift-console.apps.z24ojhlh.eastus.aroapp.io/

```

# with WSL

```
sudo ssh -i .ssh/id_rsa  \
-L 443:console-openshift-console.apps.z24ojhlh.eastus.aroapp.io:443 \
-L 443:oauth-openshift.apps.z24ojhlh.eastus.aroapp.io:443  \
-L 6443:apps.z24ojhlh.eastus.aroapp.io:6443 aroadmin@13.82.169.152


#then add in  windows etc host file (C:\Windows\System32\drivers\etc\hosts)

127.0.0.1 console-openshift-console.apps.z24ojhlh.eastus.aroapp.io
127.0.0.1 oauth-openshift.apps.z24ojhlh.eastus.aroapp.io
127.0.0.1 apps.z24ojhlh.eastus.aroapp.io

#with that I can access the web console 

#try and see if you can use oc commands from wsl

wsl-machine$ oc login localhost:6443 -u $ARO_USERNAME -p $ARO_PASSWORD
```