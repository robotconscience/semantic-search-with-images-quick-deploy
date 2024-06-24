#!/bin/sh
set -e

echo "--- ⏳ | Post-provisioning | Setup environment ---"

# Load azd .env file from the current environment
while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

# Get the source AI Search query key from KV
export SOURCE_AI_SEARCH_KEY=$(az keyvault secret show --name "$SOURCE_AI_SEARCH_KEY_SECRET_NAME" --vault-name "$KEYVAULT_NAME" --query "value" -o tsv)
export TARGET_AI_SEARCH_KEY=$(az search admin-key show --resource-group "$AZURE_RESOURCE_GROUP" --service-name "$TARGET_AI_SEARCH_NAME" --query "primaryKey" -o tsv)

echo "--- ⏳ | Post-provisioning | Build and run migration tool ---"

# Expecting from environment:
#   - SOURCE_AI_SEARCH_ENDPOINT
#   - SOURCE_AI_SEARCH_KEY
#   - SOURCE_AI_SEARCH_INDEX_NAME
#   - TARGET_AI_SEARCH_ENDPOINT
dotnet run --project "src/migration-tool/AiSearchMigrationTool.csproj" \
    --sourcesearchendpoint "$SOURCE_AI_SEARCH_ENDPOINT" \
    --sourcesearchkey "$SOURCE_AI_SEARCH_KEY" \
    --sourcesearchindexname "$SOURCE_AI_SEARCH_INDEX_NAME" \
    --targetsearchendpoint "$TARGET_AI_SEARCH_ENDPOINT" \
    --targetsearchkey "$TARGET_AI_SEARCH_KEY"

echo "--- ✅ | Post-provisioning | Completed! ---"
