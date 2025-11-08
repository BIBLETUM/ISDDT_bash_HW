#!/usr/bin/env bash

print_usage() {
  cat <<'EOF'
Использование:
  chsuf -d DIR -o OLD_SUFFIX -n NEW_SUFFIX
  chsuf DIR OLD_SUFFIX NEW_SUFFIX

Описание:
  Скрипт рекурсивно ищет обычные файлы в DIR и переименовывает те,
  у которых суффикс (часть после последней точки, например ".txt")
  ровно равен OLD_SUFFIX. Суффикс заменяется на NEW_SUFFIX.

Требования к суффиксам:
  - Начинаются с точки.
  - Не содержат других точек (пример: ".txt", ".md").

Примеры:
  chsuf -d ./docs -о .md -n .markdown
  chsuf ./src .txt .log
EOF
}

DIR=""
OLD=""
NEW=""

if [[ $# -eq 0 ]]; then
  print_usage; exit 2
fi

while getopts ":d:o:n:h" opt; do
  case "$opt" in
    d) DIR=$OPTARG ;;
    o) OLD=$OPTARG ;;
    n) NEW=$OPTARG ;;
    h) print_usage; exit 0 ;;
    \?) echo "Неизвестная опция: -$OPTARG" >&2; print_usage; exit 2 ;;
    :)  echo "Опция -$OPTARG требует значение" >&2; exit 2 ;;
  esac
done
shift $((OPTIND-1))

if [[ -z "${DIR:-}" && $# -ge 1 ]]; then DIR=$1; fi
if [[ -z "${OLD:-}" && $# -ge 2 ]]; then OLD=$2; fi
if [[ -z "${NEW:-}" && $# -ge 3 ]]; then NEW=$3; fi

err() { echo "Ошибка: $*" >&2; exit 2; }

[[ -n "${DIR:-}" ]] || err "нужно указать DIR"
[[ -d "$DIR" ]]      || err "DIR не является каталогом: $DIR"

is_suffix() {
  [[ $1 =~ ^\.[^.]+$ ]]
}

[[ -n "${OLD:-}" ]] && is_suffix "$OLD" || err "OLD_SUFFIX должен соответствовать шаблону '^\.[^.]+$' (получено: '$OLD')"
[[ -n "${NEW:-}" ]] && is_suffix "$NEW" || err "NEW_SUFFIX должен соответствовать шаблону '^\.[^.]+$' (получено: '$NEW')"

get_suffix() {
  local base=$1
  if [[ $base != *.* ]]; then printf ''; return; fi
  local prefix=${base%.*}
  if [[ -z $prefix ]]; then printf ''; return; fi
  printf '.%s' "${base##*.}"
}

shopt -s nullglob dotglob

renamed=0
skipped=0
conflicts=0
errors=0

while IFS= read -r -d '' path; do
  base=${path##*/}
  dirn=${path%/*}
  suffix=$(get_suffix "$base")

  if [[ $suffix != "$OLD" ]]; then
    ((skipped++))
    continue
  fi

  newbase=${base/%"$OLD"/"$NEW"}
  newpath="$dirn/$newbase"

  if [[ -e "$newpath" && "$newpath" != "$path" ]]; then
    echo "ПРОПУЩЕН (цель уже существует): $path -> $newpath" >&2
    ((conflicts++))
    continue
  fi

  if mv -- "$path" "$newpath"; then
    echo "ПЕРЕИМЕНОВАН: $path -> $newpath"
    ((renamed++))
  else
    echo "ОШИБКА (не удалось переместить): $path -> $newpath" >&2
    ((errors++))
  fi
done < <(find "$DIR" -type f -print0)

echo "Готово. Переименовано: $renamed, Пропущено: $skipped, Конфликтов: $conflicts, Ошибок: $errors"
