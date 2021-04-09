##!/usr/bin/env bash
set -e
. ./credentials.sh



#Log in using oc login:
oc login $ARO_URL -u $ARO_USERNAME -p $ARO_PASSWORD

#Run CentOS to test outside connectivity
#Create a pod
cat <<EOF > pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: centos
spec:
  containers:
  - name: centos
    image: centos
    ports:
    - containerPort: 80
    command:
    - sleep
    - "3600"
EOF

# Deploy
oc apply -f pod.yaml