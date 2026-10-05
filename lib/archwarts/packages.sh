#!/usr/bin/env bash

archwarts_package_manifest() {
  local source_root=$1 group=$2

  case $group in
    core|default|optional|remove)
      printf '%s/packages/%s.packages\n' "$source_root" "$group"
      ;;
    *)
      printf 'Unknown package group: %s\n' "$group" >&2
      return 2
      ;;
  esac
}

archwarts_packages() {
  local source_root=$1 group=$2 manifest line package

  manifest=$(archwarts_package_manifest "$source_root" "$group") || return
  [[ -r $manifest ]] || {
    printf 'Missing package manifest: %s\n' "$manifest" >&2
    return 1
  }

  while IFS= read -r line || [[ -n $line ]]; do
    package=${line%%#*}
    package=${package//[[:space:]]/}
    [[ -n $package ]] && printf '%s\n' "$package"
  done <"$manifest"
}

archwarts_validate_package_manifest() {
  local source_root=$1 group=$2 package
  local -A seen=()

  while IFS= read -r package; do
    [[ $package =~ ^[a-z0-9@._+-]+$ ]] || {
      printf 'Invalid package name in %s: %s\n' "$group" "$package" >&2
      return 1
    }
    [[ -z ${seen[$package]:-} ]] || {
      printf 'Duplicate package in %s: %s\n' "$group" "$package" >&2
      return 1
    }
    seen[$package]=1
  done < <(archwarts_packages "$source_root" "$group")
}

archwarts_package_plan() {
  local source_root=$1 profile=${2:-default} group package
  local -a groups=(core)
  local -A seen=()

  case $profile in
    minimal) ;;
    default) groups+=(default) ;;
    *)
      printf 'Unknown package profile: %s\n' "$profile" >&2
      return 2
      ;;
  esac

  for group in "${groups[@]}"; do
    while IFS= read -r package; do
      [[ -n ${seen[$package]:-} ]] && continue
      seen[$package]=1
      printf '%s\n' "$package"
    done < <(archwarts_packages "$source_root" "$group")
  done
}

archwarts_package_source() {
  local source_root=$1 requested_package=$2 package source _reason

  while IFS=$'\t' read -r package source _reason; do
    [[ $package == package ]] && continue
    if [[ $package == "$requested_package" ]]; then
      printf '%s\n' "$source"
      return
    fi
  done <"$source_root/packages/sources.tsv"

  printf '%s\n' official
}
