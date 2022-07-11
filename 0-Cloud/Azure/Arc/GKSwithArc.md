> # Registering a Google Kubernetes Engine Cluster with Azure Arc


<br />

## Procedure

<br />


- I created a Google Cloud account and I created a cluster in it.
- I used Azure Arc to connect the cluster from Google cloud to Azure and monitor it.
- I mention that I did not created security rules, network policies, I staied with the basic in GCP also in Azure.

Bellow you can see the steps:


<br />

## Setting up the Environment

<br />

> Make sure to be on a machine where you have access to google cloud and azure also.

<br />


## Install Google CLI:

[Installing Google Cloud SDK  |  Cloud SDK Documentation](https://cloud.google.com/sdk/docs/install)

<br />

![](pics\1.png)


<br />

## Connect to Google Kubernetes cluster:

<br />

```
./google-cloud-sdk/bin/gcloud container clusters get-credentials cluster-1 --zone us-central1-c --project seraphic-ripsaw-301013
```

<br />

## Start by registering the provider for your Azure subscription. 

<br />


> Please be patient while the providers are registered. This may take a while.

<br />


```
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
```

<br />


>  We also need to register an extension for the az CLI to work with Arc enabled Kubernetes clusters. Run the below commands to register.
```
az extension add --name connectedk8s
az extension add --name k8sconfiguration
```
<br />


## We also need the latest version of Helm installed. On macOS install it through Homebrew.

> ### `brew install helm`

<br />

<br />


## Finally, create a resource group for the registered clusters. 

<br />


> Make sure the resource group is created in one of the supported regions — East US and West Europe.

<br />


> ### `az group create --name arc-demo-clusters  -l WestEurope`

<br />

<br />


# We are now ready to register the cluster. Make sure your KUBECONFIG environment is pointing to the correct cluster.

<br />


## Registering the Kubernetes cluster with Azure Arc will result in a new namespace. 

<br />


> Let’s initiate the registration by running the below command:
(this command you will get it from the Azure portal Azure Arc)

<br />


> ## `az connectedk8s connect --name google-cluster --resource-group arc-demo-clusters --location w`

<br />





## Connect to the cluster-Command-line access

<br />


```
./google-cloud-sdk/bin/gcloud container clusters get-credentials andra --zone us-central1-c --project seraphic-ripsaw-301013 
```


<br />

##  Create a resource group for the registered clusters. Make sure the resource group is created in one of the supported regions — East US and West Europe.

`az group create --name arc-andra  -l WestEurope`

<br />


# Enable monitoring
```
curl -o enable-monitoring.sh -L https://aka.ms/enable-monitoring-bash-script
export logAnalyticsWorkspaceResourceId="/subscriptions/<subscriptionId>/resourceGroups/arc-andra/providers/Microsoft.Kubernetes/connectedClusters/andra-google-cluster"
kubectl config get-contexts
export kubeContext="gke_seraphic-ripsaw-301013_us-central1-c_andra"
bash enable-monitoring.sh --resource-id $azureArcClusterResourceId                 
bash enable-monitoring.sh --resource-id $azureArcClusterResourceId --kube-context $kubeContext 
```

# Inside the cluster I deployed a simple pod.

![](pics\Capture.JPG)


# Portal

![](pics\Capture2.JPG)
![](pics\Capture3.JPG)

Sites:

https://cloudsapient.com/azure-arc-enabled-kubernetes-onboarding-aws-eks-cluster-to-azure-part-1/
https://itnext.io/azure-arc-arc-enabled-kubernetes-arc-for-servers-2ebcd87094af






