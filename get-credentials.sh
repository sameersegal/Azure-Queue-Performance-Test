#!/bin/bash

# Set your variables
resource_group="azure-qtest"
app_insights_name="azure-qtest-appinsights"
storage_account_name="azureqteststorage"
workspace_name="azure-qtest-workspace"

# Get the instrumentation key
instrumentation_key=$(az resource show -g "$resource_group" -n "$app_insights_name" --resource-type "microsoft.insights/components" --query properties.InstrumentationKey -o tsv)

# Get the storage account connection string
connection_string=$(az storage account show-connection-string -g "$resource_group" -n "$storage_account_name" --query connectionString -o tsv)

workspace_id=$(az monitor log-analytics workspace show --resource-group "$resource_group" --workspace-name "$workspace_name" --query customerId -o tsv)

# Update the .env file
sed -i "s|^APPINSIGHTS_INSTRUMENTATIONKEY=.*$|APPINSIGHTS_INSTRUMENTATIONKEY=$instrumentation_key|" .env
sed -i "s|^AZURE_STORAGE_CONNECTION_STRING=.*$|AZURE_STORAGE_CONNECTION_STRING=$connection_string|" .env
sed -i "s|^RESOURCE_GROUP=.*$|RESOURCE_GROUP=$resource_group|" .env
sed -i "s|^WORKSPACE_ID=.*$|WORKSPACE_ID=$workspace_id|" .env
