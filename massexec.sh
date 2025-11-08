#!/usr/bin/env bash

print_usage() {
  cat <<'EOF'
Usage:
  massexec.sh [--path dirpath] [--mask mask] [--number number] command

Options:
  --path dirpath   Каталог с файлами (по умолчанию текущий).
  --mask mask      Bash-шаблон имени (по умолчанию '*').
  --number number  Макс. число одновременных процессов (>0). По умолчанию — число CPU (или 1).
EOF
}


DIRPATH="."
MASK="*"
NUMBER=""

detect_cpus() {
  if getconf _NPROCESSORS_ONLN >/dev/null 2>&1; then
    getconf _NPROCESSORS_ONLN
    return
  fi
  if command -v nproc >/dev/null 2>&1; then
    nproc
    return
  fi
  if [[ "$(uname -s)" == "Darwin" ]] && command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.ncpu
    return
  fi
  echo 1
}


while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)   [[ $# -ge 2 ]] || { echo "Нет значения для --path" >&2; exit 2; }; DIRPATH=$2; shift 2;;
    --mask)   [[ $# -ge 2 ]] || { echo "Нет значения для --mask" >&2; exit 2; }; MASK=$2;   shift 2;;
    --number) [[ $# -ge 2 ]] || { echo "Нет значения для --number" >&2; exit 2; }; NUMBER=$2; shift 2;;
    -h|--help) print_usage; exit 0;;
    --) shift; break;;
    *) break;;
  esac
done

if [[ $# -ne 1 ]]; then
  echo "Ошибка: нужен ровно один аргумент command." >&2
  print_usage
  exit 2
fi
COMMAND_RAW=$1

[[ -d "$DIRPATH" ]] || { echo "Ошибка: --path '$DIRPATH' не каталог." >&2; exit 2; }
DIR_ABS=$(cd "$DIRPATH" 2>/dev/null && pwd -P) || { echo "Не удалось получить абсолютный путь." >&2; exit 2; }
[[ -n "$MASK" ]] || { echo "Ошибка: --mask пуст." >&2; exit 2; }

if [[ -z "$NUMBER" ]]; then
  NUMBER="$(detect_cpus)"
fi
[[ "$NUMBER" =~ ^[1-9][0-9]*$ ]] || { echo "Ошибка: --number должен быть целым > 0." >&2; exit 2; }

if [[ -x "$COMMAND_RAW" && ! -d "$COMMAND_RAW" ]]; then
  COMMAND_PATH="$COMMAND_RAW"
else
  COMMAND_PATH=$(command -v -- "$COMMAND_RAW" 2>/dev/null) \
    || { echo "Ошибка: command '$COMMAND_RAW' не найден в PATH." >&2; exit 2; }
  [[ -x "$COMMAND_PATH" ]] || { echo "Ошибка: '$COMMAND_PATH' не исполняем." >&2; exit 2; }
fi

shopt -s nullglob dotglob
matches=( "$DIR_ABS"/$MASK )
FILES=()
for path in "${matches[@]}"; do
  [[ -f "$path" ]] && FILES+=( "$path" )
done
(( ${#FILES[@]} > 0 )) || exit 0

pids=()
failures=0

wait_any() {
  if wait -n 2>/dev/null; then
    return $?
  fi
  while :; do
    for pid in "${pids[@]}"; do
      if ! kill -0 "$pid" 2>/dev/null; then
        wait "$pid"
        return $?
      fi
    done
    sleep 0.05
  done
}

start_job() {
  local file="$1"
  echo "Running: $COMMAND_PATH \"$file\" &"
  (
    "$COMMAND_PATH" "$file"
  ) &
  local cpid=$!
  echo "Started: PID=$cpid FILE=$file"
  pids+=( "$cpid" )
}


running=0
for f in "${FILES[@]}"; do
  start_job "$f"
  (( running++ ))
  if (( running >= NUMBER )); then
    if ! wait_any; then (( failures++ )); fi
    (( running-- ))
  fi
done

while (( running > 0 )); do
  if ! wait_any; then (( failures++ )); fi
  (( running-- ))
done

(( failures > 0 )) && exit 1 || exit 0
