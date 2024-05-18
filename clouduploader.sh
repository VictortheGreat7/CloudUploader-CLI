#!/bin/bash

# Default values
AZURE_STORAGE_ACCOUNT_NAME="learntocloud13"
DEFAULT_CONTAINER="clouduploader-cli-storage"
DEFAULT_EXPIRY="+2hours"  # Set expiry to 2 hours by default (modify as needed)
SAS_PERMISSIONS="r"    # Set permissions to read-only by default (modify as needed)

# Function to display usage message
function usage() {
  echo "Usage: $0 &lt;filename&gt; [options]"
  echo "  -t, --target &lt;container&gt;     Target container name (optional)"
  echo "  -o, --overwrite              Overwrite existing (optional)"
  echo "  -s, --shareable-link         Generate shareable link after upload (optional)"
  echo "  -e, --sas-expiry &lt;time&gt;      Set SAS token expiry duration (default: +2hours)"
  echo "  -p, --sas-permissions &lt;permissions&gt;  Set SAS token permissions (default: r - read)"
  echo "  -h, --help                   Display this help message"
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
      SAS_EXPIRY="$2"
      shift 2
      ;;
    -p|--sas-permissions)
      SAS_PERMISSIONS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      filename="$1"
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

# Check if the filename is provided
if [ -z "$filename" ]; then
  exit_error "Please specify a file to upload"
fi

# Check if the file exists
if [ ! -f "$filename" ]; then
  exit_error "File '$filename' not found"
fi

# Load storage account name from environment variable (replace with your variable name)
storage_account_name="${AZURE_STORAGE_ACCOUNT_NAME}"

# Set target container (use default if not provided)
if [ -z "$target_container" ]; then
  target_container="$DEFAULT_CONTAINER"
fi

# Build upload command with options
upload_command="az storage blob upload --container-name \"$target_container\" \
--file \"$filename\" --name \"$filename\" --account-name \"$storage_account_name\""
if [ "$overwrite" = true ]; then
  upload_command+=" --overwrite"
fi

# Generate SAS token expiry time
sas_expiry_time=$(date -u -d "$DEFAULT_EXPIRY" '+%Y-%m-%dT%H:%MZ')

if [ "$generate_link" = true ]; then
  # Generate SAS token with expiry and permissions
  sas_token=$(az storage blob generate-sas \
    --name "$filename" \
    --account-name "$storage_account_name" \
    --container-name "$target_container" \
    --permissions r \
    --expiry "$sas_expiry_time" \
    --account-key YL1uqN93d8erhkMKRtJ/AZWuuvOqIoawjN9pGSX5zYvE/ZSZY7FM2puJOJg554HbRxS9fyvrW2Pw+AStlzAbqw== \
    --auth-mode key \
    --output tsv)

  # Modify upload command to capture output as table for easier parsing
  # upload_command+=" --output table"
fi

echo "Uploading '$filename' to Azure Blob Storage (container: $target_container)..."
eval "$upload_command" | pv

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