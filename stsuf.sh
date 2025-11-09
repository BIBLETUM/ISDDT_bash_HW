#!/usr/bin/env bash

print_usage() {
  cat <<'EOF'
Usage:
  stsuf DIR
  stsuf --path DIR

Скрипт рекурсивно находит регулярные файлы и выводит статистику по суффиксам,
сортируя по убыванию количества. "no suffix" — файлы без суффикса.
EOF
}

DIR=""
if [[ $# -eq 1 ]]; then
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    print_usage; exit 0
  elif [[ "$1" == --path=* ]]; then
    DIR=${1#--path=}
  elif [[ "$1" == "--path" ]]; then
    echo "Ошибка: нет значения для --path" >&2; exit 2
  else
    DIR=$1
  fi
elif [[ $# -eq 2 && "$1" == "--path" ]]; then
  DIR=$2
else
  print_usage; exit 2
fi

if [[ -z "$DIR" || ! -d "$DIR" ]]; then
  echo "Ошибка: '$DIR' не является каталогом." >&2
  exit 2
fi

declare -A CNT

get_suffix() {
  local base=$1
  local prefix="${base%.*}"
  local tail="${base##*.}"
  if [[ "$tail" == "$base" ]]; then echo ""; return; fi
  if [[ -z "$tail" ]]; then echo ""; return; fi
  if [[ -z "$prefix" && "$base" == .* ]]; then echo ""; return; fi
  echo ".${tail}"
}

while IFS= read -r -d '' path; do
  base=$(basename -- "$path")
  suf=$(get_suffix "$base")
  if [[ -z "$suf" ]]; then
    (( CNT["no suffix"]++ )) || true
  else
    (( CNT["$suf"]++ )) || true
  fi
done < <(find "$DIR" -type f ! -iname '.DS_Store' -print0)

{
  for key in "${!CNT[@]}"; do
    printf "%s\t%d\n" "$key" "${CNT[$key]}"
  done
} | LC_ALL=C sort -t $'\t' -k2,2nr -k1,1 \
  | awk -F'\t' '{ printf "%s: %d\n", $1, $2 }'
