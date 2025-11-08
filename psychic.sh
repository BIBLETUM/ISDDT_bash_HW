#!/usr/bin/env bash

RED='\033[31m'
GREEN='\033[32m'
RESET='\033[0m'

declare -i step=-1 hits=0 misses=0 total=0

declare -a history=()

print_last_history() {
  local -i N="${1:-10}"
  local -i len=${#history[@]}

  local -i start=0
  if (( len > N )); then
    start=$(( len - N ))
  fi

  printf "Numbers: "

  for (( i=start; i<len; i++ )); do
    printf '%b' "${history[i]}"
    if (( i < len - 1 )); then
      printf ' '
    fi
  done

  printf '\n'
}

while :; do
  number=$(( RANDOM % 10 ))

  while :; do

    if (( step + 1 >= 1 )); then
      echo "Step: $(( step + 1 ))"
    fi

    read -rp "Please enter number from 0 to 9 (q - quit): " input
    case "$input" in
      q) exit 0 ;;
      [0-9]) break ;;
      *) echo "Invalid input. Try again." ;;
    esac
  done

  step+=1

  if [[ "$input" == "$number" ]]; then
    echo "Hit! My number: $number"
    hits+=1
    history+=( "${GREEN}${number}${RESET}" )
  else
    echo "Miss! My number: $number"
    misses+=1
    history+=( "${RED}${number}${RESET}" )
  fi

  total=$(( hits + misses ))
  hit_percent=$(( hits * 100 / total ))
  miss_percent=$(( 100 - hit_percent ))

  echo "Hit: ${hit_percent}% Miss: ${miss_percent}%"

  print_last_history 10
done
