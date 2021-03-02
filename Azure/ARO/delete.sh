##!/usr/bin/env bash
set -e
. ./params.sh


az aro delete --resource-group $RESOURCEGROUP --name $CLUSTER