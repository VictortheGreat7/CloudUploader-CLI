#!/bin/bash

# Default values
AZURE_STORAGE_ACCOUNT_NAME="learntocloud13"
DEFAULT_CONTAINER="clouduploader"
DEFAULT_EXPIRY="+2 hours"  # Set expiry to 2 hours by default (modify as needed)
DEFAULT_PERMISSIONS="r"  # Set permissions to read-only by default (modify as needed)

# Function to display usage message
function usage() {
 echo "Usage: $0 <filename1> <filename2> ... [options]"
 echo " -t, --target <container>   Target container name (optional)"
 echo " -o, --overwrite       Overwrite existing (optional)"
 echo " -s, --shareable-link     Generate shareable link after upload (optional)"
 echo " -e, --sas-expiry <time>   Set SAS token expiry duration (default: +2 hours)"
 echo " -p, --sas-permissions <permissions> Set SAS token permissions (default: r - read)"
 echo " -h, --help          Display this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
 key="$1"
 case $key in
  -t|--target)
   target_container="$2"
   shift 2
   ;;
  -o|--overwrite)
   overwrite=true
   shift
   ;;
  -s|--shareable-link)
   generate_link=true
   shift
   ;;
  -e|--sas-expiry)
   sas_expiry="$2"
   shift 2
   ;;
  -p|--sas-permissions)
   sas_permissions="$2"
   shift 2
   ;;
  -h|--help)
   usage
   exit 0
   ;;
  *)
   filenames+=("$1")
   shift
   ;;
 esac
done

# Function to display an error message and exit
function exit_error() {
 echo "Error: $1" >&2
 usage
 exit 1
}

# Check if at least one filename is provided
if [ ${#filenames[@]} -eq 0 ]; then
 exit_error "Please specify at least one file to upload"
fi

# Load storage account name from environment variable
storage_account_name="${AZURE_STORAGE_ACCOUNT_NAME:-$storage_account_name}"

# Set target container (use default if not provided)
target_container="${target_container:-$DEFAULT_CONTAINER}"

# Set default expiry if not provided
sas_expiry="${sas_expiry:-$DEFAULT_EXPIRY}"

# Set default permissions if not provided
sas_permissions="${sas_permissions:-$DEFAULT_PERMISSIONS}"

# Iterate over each file and upload
for filename in "${filenames[@]}"; do
 # Check if the file exists
 if [ ! -f "$filename" ]; then
  exit_error "File '$filename' not found"
 fi

 # Build upload command with options
 upload_command="az storage blob upload --container-name \"$target_container\" \
 --file \"$filename\" --name \"$filename\" --account-name \"$storage_account_name\""

 if [ "$overwrite" = true ]; then
  upload_command+=" --overwrite"
 fi

 # Generate SAS token if required
 sas_expiry_time=$(date -u -d "$sas_expiry" '+%Y-%m-%dT%H:%MZ')

 if [ "$generate_link" = true ]; then
  # Generate SAS token with expiry and permissions
  sas_token=$(az storage blob generate-sas \
   --name "$filename" \
   --account-name "$storage_account_name" \
   --container-name "$target_container" \
   --permissions "$sas_permissions" \
   --expiry "$sas_expiry_time" \
   --auth-mode login \
   --as-user \
   --output tsv)

  # Check if SAS token generation was successful
  if [ -z "$sas_token" ]; then
   exit_error "Failed to generate SAS token for '$filename'"
  fi
 fi

 echo "Uploading '$filename' to Azure Blob Storage (container: $target_container)..."
 eval "$upload_command"

 if [ $? -eq 0 ]; then
  echo "Successfully uploaded '$filename' to Azure Blob Storage (container: $target_container)"
  if [ "$generate_link" = true ]; then
   echo "Generating shareable link..."
   # Construct SAS URL by combining blob URI with SAS token
   shareable_link="https://${storage_account_name}.blob.core.windows.net/${target_container}/${filename}?${sas_token}"
   echo "Shareable Link: $shareable_link"
  fi
 else
  exit_error "Failed to upload '$filename' to Azure Blob Storage (container: $target_container)"
 fi
done
