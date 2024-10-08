# azure-demo-terraform

## Variables for the Storage Account
```
SUBSCRIPTION=""
RESOURCE_GROUP_NAME="tysonngodemo-terraform-backend-rg"
STORAGE_ACCOUNT_NAME="tysonngodemoterraform"
CONTAINER_NAME="tysonngodemo-terraform-states"
LOCATION="SoutheastAsia"
```

## Create a resource group
```
az group create --name $RESOURCE_GROUP_NAME --subscription $SUBSCRIPTION --location $LOCATION
```

## Create a storage account (must be globally unique)
```
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
```

## Get the storage account key
```
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME -o json --query "[0].value")
```

## Create a blob container
```
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY --public-access off
```

## Run Terraform
```
terraform init -backend-config=./backends/<env>.hcl
```
