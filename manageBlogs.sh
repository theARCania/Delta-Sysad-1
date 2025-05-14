#!/bin/bash

CATEGORIES=("Sports" "Cinema" "Technology" "Travel" "Food" "Lifestyle" "Finance")
BLOG_YAML="blogs.yaml"
BLOG_DIR="$(pwd)/blogs"
PUBLIC_DIR="$(dirname "$BLOG_DIR")/public"

usage() {
  echo "Usage: $0 -p|-a|-d|-e <filename>"
  exit 1
}

get_cat_order() {
  echo "Select category preference (comma separated, e.g., 2,1,3):"
  for i in "${!CATEGORIES[@]}"; do
    echo "$((i+1)): ${CATEGORIES[$i]}"
  done
  read -rp "Enter category order: " input
  echo "$input"
}

update_yaml() {
  yq e -i "$1" "$BLOG_YAML"
}

publish_blog() {
  if [[ ! -f "$BLOG_DIR/$FILENAME" ]]; then
    echo "Blog file does not exist."
    exit 1
  fi

  cat_order_raw=$(get_cat_order)
  cat_order_array=(${cat_order_raw//,/ })

  mkdir -p "$PUBLIC_DIR"
  ln -sf "$BLOG_DIR/$FILENAME" "$PUBLIC_DIR/$FILENAME"
  chmod o+r "$BLOG_DIR/$FILENAME"

  if yq e ".blogs[] | select(.file_name == \"$FILENAME\")" "$BLOG_YAML" > /dev/null; then
    update_yaml "( .blogs[] | select(.file_name == \"$FILENAME\") ).publish_status = true"
    update_yaml "( .blogs[] | select(.file_name == \"$FILENAME\") ).cat_order = [$(IFS=,; echo "${cat_order_array[*]}")]"
  else
    update_yaml ".blogs += [{file_name: \"$FILENAME\", publish_status: true, cat_order: [$(IFS=,; echo "${cat_order_array[*]}")]}]"
  fi
  echo "Published blog: $FILENAME"
}

archive_blog() {
  rm -f "$PUBLIC_DIR/$FILENAME"
  chmod o-r "$BLOG_DIR/$FILENAME" 2>/dev/null || true
  update_yaml "( .blogs[] | select(.file_name == \"$FILENAME\") ).publish_status = false"
  echo "Archived blog: $FILENAME"
}

delete_blog() {
  rm -f "$BLOG_DIR/$FILENAME" "$PUBLIC_DIR/$FILENAME"
  update_yaml ".blogs |= map(select(.file_name != \"$FILENAME\"))"
  echo "Deleted blog: $FILENAME"
}

edit_blog() {
  if ! yq e ".blogs[] | select(.file_name == \"$FILENAME\")" "$BLOG_YAML" > /dev/null; then
    echo "Blog not found in YAML."
    exit 1
  fi
  cat_order_raw=$(get_cat_order)
  cat_order_array=(${cat_order_raw//,/ })
  update_yaml "( .blogs[] | select(.file_name == \"$FILENAME\") ).cat_order = [$(IFS=,; echo "${cat_order_array[*]}")]"
  echo "Updated category order for $FILENAME"
}

# Entry Point
if [[ $# -ne 2 ]]; then usage; fi

CMD="$1"
FILENAME="$2"

case "$CMD" in
  -p) publish_blog ;;
  -a) archive_blog ;;
  -d) delete_blog ;;
  -e) edit_blog ;;
  *) usage ;;
esac

