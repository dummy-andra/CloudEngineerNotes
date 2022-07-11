##!/usr/bin/env bash
set -e
. ./params.sh 



# Set environment variables

echo "Set environment variables"

domain=$(az aro show -g $RESOURCEGROUP -n $CLUSTER --query clusterProfile.domain -o tsv)  

location=$(az aro show -g $RESOURCEGROUP -n $CLUSTER  --query location -o tsv)  

apiServer=$(az aro show -g $RESOURCEGROUP -n $CLUSTER  --query apiserverProfile.url -o tsv)  

webConsole=$(az aro show -g $RESOURCEGROUP -n $CLUSTER  --query consoleProfile.url -o tsv)  

oauthCallbackURL=https://oauth-openshift.apps.$domain.$location.aroapp.io/oauth2callback/AAD  


# For this example I used 2 tennants on 2 different subscriptions to be able to simulate areal world infra
# On first tennant I created the cluster and I have fully admin wrights
# I use AAD to give permissions to the second tennant from a different subscription to access my ARO cluster
 

# I have decided to give
az login && tenantId=$(az account show --query tenantId -o tsv) 

# We need to create an Azure AD Application in order to integrate OpenShift authentication with Azure AD


# az ad app create \ 
#   --query appId -o tsv \ 
#   --display-name $appName \ 
#   --reply-urls $oauthCallbackURL \ 
#   --password $appSecret 
# # Create a new environment variable with the application id.
# appId=$(az ad app list --display-name $appName | jq -r '.[] | "\(.appId)"')

echo "create an Azure AD Application"

app_id=$(az ad app create \
  --query appId -o tsv \
  --display-name $appName \
  --reply-urls $oauthCallbackURL \
  --password $appSecret)


# This user will need an Azure Active Directory Graph scope (Azure Active Directory Graph.User.Read) permission 
# to be able to read the user information from Azure Active Directory

echo "give (Azure Active Directory Graph.User.Read) permission "
az ad app permission add \
--api 00000002-0000-0000-c000-000000000000 \
--api-permissions 311a71cc-e848-46a1-bdf8-97ff7156d8e6=Scope \
--id $app_id

# Create optional claims to use e-mail with an UPN fallback authentication.

echo "Create optional claims to use e-mail with an UPN fallback authentication"

 
cat <<EOF > manifest.json
[{
  "name": "upn",
  "source": null,
  "essential": false,
  "additionalProperties": []
},
{
"name": "email",
  "source": null,
  "essential": false,
  "additionalProperties": []
}]
EOF



# Configure optional claims for the Application

echo "Configure optional claims for the Application"

az ad app update \
--set optionalClaims.idToken=@manifest.json \
--id $app_id




# Configure an OpenShift OpenID authentication secret YOU NEED THIS TO RUN IT ONE TIME

echo "Configure an OpenShift OpenID authentication secret."

oc create secret generic openid-client-secret-azuread \
--namespace openshift-config \
--from-literal=clientSecret=$appSecret


# Create and openshift OAuth resource object which connects the cluster with the AAD.

echo "Create and openshift OAuth resource object which connects the cluster with the AAD"


cat <<EOF > oidc.yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: AAD
    mappingMethod: claim
    type: OpenID
    openID:
      clientID: $app_id
      clientSecret:
        name: openid-client-secret-azuread
      extraScopes:
      - email
      - profile
      extraAuthorizeParameters:
        include_granted_scopes: "true"
      claims:
        preferredUsername:
        - email
        - upn
        name:
        - name
        email:
        - email
      issuer: https://login.microsoftonline.com/$tenantId
EOF




oc apply -f oidc.yaml


 