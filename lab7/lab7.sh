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

show_fs_only() {
    df -Th -x procfs -x tmpfs -x devtmpfs -x sysfs | awk '{ print $1, $2, $7}' | column -t | tail -n +2
}
show_filesystems() {
    echo -e "Текущие файоловые системы:\n------"
    show_fs_only
    echo "------"
}

mount_filesystem() {
    read -p "Введите файловую систему для монтирования: " filesys

    if [[ -z "$filesys" ]] || [[ ! -e "$filesys" ]] then
        echo "[!ERR] Такой ФС не существует!" >&2
        return
    fi

    read -p "Введите каталог для монтирования > " folder
    if [[ ! -e "$folder" ]] then
        mkdir "$folder"
    fi

    if [[ -d "$folder" ]] && [[ "$(ls -A "$folder" 2> /dev/null)" ]] && [[ -f "filesys" ]] then
        if mount "$filesys" "$folder"; then
            echo "Примонтировано $filesys в $folder"
            printf "%s" "Press any key..."
            read ans
            return
        else
            echo "Примонтировано $filesys в $folder"
            printf "%s" "Press any key..."
            read ans
            return
        fi
    fi
    
    if [[ -d "$folder" ]] && [[ "$(ls -A "$folder" 2> /dev/null)" ]] && [[ ! -d "filesys" ]] then
        if mount -o loop "$filesys" "$folder"; then
            echo "Примонтировано $filesys в $folder"
            printf "%s", "Press any key..."
            read ans
            return
        else
            echo "Примонтировано $filesys в $folder"
            printf "%s", "Press any key..."
            read ans
            return
        fi
    fi
    return
}

unmount_filesystem() {
    echo -e "\n"
	readarray -t menu < <(df -Th -x procfs -x tmpfs -x devtmpfs -x sysfs | tail -n +6 | cut -d ' ' -f 1)
	menu+=(Справка Назад)
	PS3="Выберите файловую систему, которую хотите отмонтировать или введите путь до неё > "
	select ans in "${menu[@]}"; do
		case $ans in 
			Назад)
				break
				;;
			*)
				if [[ -z $ans ]]; then 
					if [[ " ${menu[*]} " =~ " ${REPLY} " ]]; then 
						umount $REPLY
						losetup --detach $REPLY
						break
					fi
					echo -e "Ошибка! Некорректный ввод\n" >&2
					break
				else
					umount $ans
					losetup --detach $ans
					break
				fi
				;;
		esac
	done
}

change_fs_settings() {
    fs="$(show_fs_only)"
    fs=$(echo "$fs" | awk '{print $1}')
    fses=$(echo "$fs" | nl -s ')')
    echo -e "Выберите файловую систему\n$fses"
    lines=$(echo "$fs" | wc -l)
    read -p "Select filesystem to remount: " option
    
    if [ "$option" -gt "$lines" ]; then
        echo "[!ERR] Выбран неправильный номер"
        printf "%s" "Press any key..."
        read ans
        return
    fi
    selected=$(echo "$fs" | sed -n "$option"p)
    echo "1) Перемонтировать в режим 'только для чтения'"
    echo "2) Перемонтировать в режим 'чтение-запись'"

    read -p "{1-2} > " options

    case $option in
        1 ) mount -o remount,ro "$selected" && echo "Успешно перемонтировано!" || echo "[!ERR] Ошибка перемонтирования!";;
        2 ) mount -o remount,rw "$selected" && echo "Успешно перемонтировано!" || echo "[!ERR] Ошибка перемонтирования!";;
        * ) echo "[!ERR] Неправильная опция" ;;
    esac

    printf "%s" "Press any key..."
    read ans
}

show_fs_options() {
    fs="$(show_fs_only)"
    fs=$(echo "$fs" | awk '{print $1}')
    fses=$(echo "$fs" | nl -s ')')
    echo -e "Выберите файловую систему\n$fses"
    lines=$(echo "$fs" | wc -l)
    read -p "Выберите файловую систему: " option
    
    if [ "$option" -gt "$lines" ]; then
        echo "[!ERR] Выбран неправильный номер"
        printf "%s" "Press any key..."
        read ans
        return
    fi
    selected=$(echo "$fs" | sed -n "$option"p)

    echo -e "Параметры для ФС $selected:\n$(findmnt -no OPTIONS "$selected")"
    printf "%s" "Press any key..."
    read ans
}

show_ext_info() {
    fs="$(show_fs_only)"
    fs=$(echo "$fs" | awk '{print $1}')
    fses=$(echo "$fs" | nl -s ')')
    echo -e "Выберите файловую систему\n$fses"
    lines=$(echo "$fs" | wc -l)
    read -p "Выберите файловую систему: " option
    
    if [ "$option" -gt "$lines" ]; then
        echo "[!ERR] Выбран неправильный номер"
        printf "%s" "Press any key..."
        read ans
        return
    fi
    selected=$(echo "$fs" | sed -n "$option"p)

    tune2fs -l $(echo "$selected")

    printf "%s" "Press any key..."
    read ans
}


main_menu() {
    echo "Главное меню"
    echo ""
    echo "1) Таблицы файловых систем"
    echo "2) Примонтировать ФС"
    echo "3) Отмонтировать ФС"
    echo "4) Изменить параметры монтирования"
    echo "5) Вывести параметры примонтированной ФС"
    echo "6) Вывести информацию о ext системе"
    echo "7) Exit"
    
    read -p "{1...7} > " option

    case $option in
        1 ) show_filesystems ;;
        2 ) mount_filesystem ;; 
        3 ) unmount_filesystem ;;
        4 ) change_fs_settings ;;
        5 ) show_fs_options ;;
        6 ) show_ext_info ;;
        7 | q ) echo -e "Goodbye!\n(⌐■_■)" & exit 0 ;;
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