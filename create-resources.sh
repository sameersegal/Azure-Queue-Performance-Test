#!/bin/bash

# Set your variables
resource_group="azure-qtest"
location="centralindia"
app_name="azure-qtest-func"
app_insights_name="azure-qtest-appinsights"
storage_account_name="azureqteststorage"
workspace_name="azure-qtest-workspace"

# Delete the resource group if it exists
az group delete --name "$resource_group" --yes

# Create the resource group
az group create --name "$resource_group" --location "$location"

# Deploy resources using the ARM template
az deployment group create --resource-group "$resource_group" --template-file azuredeploy.json --parameters appName="$app_name" appInsightsName="$app_insights_name" storageAccountName="$storage_account_name" location="$location" --parameters workspaceName="$workspace_name"

sed -i "s|^RESOURCE_GROUP=.*$|RESOURCE_GROUP=$resource_group|" .env