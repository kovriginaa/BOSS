#!/bin/bash

set -Eeuo pipefail
trap EXIT

help_print() {
    echo "Программа по управлению файловой системой и монтированием"
    echo 
    echo "Usage ..."
}

myprint(){
    echo >&2 -e "${1-}"
}

myexit(){
    local msg=$1
    local exitcode=${2-1}
    myprint "$msg"
    exit "$exitcode"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        myexit "[!ERR] Must be run as root!"         
    fi
}

makelist() {
  local -n options1=$1
  options1+=(
            "Помощь"
            "Выход"
            ) 
  while true
  do
  select opt in "${options1[@]}"; do
    case $opt in
      "Помощь")
        echo $2
        break
        ;;
      "Выход")
        return 0
        ;;
      *)
        if [ -z "$opt" ]; then
          err "Введите номер из списка"
          break
        else
          return $REPLY
        fi
        ;;
      esac
    done
  done
  }


find_sysctl() {
    read -p "Введите имя службыж " inp
    systemctl list-units --type=service | head -n-6 | tail -n+2 | grep "$inp" | less

    printf "%s", "Press any key..."
    read ans
}

ps_and_services() {
    ps ax -o'pid,unit,args' | grep  '.service' | less

    printf "%s", "Press any key..."
    read ans
}

conf_service() {
    IFS=$'\n' read -r -d '' -a arr < <(systemctl list-units --type=service | head -n-6 | tail -n+2 | cut -c 3- |  cut -d" " -f 1 && printf '\0')
    makelist arr "Номер сервиса: "
    num=$?
    echo "========" $num
    if [ $num -eq 0 ]; then
        return
    fi
    service=${arr[num-1]}
    settings=(
        "Включить службу"
        "Отключить службу"
        "Запустить или перезапустить службу"
        "Остановить службу"
        "Вывести содержимое юнита службы"
        "Отредактировать юнит службы"
        "Назад"
    )
    select opt in "${options2[@]}"
    do
        case $opt in
            "Включить службу")
            systemctl enable "$service"
            break
            ;;
            "Отключить службу")
            systemctl disable "$service"
            break
            ;;
            "Запустить или перезапустить службу")
            systemctl restart "$service"
            break
            ;;
            "Остановить службу")
            systemctl stop "$service"
            break
            ;;
            "Вывести содержимое юнита службы")
            less "$(systemctl status $service | head -n+2 | tail -n-1 | cut -f2 -d"(" | cut -f1 -d";")"
            break
            ;;
            "Отредактировать юнит службы")
                vim "$(systemctl status $service | head -n+2 | tail -n-1 | cut -f2 -d"(" | cut -f1 -d";")"
            break
            ;;
            "Назад")
            return
            ;;
        *) err "Невер   ный аргумент $REPLY"
        esac
    done 
}

search_journal() {
    read -p "Введите имя службы: " service
    read -p "Введите степень важности: " priority
    read -p "ВВедите строку поиска: " req
    journalctl -p "$priority" -u "$service" -g "$req"
}


main_menu() {
    echo "Главное меню"
    echo ""
    echo "1) Найти системную службу"
    echo "2) Список процессов и связанных с ними служб"
    echo "3) Управление службами"
    echo "4) Поиска собычий в журнале"
    echo "5) Выход"
    
    read -p "{1...5} > " option

    case $option in
        1 ) find_sysctl ;;
        2 ) ps_and_services ;; 
        3 ) conf_service ;;
        4 ) search_journal ;;
        5 | q ) echo -e "Goodbye!\n(⌐■_■)" & exit 0 ;;
        * ) echo -e "[!WRN] Неправильная команда \n---------" ;;
    esac
}

main() {
    check_root
    while true; do
        main_menu
    done
}

main
