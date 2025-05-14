#!/bin/bash

YAML_FILE="users.yaml"

# Groups
declare -A GROUPS=(
  ["users"]="g_user"
  ["authors"]="g_author"
  ["mods"]="g_mod"
  ["admins"]="g_admin"
)

# Home directories
declare -A HOME_DIRS=(
  ["users"]="/home/users"
  ["authors"]="/home/authors"
  ["mods"]="/home/mods"
  ["admins"]="/home/admin"
)

# Ensure groups exist
for group in "${GROUPS[@]}"; do
  getent group "$group" > /dev/null || groupadd "$group"
done

# Ensure base home dirs exist
for dir in "${HOME_DIRS[@]}"; do
  mkdir -p "$dir"
done

# Create users
users=$(yq e '.users[].username' "$YAML_FILE")
for username in $users; do
  useradd -m -d "/home/users/$username" -g g_user "$username" 2>/dev/null || true
  mkdir -p "/home/users/$username/all_blogs"
  chmod 700 "/home/users/$username"
  chown "$username:g_user" "/home/users/$username" -R
done

# Create authors
authors=$(yq e '.authors[].username' "$YAML_FILE")
for username in $authors; do
  useradd -m -d "/home/authors/$username" -g g_author "$username" 2>/dev/null || true
  mkdir -p "/home/authors/$username/blogs" "/home/authors/$username/public"
  chmod 700 "/home/authors/$username"
  chmod 755 "/home/authors/$username/public"
  chown "$username:g_author" "/home/authors/$username" -R
done

# Create mods
mod_count=$(yq e '.mods | length' "$YAML_FILE")
for ((i=0; i<mod_count; i++)); do
  modname=$(yq e ".mods[$i].username" "$YAML_FILE")
  useradd -m -d "/home/mods/$modname" -g g_mod "$modname" 2>/dev/null || true
  chmod 700 "/home/mods/$modname"
  chown "$modname:g_mod" "/home/mods/$modname" -R

  assigned_authors=$(yq e ".mods[$i].authors[]" "$YAML_FILE")
  for author in $assigned_authors; do
    setfacl -m u:$modname:rwX "/home/authors/$author/public"
  done
done

# Create admins
admins=$(yq e '.admins[].username' "$YAML_FILE")
for username in $admins; do
  useradd -m -d "/home/admin/$username" -g g_admin "$username" 2>/dev/null || true
  chmod 700 "/home/admin/$username"
  chown "$username:g_admin" "/home/admin/$username" -R

  for dir in /home/users /home/authors /home/mods; do
    setfacl -Rm u:$username:rwx "$dir"
  done
done

# Setup all_blogs symlinks for users
for username in $users; do
  blog_dir="/home/users/$username/all_blogs"
  rm -f "$blog_dir"/* 2>/dev/null
  for author in $authors; do
    ln -sfn "/home/authors/$author/public" "$blog_dir/$author"
  done
  chmod -R 555 "$blog_dir"
done

