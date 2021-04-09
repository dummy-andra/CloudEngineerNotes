#!/usr/bin/env bash


#Download and install az cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; sudo apt install jq -y


#Download the oc cli to the jumpbox
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
mkdir openshift
tar -zxvf openshift-client-linux.tar.gz -C openshift

function addbashrc() {
   if [ -f .bashrc ]; then
      output='export PATH=$PATH:~/openshift'
      echo $output >> .bashrc
   fi
  source .bashrc
}
addbashrc

#reboot to be able to use oc cli 
reboot






