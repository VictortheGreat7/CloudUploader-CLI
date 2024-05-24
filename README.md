# CloudUploader-CLI

## Overview
CloudUploader-CLI is a command-line tool designed to upload files to Azure Blob Storage. This README provides step-by-step instructions on how to use the script.

## Prerequisites
- Azure CLI installed on your system. Download and install from [Azure CLI Installation Guide](https://docs.microsoft.com/cli/azure/install-azure-cli).
- An active Azure account. Sign up for a free account at [Azure Free Account](https://azure.microsoft.com/free/).
- Copy the `clouduploader.sh` file in this repository and make it executable on your computer

## Steps to Use CloudUploader-CLI

### 1. Login to Azure
First, log in to your Azure account using the following command:

```sh
az login
```

Follow the instructions in the web browser to complete the login process.

### 2. Select Subscription and Tenant
After logging in, select the subscription and tenant you want to use. The command will prompt you to choose a subscription if you have multiple subscriptions.

### 3. Create a Resource Group
If you do not already have one available, create a resource group using the `az group create` command with your desired resource group name and location:

```sh
az group create --name <preferred-group-name> --location <preferred-location>
```

### 4. Create a Storage Account
Create a storage account in the resource group using the `az storage account` create command specifying your preferred resource group and location. Replace `learntocloud13` with your desired account name if you desire (both in this command and the variable name `AZURE_STORAGE_ACCOUNT_NAME`):

```sh
az storage account create --name learntocloud13 --resource-group <resource-group> --location <location> --sku Standard_LRS
```

### 5. Create a Blob Container
Create a blob container within the storage account using the `az storage container create` command. You can replace `clouduploader` with your desired container name if you desire (but make sure to use the `-t` flag and specify the new container name when running the script):

```sh
az storage container create --name clouduploader --account-name learntocloud13
```

### 6. Assign Role to User
Assign the "Storage Blob Data Owner" role to your user account using the `az role assignment create` command. Fill in the appropriate values where needed:

```sh
az role assignment create --role "Storage Blob Data Owner" --assignee "<user-principal-name>" --scope "/subscriptions/<subscription_id>/resourceGroups/test-storage/providers/Microsoft.Storage/storageAccounts/<storage-account>"
```

Use `az ad signed-in-user show` command to get your `user-principal-name`

### 7. Upload Files Using CloudUploader-CLI
Navigate to the directory where you have the `clouduploader.sh` script and run it to upload your desired files to the blob storage. Use the following command to upload your desired file:

```sh
./clouduploader.sh <filename>
```

## Script Usage
The script supports several options:

- `-t, --target <container>`: Specify the target container name (optional).
- `-o, --overwrite`: Overwrite where needed(optional). For example, where a file of the same name already exists in the container
- `-s, --shareable-link`: Generate a shareable link after upload (optional).
- `-e, --sas-expiry <time>`: Set SAS token expiry duration (default: +2 hours).
- `-p, --sas-permissions <permissions>`: Set SAS token permissions (default: r - read).
- `-h, --help`: Display a help message.

### Example Commands
- Upload a file and generate a shareable link:

```sh
./clouduploader.sh <filename> -s
```

- Upload a file to a specific container:
```sh
./clouduploader.sh <filename> -t mycontainer
```