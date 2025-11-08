#!/usr/bin/env bash

print_usage() {
  cat <<'EOF'
Usage:
  addline DIR
  addline --path DIR

Описание:
  Без рекурсии обрабатывает только регулярные файлы в каталоге DIR,
  чьё имя оканчивается на ".txt". В начало каждого файла добавляется строка:
    Approved user_name date
  где user_name — логин пользователя, а date — текущая дата в формате ISO 8601.
EOF
}

DIR=""
case "${1-}" in
  "")            print_usage; exit 2 ;;
  --path)        [[ $# -ge 2 ]] || { echo "Ошибка: нет значения для --path" >&2; exit 2; }
                 DIR=$2 ;;
  --path=*)      DIR=${1#--path=} ;;
  *)             DIR=$1 ;;
esac

if [[ ! -d "$DIR" ]]; then
  echo "Ошибка: '$DIR' не каталог" >&2
  exit 2
fi

shopt -s nullglob
shopt -s dotglob

USER_NAME=$(whoami)

if ISO_DATE=$(date --iso-8601=seconds 2>/dev/null); then
  :
elif ISO_DATE=$(date -Iseconds 2>/dev/null); then
  :
else
  ISO_DATE=$(date +"%Y-%m-%dT%H:%M:%S%z")
  ISO_DATE=$(printf '%s' "$ISO_DATE" | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')
fi

HEADER_LINE="Approved ${USER_NAME} ${ISO_DATE}"

processed=0
for f in "$DIR"/*.txt; do
  [[ -f "$f" ]] || continue

  tmp=$(mktemp "$DIR/.addline.XXXXXX") || { echo "Ошибка: mktemp" >&2; exit 2; }

  {
    printf '%s\n' "$HEADER_LINE"
    cat -- "$f"
  } > "$tmp"

  if perms=$(stat -f '%OLp' "$f" 2>/dev/null); then
    chmod "$perms" "$tmp" 2>/dev/null || true
  elif perms=$(stat -c '%a' "$f" 2>/dev/null); then
    chmod "$perms" "$tmp" 2>/dev/null || true
  fi

  if owner=$(stat -f '%u' "$f" 2>/dev/null) && group=$(stat -f '%g' "$f" 2>/dev/null); then
    chown "$owner:$group" "$tmp" 2>/dev/null || true
  elif owner=$(stat -c '%u' "$f" 2>/dev/null) && group=$(stat -c '%g' "$f" 2>/dev/null); then
    chown "$owner:$group" "$tmp" 2>/dev/null || true
  fi

  touch -r "$f" "$tmp" 2>/dev/null || true
  mv -f -- "$tmp" "$f"

  ((processed++))
done

if (( processed == 0 )); then
  echo "Нет подходящих .txt файлов для обработки в каталоге: $DIR"
  exit 1
fi

echo "Готово. Обработано файлов: $processed"
exit 0
