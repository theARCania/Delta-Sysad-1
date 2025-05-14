#!/bin/bash

MOD_HOME=$(eval echo ~$USER)
BLACKLIST="$MOD_HOME/blacklist.txt"

if [[ ! -f "$BLACKLIST" ]]; then
  echo "No blacklist.txt found in $MOD_HOME"
  exit 1
fi

PUBLIC_BASE="/home/authors"
MOD_SYMLINKS="/home/mods/$USER"

for author in "$MOD_SYMLINKS"/*; do
  [ -L "$author" ] || continue
  BLOG_FILE=$(readlink -f "$author")
  AUTHOR_NAME=$(basename "$(dirname "$BLOG_FILE")")
  BLOG_NAME=$(basename "$BLOG_FILE")
  AUTHOR_DIR="$PUBLIC_BASE/$AUTHOR_NAME"
  BLOG_PATH="$AUTHOR_DIR/public/$BLOG_NAME"
  BLOG_YAML="$AUTHOR_DIR/../blogs.yaml"

  temp_file=$(mktemp)
  cp "$BLOG_PATH" "$temp_file"
  total_hits=0

  while IFS= read -r word; do
    word_regex="\\b${word}\\b"
    lc_word=$(echo "$word" | tr '[:upper:]' '[:lower:]')
    match_lines=$(grep -in -o -P "(?i)$word" "$BLOG_PATH" || true)

    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      line_no=$(echo "$match" | cut -d: -f1)
      found_word=$(echo "$match" | cut -d: -f3)
      echo "Found blacklisted word $found_word in $BLOG_NAME at line $line_no"
      total_hits=$((total_hits+1))
    done <<< "$match_lines"

    # Replace all instances in file (case-insensitive, exact-length asterisks)
    sed -E -i "s/($word)/$(printf "%${#word}s" | tr ' ' '*')/Ig" "$temp_file"
  done < "$BLACKLIST"

  if [[ $total_hits -gt 5 ]]; then
    echo "Blog $BLOG_NAME is archived due to excessive blacklisted words"
    rm -f "$MOD_SYMLINKS/$BLOG_NAME"
    mv "$temp_file" "$BLOG_PATH"  # Apply replacements before archiving

    if [[ -f "$BLOG_YAML" ]]; then
      yq e -i "( .blogs[] | select(.file_name == \"$BLOG_NAME\") ).publish_status = false" "$BLOG_YAML"
      yq e -i "( .blogs[] | select(.file_name == \"$BLOG_NAME\") ).mod_comments = \"found $total_hits blacklisted words\"" "$BLOG_YAML"
    fi

    chmod o-r "$BLOG_PATH"
  else
    mv "$temp_file" "$BLOG_PATH"
  fi
done

