Allow your application pods running inside the cluster to resolve names hosted on a private DNS server outside the cluster. 

<br />




>If you want to forward all DNS requests for *.example.com to be resolved by a DNS server 192.168.100.10, you can edit the operator configuration by running:

    oc edit dns.operator/default


This will launch an editor and you can replace spec: {} with:
```    
spec:
 servers:
 - forwardPlugin:
     upstreams:
     - 192.168.100.10
   name: example-dns
   zones:
   - example.com
```

Save the file and exit your editor.


>documented for OpenShift 4.6 (https://docs.openshift.com/container-platform/4.6/networking/dns-operator.html)