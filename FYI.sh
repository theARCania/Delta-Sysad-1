#!/bin/bash

ADMIN_LIST=("mukundk" "jey")
CATEGORIES=(
  "" "Sports" "Cinema" "Technology" "Travel" "Food" "Lifestyle" "Finance"
)

if [[ ! " ${ADMIN_LIST[*]} " =~ " ${USER} " ]]; then
  echo "Permission denied: Only admins can run this script"
  exit 1
fi

USERPREF="userpref.yaml"
declare -A BLOG_POOL
declare -A USER_PREFS
declare -A BLOG_ASSIGNMENT_COUNT

# Collect all blogs
while IFS= read -r author_dir; do
  [[ -f "$author_dir/blogs.yaml" ]] || continue
  author=$(basename "$author_dir")
  mapfile -t blogs < <(yq '.blogs[] | select(.publish_status == true)' "$author_dir/blogs.yaml")

  for ((i = 0; i < ${#blogs[@]}; i++)); do
    blog=$(yq ".blogs[$i]" "$author_dir/blogs.yaml")
    file_name=$(echo "$blog" | yq '.file_name')
    categories=($(echo "$blog" | yq '.cat_order[]'))
    blog_key="$author/$file_name"
    BLOG_POOL["$blog_key"]="${categories[*]}"
    BLOG_ASSIGNMENT_COUNT["$blog_key"]=0
  done
done < <(find /home/authors -maxdepth 1 -mindepth 1 -type d)

# Read user preferences
mapfile -t usernames < <(yq '.users[].username' "$USERPREF")
for username in "${usernames[@]}"; do
  pref1=$(yq ".users[] | select(.username == \"$username\") | .pref1" "$USERPREF")
  pref2=$(yq ".users[] | select(.username == \"$username\") | .pref2" "$USERPREF")
  pref3=$(yq ".users[] | select(.username == \"$username\") | .pref3" "$USERPREF")
  USER_PREFS["$username"]="$pref1,$pref2,$pref3"
done

# Assign blogs to users
declare -A USER_FYI

for username in "${usernames[@]}"; do
  IFS=',' read -r p1 p2 p3 <<< "${USER_PREFS[$username]}"
  declare -A matched
  for blog in "${!BLOG_POOL[@]}"; do
    IFS=' ' read -r -a cat_ids <<< "${BLOG_POOL[$blog]}"
    categories=("${CATEGORIES[${cat_ids[0]}]}" "${CATEGORIES[${cat_ids[1]}]}" "${CATEGORIES[${cat_ids[2]}]}")
    
    match_score=0
    [[ "${categories[*]}" =~ $p1 ]] && ((match_score++))
    [[ "${categories[*]}" =~ $p2 ]] && ((match_score++))
    [[ "${categories[*]}" =~ $p3 ]] && ((match_score++))

    [[ $match_score -gt 0 ]] && matched["$blog"]=$match_score
  done

  # Sort by match score and then by current assignment count (ascending)
  best_matches=$(for blog in "${!matched[@]}"; do
    echo "$blog ${matched[$blog]} ${BLOG_ASSIGNMENT_COUNT[$blog]}"
  done | sort -k2,2nr -k3,3n | head -n 10)

  USER_FYI["$username"]=""
  count=0

  while IFS= read -r line && [[ $count -lt 3 ]]; do
    blog=$(echo "$line" | awk '{print $1}')
    USER_FYI["$username"]+="$blog"$'\n'
    ((BLOG_ASSIGNMENT_COUNT["$blog"]++))
    ((count++))
  done <<< "$best_matches"
done

# Write FYI.yaml for each user
for username in "${!USER_FYI[@]}"; do
  user_dir="/home/users/$username"
  mkdir -p "$user_dir"
  FYI_FILE="$user_dir/FYI.yaml"
  echo "blogs:" > "$FYI_FILE"

  while IFS= read -r blog; do
    [[ -z "$blog" ]] && continue
    author=$(cut -d/ -f1 <<< "$blog")
    file=$(cut -d/ -f2 <<< "$blog")
    echo "  - author: $author" >> "$FYI_FILE"
    echo "    file: $file" >> "$FYI_FILE"
  done <<< "${USER_FYI[$username]}"
done

echo "FYI pages updated for all users."

