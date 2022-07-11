# Obtain ARM Template

wget https://raw.githubusercontent.com/stuartatmicrosoft/azure-aro/master/azuredeploy.json


# Object ARM Template Parameters File

wget https://raw.githubusercontent.com/stuartatmicrosoft/azure-aro/master/azuredeploy.parameters.json


# Create SP

az ad sp create-for-rbac -n my-aro-cluster --role Contributor --only-show-errors -o table


# Determine Object ID

az ad sp list --filter "displayname eq 'my-aro-cluster'" --query "[?appDisplayName=='my-aro-cluster'].{name: appDisplayName, objectId: objectId}" -o table



# Determine ARO RP Object ID

az ad sp list --filter "displayname eq 'Azure Red Hat OpenShift RP'" --query "[?appDisplayName=='Azure Red Hat OpenShift RP'].{name: appDisplayName, objectId: objectId}" -o table


# Edit parameters file

vi azuredeploy.parameters.json


# Create Resource Group

az group create -n armaro -l westeurope


# Initiate Deployment

az deployment group create -g armaro --template-file azuredeploy.json --parameters @azuredeploy.parameters.json



# list all objed id sp
for sp in name; do az ad sp list --query "[?appDisplayName==$sp].{objectId: objectId}" -o table; done

# list all app sp id 

for sp in name; do az ad sp list --query "[?appDisplayName==$sp].{appId: appId}" -o table; done

for sp in name; do az ad sp list --query "[?appDisplayName==$sp].{appId: appId}" -o table| awk '(NR>2)'; done 

for sp in name; do az ad sp delete --id $(az ad sp list  --query "[?appDisplayName==$sp].{appId: appId}" -o table| awk '(NR>2)'); done


item=$(for sp in name; do az ad sp list --query "[?appDisplayName==$sp].{appId: appId}" -o table| awk '(NR>2)'; done)

for i in item; do echo $i; done

