#!/bin/bash

REQ_FILE="/admin/requests.yaml"
AUTHORS_HOME="/home/authors"
ALL_BLOGS="/home/all_blogs"

[ -f "$REQ_FILE" ] || { echo "No requests file found."; exit 1; }

mapfile -t USERS < <(grep "^- " "$REQ_FILE" | sed 's/^- //')

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "No pending requests."
    exit 0
fi

for USERNAME in "${USERS[@]}"; do
    echo "Approve $USERNAME as author? [y/n]"
    read -r RESPONSE
    if [[ "$RESPONSE" == "y" ]]; then
        USER_HOME="/home/$USERNAME"
        NEW_HOME="$AUTHORS_HOME/$USERNAME"
        sudo usermod -g g_author "$USERNAME"
        sudo mkdir -p "$NEW_HOME/blogs" "$NEW_HOME/public"
        sudo mv "$USER_HOME" "$NEW_HOME"
        sudo ln -s "$NEW_HOME/public" "$ALL_BLOGS/$USERNAME"
        echo "$USERNAME approved and moved to authors."
    else
        echo "$USERNAME request rejected."
    fi
    # Remove processed request
    sudo sed -i "/^- $USERNAME/d" "$REQ_FILE"
done

