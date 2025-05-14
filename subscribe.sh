#!/bin/bash

USER_HOME="/home/users/$USER"
SUBSCRIPTIONS_FILE="/home/admin/subscriptions.yaml"
mkdir -p "$USER_HOME/subscribed_blogs"

if [[ "$1" != "-a" || -z "$2" ]]; then
  echo "Usage: $0 -a <author_username>"
  exit 1
fi

author="$2"
# Check if author exists
if [[ ! -d "/home/authors/$author" ]]; then
  echo "Author does not exist"
  exit 1
fi

# Add subscription
if ! yq eval ".subscriptions.$USER" "$SUBSCRIPTIONS_FILE" &>/dev/null; then
  yq eval ".subscriptions.$USER = []" -i "$SUBSCRIPTIONS_FILE"
fi

if yq eval ".subscriptions.$USER | index(\"$author\")" "$SUBSCRIPTIONS_FILE" &>/dev/null; then
  echo "Already subscribed to $author"
else
  yq eval ".subscriptions.$USER += [\"$author\"]" -i "$SUBSCRIPTIONS_FILE"
  echo "Subscribed to $author"
fi

