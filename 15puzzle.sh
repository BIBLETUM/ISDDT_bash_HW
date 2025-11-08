#!/usr/bin/env bash

HLINE="+-------------------+"
RSEP="|-------------------|"

trap 'echo; echo "Завершить игру можно, введя символ q. Продолжаем...";' INT

BOARD=()
TURN=1

print_board() {
  echo
  printf "Ход № %d\n\n" "$TURN"
  echo "$HLINE"
  local r c v
  for r in 0 1 2 3; do
    printf "|"
    for c in 0 1 2 3; do
      v=${BOARD[$((r*4+c))]}
      if [ "$v" -eq 0 ]; then
        printf "    |"
      else
        printf " %2d |" "$v"
      fi
    done
    echo
    if [ "$r" -lt 3 ]; then echo "$RSEP"; fi
  done
  echo "$HLINE"
  echo
}

find_empty_idx() {
  local i
  for i in "${!BOARD[@]}"; do
    [ "${BOARD[$i]}" -eq 0 ] && { echo "$i"; return; }
  done
  echo -1
}

get_movable_values() {
  local z="$1" r=$((z/4)) c=$((z%4)) vals=()
  [ "$c" -gt 0 ] && vals+=( "${BOARD[$((r*4+c-1))]}" )
  [ "$r" -gt 0 ] && vals+=( "${BOARD[$(((r-1)*4+c))]}" )
  [ "$c" -lt 3 ] && vals+=( "${BOARD[$((r*4+c+1))]}" )
  [ "$r" -lt 3 ] && vals+=( "${BOARD[$(((r+1)*4+c))]}" )
  echo "${vals[*]}"
}

try_move_value() {
  local val="$1"
  local z r c idx
  z=$(find_empty_idx)
  r=$((z/4)); c=$((z%4))

  if [ "$c" -gt 0 ]; then idx=$((r*4+c-1)); [ "${BOARD[$idx]}" -eq "$val" ] && { BOARD[$z]="$val"; BOARD[$idx]=0; return 0; }; fi
  if [ "$r" -gt 0 ]; then idx=$(((r-1)*4+c)); [ "${BOARD[$idx]}" -eq "$val" ] && { BOARD[$z]="$val"; BOARD[$idx]=0; return 0; }; fi
  if [ "$c" -lt 3 ]; then idx=$((r*4+c+1)); [ "${BOARD[$idx]}" -eq "$val" ] && { BOARD[$z]="$val"; BOARD[$idx]=0; return 0; }; fi
  if [ "$r" -lt 3 ]; then idx=$(((r+1)*4+c)); [ "${BOARD[$idx]}" -eq "$val" ] && { BOARD[$z]="$val"; BOARD[$idx]=0; return 0; }; fi
  return 1
}

is_solved() {
  local i
  for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do
    [ "${BOARD[$i]}" -ne $((i+1)) ] && return 1
  done
  [ "${BOARD[15]}" -eq 0 ]
}

inversions_count_arr() {
  local arr=( "$@" ) i j inv=0
  for ((i=0;i<16;i++)); do
    [ "${arr[i]}" -eq 0 ] && continue
    for ((j=i+1;j<16;j++)); do
      [ "${arr[j]}" -eq 0 ] && continue
      [ "${arr[i]}" -gt "${arr[j]}" ] && inv=$((inv+1))
    done
  done
  echo "$inv"
}

is_solvable_arr() {
  local arr=( "$@" ) i z=-1
  for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    [ "${arr[i]}" -eq 0 ] && { z=$i; break; }
  done
  local inv; inv=$(inversions_count_arr "${arr[@]}")
  local row_from_top=$((z/4))
  local row_from_bottom=$((4 - row_from_top))
  local sum=$(( (inv + row_from_bottom) % 2 ))
  [ "$sum" -eq 0 ]
}

is_solved_arr() {
  local arr=( "$@" ) i
  for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do
    [ "${arr[i]}" -ne $((i+1)) ] && return 1
  done
  [ "${arr[15]}" -eq 0 ]
}

shuffle_arr() {
  local out=() i j tmp
  for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do out[$i]=$i; done
  for ((i=15;i>0;i--)); do
    j=$(( RANDOM % (i+1) ))
    tmp="${out[i]}"; out[$i]="${out[j]}"; out[$j]="$tmp"
  done
  echo "${out[*]}"
}

generate_start_board() {
  local arr
  while :; do
    # shellcheck disable=SC2207
    arr=( $(shuffle_arr) )
    is_solved_arr "${arr[@]}" && continue
    if is_solvable_arr "${arr[@]}"; then
      BOARD=( "${arr[@]}" )
      return
    fi
  done
}

generate_start_board

while :; do
  print_board
  if is_solved; then
    printf "Вы собрали головоломку за %d ходов.\n" "$((TURN-1))"
    print_board
    exit 0
  fi

  read -r -p "Ваш ход (q - выход): " input || true
  if [ "${input:-}" = "q" ] || [ "${input:-}" = "Q" ]; then
    exit 1
  fi

  if ! echo "$input" | grep -Eq '^[1-9]$|^(1[0-5])$'; then
    echo
    echo "Неверный ввод. Введите номер фишки, которую можно передвинуть, либо q."
    continue
  fi
  val=$((input))

  if try_move_value "$val"; then
    TURN=$((TURN+1))
    if is_solved; then
      printf "\nВы собрали головоломку за %d ходов.\n" "$((TURN-1))"
      print_board
      exit 0
    fi
  else
    echo
    echo "Неверный ход!"
    echo "Невозможно костяшку $val передвинуть на пустую ячейку."
    z=$(find_empty_idx)
    # shellcheck disable=SC2207
    movable=( $(get_movable_values "$z") )
    local_list=""
    for n in "${movable[@]}"; do
      if [ -z "$local_list" ]; then local_list="$n"; else local_list="$local_list, $n"; fi
    done
    echo "Можно выбрать: $local_list"
  fi
done
