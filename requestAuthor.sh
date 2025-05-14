#!/bin/bash
USERNAME="$USER"
REQ_FILE="/admin/requests.yaml"

# Ensure only one request per user
if grep -q "^- $USERNAME" "$REQ_FILE" 2>/dev/null; then
    echo "You already have a pending request."
    exit 1
fi

echo "- $USERNAME" | sudo tee -a "$REQ_FILE" > /dev/null
echo "Request submitted to become an author."

