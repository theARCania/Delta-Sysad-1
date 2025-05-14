#!/bin/bash

AUTHOR="$USER"
AUTHOR_DIR="/home/authors/$AUTHOR"
SUBSCRIPTIONS_FILE="/home/admin/subscriptions.yaml"

if [[ "$1" != "-f" || -z "$2" || "$3" != "-m" || -z "$4" ]]; then
  echo "Usage: $0 -f <filename> -m <mode: public | subscribers>"
  exit 1
fi

FILENAME="$2"
MODE="$4"
BLOG_FILE="$AUTHOR_DIR/$FILENAME"

if [[ ! -f "$BLOG_FILE" ]]; then
  echo "File not found!"
  exit 1
fi

if [[ "$MODE" != "public" && "$MODE" != "subscribers" ]]; then
  echo "Invalid mode. Use 'public' or 'subscribers'"
  exit 1
fi

if [[ "$MODE" == "public" ]]; then
  ln -sf "$BLOG_FILE" "/home/public/$AUTHOR-$FILENAME"
  echo "Published $FILENAME as public"
else
  # deliver to each subscriber
  for user in $(yq eval '.subscriptions | keys | .[]' "$SUBSCRIPTIONS_FILE"); do
    authors=$(yq eval ".subscriptions.$user[]" "$SUBSCRIPTIONS_FILE")
    if echo "$authors" | grep -q "$AUTHOR"; then
      user_dir="/home/users/$user/subscribed_blogs"
      mkdir -p "$user_dir"
      ln -sf "$BLOG_FILE" "$user_dir/$AUTHOR-$FILENAME"
    fi
  done
  echo "Published $FILENAME as subscribers-only"
fi

