#!/bin/bash

ADMIN_LIST=("mukundk" "jey")
CATEGORIES=( "" "Sports" "Cinema" "Technology" "Travel" "Food" "Lifestyle" "Finance" )

if [[ ! " ${ADMIN_LIST[*]} " =~ " ${USER} " ]]; then
  echo "Permission denied: Only admins can run this script"
  exit 1
fi

REPORT_FILE="/home/admin/admin_report.txt"
echo "Admin Report - $(date)" > "$REPORT_FILE"
echo "----------------------------------" >> "$REPORT_FILE"

declare -A published
declare -A deleted
declare -A readcounts

# Loop over all authors
for author_dir in /home/authors/*; do
  [[ -d "$author_dir" ]] || continue
  blog_yaml="$author_dir/blogs.yaml"
  [[ -f "$blog_yaml" ]] || continue
  author=$(basename "$author_dir")

  total_blogs=$(yq eval '.blogs | length' "$blog_yaml")
  for ((i = 0; i < total_blogs; i++)); do
    blog=$(yq ".blogs[$i]" "$blog_yaml")
    fname=$(echo "$blog" | yq '.file_name')
    status=$(echo "$blog" | yq '.publish_status')
    cats=($(echo "$blog" | yq '.cat_order[]'))

    for cat in "${cats[@]}"; do
      category="${CATEGORIES[$cat]}"
      if [[ "$status" == "true" ]]; then
        ((published["$category"]++))
      else
        ((deleted["$category"]++))
      fi
    done

    # Read count
    log_file="$author_dir/.readlog_$fname"
    if [[ -f "$log_file" ]]; then
      count=$(<"$log_file")
      readcounts["$author/$fname"]=$count
    fi
  done
done

# Sort and print published articles
echo -e "\nPublished Articles by Category:" >> "$REPORT_FILE"
for cat in "${!published[@]}"; do
  echo "$cat: ${published[$cat]}" >> "$REPORT_FILE"
done

# Sort and print deleted articles
echo -e "\nDeleted Articles by Category:" >> "$REPORT_FILE"
for cat in "${!deleted[@]}"; do
  echo "$cat: ${deleted[$cat]}" >> "$REPORT_FILE"
done

# Top 3 most read
echo -e "\nTop 3 Most Read Articles:" >> "$REPORT_FILE"
for entry in "${!readcounts[@]}"; do
  echo "$entry ${readcounts[$entry]}"
done | sort -k2 -nr | head -3 >> "$REPORT_FILE"

echo -e "\nReport saved to $REPORT_FILE"


# Check for first/last Saturday if today is Saturday
if [[ $(date +%u) -eq 6 ]]; then
  day=$(date +%-d)
  last_day=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%-d)

  if [[ "$day" -ne 1 && "$day" -lt "$((last_day - 6))" ]]; then
    exit 0
  fi
fi

