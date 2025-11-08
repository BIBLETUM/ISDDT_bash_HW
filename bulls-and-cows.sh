#!/usr/bin/env bash

interrupted=0
on_sigint() {

  printf '\nНажат Ctrl+C. Чтобы выйти, введите q или Q и нажмите Enter.\n' >&2
  interrupted=1
}
trap on_sigint INT

gen_secret() {
  local digits=(0 1 2 3 4 5 6 7 8 9) secret="" pick i
  while :; do
    pick=$(( RANDOM % 10 ))
    (( pick != 0 )) || continue
    secret="${pick}"
    digits[$pick]=""
    break
  done
  for i in 1 2 3; do
    while :; do
      pick=$(( RANDOM % 10 ))
      [[ -n "${digits[$pick]}" ]] || continue
      secret+="${pick}"
      digits[$pick]=""
      break
    done
  done
  printf '%s' "$secret"
}

is_valid_guess() {
  local s="$1"
  [[ "$s" =~ ^[0-9]{4}$ ]] || return 1
  [[ "${s:0:1}" != "0" ]]   || return 1
  local a b c d
  a="${s:0:1}"; b="${s:1:1}"; c="${s:2:1}"; d="${s:3:1}"
  [[ "$a" != "$b" && "$a" != "$c" && "$a" != "$d" && "$b" != "$c" && "$b" != "$d" && "$c" != "$d" ]]
}

score_bc() {
  local secret="$1" guess="$2" bulls=0 cows=0 i j gs ss
  for i in 0 1 2 3; do
    gs="${guess:$i:1}"; ss="${secret:$i:1}"
    (( gs == ss )) && (( bulls++ ))
  done
  for i in 0 1 2 3; do
    gs="${guess:$i:1}"
    [[ "$gs" == "${secret:$i:1}" ]] && continue
    for j in 0 1 2 3; do
      [[ $i -eq $j ]] && continue
      ss="${secret:$j:1}"
      if [[ "$gs" == "$ss" ]]; then
        (( cows++ ))
        break
      fi
    done
  done
  printf '%s %s' "$bulls" "$cows"
}

printf '%s\n' \
"********************************************************************************" \
"* Я загадал 4-значное число с неповторяющимися цифрами. Для выхода — q или Q.  *" \
"********************************************************************************"

secret="$(gen_secret)"
echo "[DEBUG] secret=$secret" 1>&2

declare -i attempt=0
declare -a history=()

while :; do
  printf 'Попытка %d: ' "$((attempt + 1))"

  if ! read -r guess; then

    if (( interrupted )); then
      interrupted=0
      continue
    fi

    printf 'Ошибка ввода. Попробуйте ещё раз.\n' >&2
    continue
  fi

  [[ "$guess" == "q" || "$guess" == "Q" ]] && {
    printf 'Игра окончена. Загаданное число было: %s\n' "$secret"
    exit 1
  }

  if ! is_valid_guess "$guess"; then
    printf 'Ошибка: нужно ровно 4 уникальные цифры, первая — не 0. Попробуйте снова.\n'
    continue
  fi

  attempt=$((attempt + 1))

  read -r bulls cows < <(score_bc "$secret" "$guess")
  printf 'Коров - %d, Быков - %d\n\n' "$cows" "$bulls"

  history+=( "$(printf '%d. %s (Коров - %d Быков - %d)' "$attempt" "$guess" "$cows" "$bulls")" )

  printf 'История ходов:\n'
  for line in "${history[@]}"; do
    printf '%s\n' "$line"
  done
  printf '\n'

  if (( bulls == 4 )); then
    printf 'Поздравляю! Вы отгадали число за %d ход(ов).\n' "$attempt"
    exit 0
  fi
done
