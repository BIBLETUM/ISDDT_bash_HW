#!/usr/bin/env bash

print_usage() {
  cat <<EOF
Usage:
  $(basename "$0") -d DIR -n NAME

Options:
  -d DIR   Что упаковать (каталог)
  -n NAME  Имя скрипта-распаковщика (будет создан файл ./NAME.sh)
  -h       Показать помощь
EOF
}

SRC_DIR=""
WRAP_NAME=""

while getopts ":d:n:h" opt; do
  case "$opt" in
    d) SRC_DIR="$OPTARG" ;;
    n) WRAP_NAME="$OPTARG" ;;
    h) print_usage; exit 0 ;;
    \?|:) print_usage; exit 2 ;;
  esac
done

[ -n "$SRC_DIR" ]    || { echo "Ошибка: не указан -d DIR"; print_usage; exit 2; }
[ -n "$WRAP_NAME" ]  || { echo "Ошибка: не указан -n NAME"; print_usage; exit 2; }
[ -d "$SRC_DIR" ]    || { echo "Ошибка: каталога '$SRC_DIR' не существует"; exit 2; }
command -v tar  >/dev/null || { echo "Ошибка: не найден 'tar'"; exit 3; }
command -v gzip >/dev/null || { echo "Ошибка: не найден 'gzip'"; exit 3; }

BASENAME="$(basename "$SRC_DIR")"
ARCHIVE="./${BASENAME}.tar.gz"
WRAPPER="./${WRAP_NAME}.command"

tar_opts=(-czf)
if tar --version 2>/dev/null | grep -qi bsdtar; then
  export COPYFILE_DISABLE=1
  tar_opts=(--no-xattrs --no-mac-metadata -czf)
fi

tar "${tar_opts[@]}" "$ARCHIVE" -C "$(dirname "$SRC_DIR")" "$BASENAME"

echo "Создан архив: $ARCHIVE"

read -r -d '' WRAP_SRC <<'WRAP'
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [-o DIR]

Options:
  -o DIR  Куда распаковать (по умолчанию — каталог, где лежит этот .command)
  -h      Помощь
EOF
}

TARGET_DIR=""
while getopts ":o:h" opt; do
  case "$opt" in
    o) TARGET_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?|:) usage; exit 2 ;;
  esac
done

SELF_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

: "${TARGET_DIR:=$SELF_DIR}"
[ -d "$TARGET_DIR" ] || { echo "Нет такого каталога: $TARGET_DIR"; exit 1; }

ARCHIVE_PATH="$SELF_DIR/__ARCHIVE_NAME__"
[ -f "$ARCHIVE_PATH" ] || { echo "Архив не найден: $ARCHIVE_PATH"; exit 1; }

tar -xzf "$ARCHIVE_PATH" -C "$TARGET_DIR"
echo "Готово: распаковано в $TARGET_DIR"

if [ -t 0 ]; then

  read -n 1 -s -r -p "Нажмите любую клавишу, чтобы завершить"; echo
else

  read -n 1 -s -r -p "Нажмите любую клавишу, чтобы завершить" < /dev/tty || true
  echo
fi
WRAP

WRAP_SRC="${WRAP_SRC/__ARCHIVE_NAME__/$(basename "$ARCHIVE")}"
printf '%s\n' "$WRAP_SRC" > "$WRAPPER"
chmod +x "$WRAPPER"

echo "Создан распаковщик: $WRAPPER"
echo "Пример: $WRAPPER -o /tmp"
