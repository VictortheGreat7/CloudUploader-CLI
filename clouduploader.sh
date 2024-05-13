#!/bin/bash

# Default values
AZURE_STORAGE_ACCOUNT_NAME=learntocloud13

# Function to display usage message
function usage() {
  echo "Usage: $0 <filename> [options]"
  echo "  -t, --target <container>  Target container name (optional)"
  echo "  -p, --progress           Show progress bar (optional)"
  echo "  -s, --shareable-link     Generate shareable link after upload (optional)"
  echo "  -h, --help                Display this help message"
}

# Function to display an error message and exit
function exit_error() {
  echo "Error: $1" >&2
  usage
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -t|--target)
      target_container="$2"
      shift
      shift
      ;;
    -p|--progress)
      show_progress=true
      shift
      ;;
    -s|--shareable-link)
      generate_link=true
      shift
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

# Check if the filename is provided
if [ -z "$filename" ]; then
  exit_error "Please specify a file to upload"
fi

# Check if the file exists
if [ ! -f "$filename" ]; then
  exit_error "File '$filename' not found"
fi

# Set target container (use default if not provided)
if [ -z "$target_container" ]; then
  target_container="clouduploader-cli-storage"
fi

# Load storage account name from environment variable (replace with your variable name)
storage_account_name=${AZURE_STORAGE_ACCOUNT_NAME}

# Build upload command with options
upload_command="az storage blob upload --container-name \"$target_container\" \
--file \"$filename\" --name \"$filename\" --account-name \"$storage_account_name\""
if [ "$show_progress" = true ]; then
  upload_command+=" --progress"
fi
if [ "$generate_link" = true ]; then
  upload_command+=" --output table"
fi

echo "Uploading '$filename' to Azure Blob Storage (container: $target_container)..."
eval "$upload_command"

if [ $? -eq 0 ]; then
  echo "Successfully uploaded '$filename' to Azure Blob Storage (container: $target_container)"

  if [ "$generate_link" = true ]; then
    echo "Generating shareable link..."
    # Extract blob URL from table output (modify based on actual output format)
    blob_url=$(eval "$upload_command" | grep "$filename" | awk '{print $4}')
    echo "Shareable Link: $blob_url"
  fi
else
  # Consider using specific Azure CLI error codes for targeted messages
  exit_error "Failed to upload '$filename' to Azure Blob Storage (container: $target_container). Please check Azure CLI logs for more details."
fi
