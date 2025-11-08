#!/usr/bin/env bash

declare -a TOWER_A=(8 7 6 5 4 3 2 1)
declare -a TOWER_B=()
declare -a TOWER_C=()
MOVES_COUNT=0

show_interrupt_message() {
    echo ""
    echo "Для выхода введите q или Q."
}

display_towers() {
    local height=8 i
    local a_val b_val c_val

    for ((i=height-1; i>=0; i--)); do
        a_val="${TOWER_A[i]:- }"
        b_val="${TOWER_B[i]:- }"
        c_val="${TOWER_C[i]:- }"
        printf "|%s|  |%s|  |%s|\n" "$a_val" "$b_val" "$c_val"
    done
    echo "+-+  +-+  +-+"
    echo " A    B    C"
}

get_tower_array() {
    local tower_name=$1
    case $tower_name in
        A) echo "${TOWER_A[@]}" ;;
        B) echo "${TOWER_B[@]}" ;;
        C) echo "${TOWER_C[@]}" ;;
    esac
}

set_tower_array() {
    local tower_name=$1
    shift
    local values=("$@")
    case $tower_name in
        A) TOWER_A=("${values[@]}") ;;
        B) TOWER_B=("${values[@]}") ;;
        C) TOWER_C=("${values[@]}") ;;
    esac
}

validate_move() {
    local source=$1 target=$2
    local src_array=($(get_tower_array $source))
    local tgt_array=($(get_tower_array $target))

    if [ ${#src_array[@]} -eq 0 ]; then
        echo "Стек $source пуст. Повторите ввод."
        return 1
    fi

    local top_source=${src_array[${#src_array[@]}-1]}
    local top_target=0
    if [ ${#tgt_array[@]} -gt 0 ]; then
        top_target=${tgt_array[${#tgt_array[@]}-1]}
    fi

    if [ $top_target -ne 0 ] && [ $top_source -gt $top_target ]; then
        echo "Такое перемещение запрещено!"
        return 1
    fi

    return 0
}

perform_move() {
    local from=$1 to=$2
    local src_arr=($(get_tower_array $from))
    local tgt_arr=($(get_tower_array $to))

    local disk=${src_arr[${#src_arr[@]}-1]}

    unset 'src_arr[${#src_arr[@]}-1]'
    tgt_arr+=($disk)

    set_tower_array $from "${src_arr[@]}"
    set_tower_array $to "${tgt_arr[@]}"
}

check_victory() {
    local target_tower=$1
    local current=($(get_tower_array $target_tower))
    local winning_sequence=(8 7 6 5 4 3 2 1)

    if [ "${current[*]}" = "${winning_sequence[*]}" ]; then
        echo "Поздравляем! Вы победили!"
        display_towers
        exit 0
    fi
}

process_user_input() {
    local input=$1
    input=$(echo "$input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    if [ "$input" = "q" ]; then
        echo "До свидания"
        exit 1
    fi

    if [ ${#input} -ne 2 ]; then
        echo "Некорректный ввод. Повторите."
        return 1
    fi

    local source_tower=${input:0:1}
    local target_tower=${input:1:1}

    if [[ ! "$source_tower" =~ [abc] ]] || [[ ! "$target_tower" =~ [abc] ]]; then
        echo "Некорректные имена стеков. Используйте A, B, C."
        return 1
    fi

    if [ "$source_tower" = "$target_tower" ]; then
        echo "Нельзя перемещать в тот же стек."
        return 1
    fi

    source_tower=$(echo "$source_tower" | tr '[:lower:]' '[:upper:]')
    target_tower=$(echo "$target_tower" | tr '[:lower:]' '[:upper:]')

    if validate_move $source_tower $target_tower; then
        perform_move $source_tower $target_tower
        ((MOVES_COUNT++))
        check_victory B
        check_victory C
        return 0
    fi
    return 1
}

trap show_interrupt_message SIGINT

echo "Игра 'Ханойские башни'"
echo "Цель: переместить все диски со стержня A на стержень B или C"
echo "Правила:"
echo "- Можно перемещать только один диск за ход"
echo "- Нельзя класть больший диск на меньший"
echo "- Для хода введите две буквы (откуда куда), например: AB"
echo ""

while true; do
    display_towers
    read -p "Ход № $((MOVES_COUNT+1)) (откуда, куда): " user_input
    process_user_input "$user_input"
done