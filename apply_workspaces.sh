#!/bin/bash

# apply_workspaces.sh
# Expected file structure
# ├── apply_workspaces.sh
# └── workspaces
#     ├── .env
#     ├── active
#     │   ├── 1234-sampleworkspace.dsl
#     │   └── 5678-anotherworkspace.dsl
#     └── inactive

# Exit immediately if a command exits with a non-zero status
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

WORKSPACES_DIR="./workspaces"

# At the beginning of the script
CONFIG_FILE="$WORKSPACES_DIR/workspaces.yml"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo -e "${RED}Error: yq is not installed. Please install yq to use this script.${NC}"
    exit 1
fi

# Load default URL
STRUCTURIZR_URL=$(yq e '.default_url' "$CONFIG_FILE")


# Function to mask sensitive variables
mask_variable() {
    local var="$1"
    local masked
    masked=$(echo "$var" | sed 's/./*/g')
    echo "$masked"
}

# Load environment variables from .env file if it exists
if [ -f "$WORKSPACES_DIR/.env" ]; then
    echo -e "${YELLOW}Loading environment variables from $WORKSPACES_DIR/.env${NC}"
    # Export all variables from .env
    set -a
    source "$WORKSPACES_DIR/.env"
    set +a
else
    echo -e "${YELLOW}.env file not found in $WORKSPACES_DIR. Relying on existing environment variables.${NC}"
fi

# Set default URL if not specified
if [ -z "$STRUCTURIZR_URL" ]; then
    STRUCTURIZR_URL="https://api.structurizr.com"
fi

# Collect workspace files from the active directory
FILES=()
for FILE in "$WORKSPACES_DIR/active/"*.dsl; do
    if [ -f "$FILE" ]; then
        FILES+=("$FILE")
    fi
done

# Check if any files were found
if [ ${#FILES[@]} -eq 0 ]; then
    echo -e "${RED}No workspace files found in $WORKSPACES_DIR/active${NC}"
    exit 1
else
    echo -e "${BLUE}Workspace files found in $WORKSPACES_DIR/active:${NC}"
    for FILE in "${FILES[@]}"; do
        FILENAME=$(basename "$FILE")
        echo -e "  ${GREEN}$FILENAME${NC}"
    done
fi

# Loop 1: Validate workspaces
echo -e "${BLUE}\nValidating workspaces:${NC}"
VALIDATION_FAILED=0

for FILE in "${FILES[@]}"; do
    FILENAME=$(basename "$FILE")
    ID=$(echo "$FILENAME" | cut -d'-' -f2 | cut -d'.' -f1)
    echo -e "${YELLOW}Validating workspace file: $FILENAME (ID: $ID)${NC}"

    # Get the key and secret for this workspace
#    key_var="STRUCTURIZR_KEY_$ID"
#    secret_var="STRUCTURIZR_SECRET_$ID"
    # Get the key and secret for this workspace
    STRUCTURIZR_KEY=$(yq e ".workspaces[] | select(.id == $ID) | .key" "$CONFIG_FILE")
    STRUCTURIZR_SECRET=$(yq e ".workspaces[] | select(.id == $ID) | .secret" "$CONFIG_FILE")

#    STRUCTURIZR_KEY=${!key_var}
#    STRUCTURIZR_SECRET=${!secret_var}

    if [ -z "$STRUCTURIZR_KEY" ] || [ -z "$STRUCTURIZR_SECRET" ]; then
        echo -e "${RED}Error: Key and/or secret not set for workspace ID $ID. Skipping this workspace.${NC}"
        VALIDATION_FAILED=1
        continue
    fi

    # Display configuration (without exposing sensitive info)
    echo -e "${BLUE}Configuration for workspace ID $ID:${NC}"
    echo -e "  STRUCTURIZR_URL: ${STRUCTURIZR_URL}"
    echo -e "  STRUCTURIZR_KEY: $(mask_variable "$STRUCTURIZR_KEY")"
    echo -e "  STRUCTURIZR_SECRET: $(mask_variable "$STRUCTURIZR_SECRET")"

    # Validate the workspace
    docker run -it --net=host --rm -v "$PWD/workspaces/active":/usr/local/structurizr structurizr/cli validate --workspace "$FILENAME"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Validation failed for $FILENAME${NC}\n"
        VALIDATION_FAILED=1
    else
        echo -e "${GREEN}Validation succeeded for $FILENAME${NC}\n"
    fi
done

# Check if any validation failed
if [ $VALIDATION_FAILED -ne 0 ]; then
    echo -e "${RED}Validation failed for one or more workspaces. Aborting push.${NC}"
    exit 1
else
    echo -e "${GREEN}All validations succeeded.${NC}"
fi

# Loop 2: Push workspaces
echo -e "${BLUE}\nPushing workspaces to Structurizr:${NC}"

for FILE in "${FILES[@]}"; do
    FILENAME=$(basename "$FILE")
    ID=$(echo "$FILENAME" | cut -d'-' -f2 | cut -d'.' -f1)
    echo -e "${YELLOW}Pushing workspace file: $FILENAME (ID: $ID)${NC}"

    # Get the key and secret for this workspace
#    key_var="STRUCTURIZR_KEY_$ID"
#    secret_var="STRUCTURIZR_SECRET_$ID"
#    STRUCTURIZR_KEY=${!key_var}
#    STRUCTURIZR_SECRET=${!secret_var}
    STRUCTURIZR_KEY=$(yq e ".workspaces[] | select(.id == $ID) | .key" "$CONFIG_FILE")
    STRUCTURIZR_SECRET=$(yq e ".workspaces[] | select(.id == $ID) | .secret" "$CONFIG_FILE")

    if [ -z "$STRUCTURIZR_KEY" ] || [ -z "$STRUCTURIZR_SECRET" ]; then
        echo -e "${RED}Error: Key and/or secret not set for workspace ID $ID. Skipping this workspace.${NC}"
        continue
    fi

    # Display configuration (without exposing sensitive info)
    echo -e "${BLUE}Configuration for workspace ID $ID:${NC}"
    echo -e "  STRUCTURIZR_URL: ${STRUCTURIZR_URL}"
    echo -e "  STRUCTURIZR_KEY: $(mask_variable "$STRUCTURIZR_KEY")"
    echo -e "  STRUCTURIZR_SECRET: $(mask_variable "$STRUCTURIZR_SECRET")"

    # Push the workspace
    docker run -it --net=host --rm -v "$PWD":/usr/local/structurizr structurizr/cli push \
        -id "$ID" \
        -key "$STRUCTURIZR_KEY" \
        -secret "$STRUCTURIZR_SECRET" \
        -workspace "$FILE" \
        -merge true \
        -archive=false \
        -url "$STRUCTURIZR_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Push failed for $FILENAME${NC}\n"
        exit 1
    else
        echo -e "${GREEN}Push succeeded for $FILENAME${NC}\n"
    fi
done

echo -e "${GREEN}All workspaces have been successfully applied.${NC}"
