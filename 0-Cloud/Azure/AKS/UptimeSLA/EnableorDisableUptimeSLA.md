> # Enable or Disable Uptime SLA


<br /><br />

> Set the Uptime SLA to Free  via ARM using  `az resource update --ids AKSResourceID --set sku.tier="Free"` 

or using (https://resources.azure.com)





Via CLI:

Install this extension using the below CLI command:
az extension add --name aks-preview
Update the extension to make sure you have the latest version installed:
az extension update --name aks-preview
Update AZ CLI to latest version:
az upgrade --yes 

Check AZ CLI version:
az --version
azure-cli   2.19.1
Extensions:
aks-preview 0.5.0 #This is not the latest in release history but the latest available version in update extension command.
Enable and Disable Uptime SLA:
az aks update -n AKSname -g RGname --uptime-sla
az aks update -n AKSname -g RGname –-no-uptime-sla

Stay up to date: AZ CLI Release History and AKS-Preview Release History
