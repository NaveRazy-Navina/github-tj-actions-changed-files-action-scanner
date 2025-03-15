#!/bin/bash

# Organization details
ORG="<<your org>>"
OUTPUT_DIR="./github_action_logs"
LOG_FILE="GH_LOG.txt"

# Check if GitHub token is set
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "❌ ERROR: Please set your GitHub token using 'export GITHUB_TOKEN=your_token'"
  exit 1
fi

# Ensure output directory exists
mkdir -p $OUTPUT_DIR

# Clear previous log file
> $LOG_FILE

# 🔍 Step 1: Get repositories with workflows using 'tj-actions/changed-files'
echo "🔍 Searching for repositories using 'tj-actions/changed-files'..."
AFFECTED_REPOS=$(gh api "search/code?q=org:$ORG+tj-actions/changed-files+language:YAML+path:.github" --paginate | jq -r '.items[].repository.full_name' | sort -u)

if [[ -z "$AFFECTED_REPOS" ]]; then
  echo "✅ No affected repositories found."
  exit 0
fi

echo "✅ Found affected repositories:"
echo "$AFFECTED_REPOS"

# 🔄 Step 2: Find affected workflows in each repository
for REPO in $AFFECTED_REPOS; do
  echo "🔍 Checking workflows in repository: $REPO"

  # Fetch all workflows in the repository
  WORKFLOWS_JSON=$(gh api "repos/$REPO/actions/workflows")

  # Extract workflow paths
  ALL_WORKFLOWS=$(echo "$WORKFLOWS_JSON" | jq -r '.workflows[].path')

  if [[ -z "$ALL_WORKFLOWS" ]]; then
    echo "✅ No workflows found in $REPO."
    continue
  fi

  for WORKFLOW_PATH in $ALL_WORKFLOWS; do
    echo "🔍 Checking workflow file contents: $WORKFLOW_PATH"

    # Fetch the actual workflow YAML file content
    WORKFLOW_CONTENT=$(gh api "repos/$REPO/contents/$WORKFLOW_PATH" | jq -r '.content' | base64 -d)

    # Check if the workflow uses 'tj-actions/changed-files'
    if ! echo "$WORKFLOW_CONTENT" | grep -q "tj-actions/changed-files"; then
      echo "✅ Workflow does not contain 'tj-actions/changed-files', skipping."
      continue
    fi

    echo "✅ Affected workflow found: $WORKFLOW_PATH"

    # Fetch workflow ID
    WORKFLOW_ID=$(echo "$WORKFLOWS_JSON" | jq -r ".workflows[] | select(.path == \"$WORKFLOW_PATH\") | .id")

    if [[ -z "$WORKFLOW_ID" || "$WORKFLOW_ID" == "null" ]]; then
      echo "❌ ERROR: Could not find workflow ID for $WORKFLOW_PATH in $REPO"
      continue
    fi

    echo "✅ Found workflow ID: $WORKFLOW_ID"

    # Fetch all workflow runs
    RUN_IDS=$(gh api "repos/$REPO/actions/workflows/$WORKFLOW_ID/runs" | jq -r '.workflow_runs[].id')

    if [[ -z "$RUN_IDS" || "$RUN_IDS" == "null" ]]; then
      echo "❌ ERROR: No runs found for workflow $WORKFLOW_PATH"
      continue
    fi

    # 🔄 Step 3: Loop through all run IDs
    for RUN_ID in $RUN_IDS; do
      echo "📥 Fetching logs for run ID: $RUN_ID..."
      RUN_LOG_DIR="$OUTPUT_DIR/$(basename "$WORKFLOW_PATH")/$RUN_ID"
      mkdir -p "$RUN_LOG_DIR"

      # Fetch logs
      LOGS_URL="https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/logs"
      curl -s -H "Authorization: token $GITHUB_TOKEN" -L "$LOGS_URL" -o "$RUN_LOG_DIR/workflow_logs.zip"

      if [[ $? -ne 0 ]]; then
        echo "❌ ERROR: Failed to fetch logs for run ID $RUN_ID"
        continue
      fi

      # Extract logs
      unzip -q "$RUN_LOG_DIR/workflow_logs.zip" -d "$RUN_LOG_DIR"

      # Find "Get changed files" log file
      TARGET_FILE=$(find "$RUN_LOG_DIR" -type f -name "*_Get changed files.txt")

      if [[ -z "$TARGET_FILE" ]]; then
        echo "✅ No 'Get changed files' step found in run $RUN_ID. Skipping."
        continue
      fi

      echo "🔍 Scanning: $TARGET_FILE"

      # Scan only the "Get changed files" log for base64-encoded secrets
      grep -Eo "[A-Za-z0-9+/=]{20,}" "$TARGET_FILE" | while read -r line; do
        # First Base64 decode
        DECODEDLINE=$(echo "$line" | base64 -d 2>/dev/null)

        # Check if the decoded output is also Base64-like
        if [[ "$DECODEDLINE" =~ ^[A-Za-z0-9+/=]{20,}$ ]]; then
          SECOND_DECODED=$(echo "$DECODEDLINE" | base64 -d 2>/dev/null)

          if [[ $? -eq 0 ]]; then
            echo "⚠️ Possible double-encoded Base64 string found in $TARGET_FILE: $SECOND_DECODED"
            echo "⚠️ in $TARGET_FILE: OG line: $line | First Decode: $DECODEDLINE | Second Decode: $SECOND_DECODED" >> "$LOG_FILE"
          fi
        fi
      done
    done
  done
done

echo "✅ Scan completed. Results saved in $LOG_FILE."