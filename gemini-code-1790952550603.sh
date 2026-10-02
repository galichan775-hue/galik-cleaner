#!/usr/bin/env bash

# ==============================================================================
# Скрипт: Ubuntu Advanced Privacy & USB Cleaner (Anti-Forensics Edition)
# Версия: 2.5
# Описание: Глубокая очистка следов файловой системы, USB-накопителей и 
#           автоматическое заметание следов работы самого клинера.
# ==============================================================================

# Проверка привилегий суперпользователя
if [ "$EUID" -ne 0 ]; then
    echo "[!] Ошибка: Этот скрипт требует прав администратора (root)."
    echo "[>] Запустите его командой: sudo bash $0"
    exit 1
fi

# Конфигурация окружения dialog
export DIALOGRC=""
CONFIG_FILE=$(mktemp)
USB_LIST_FILE=$(mktemp)
TARGET_USB=""

# Инициализация логов работы скрипта для последующего уничтожения
SCRIPT_LOG="/var/log/system_cleaner_activity.log"
exec > >(tee -a "$SCRIPT_LOG") 2>&1

# ==============================================================================
# ФУНКЦИИ СКАНИРОВАНИЯ И ИНТЕРФЕЙСА
# ==============================================================================

draw_header() {
    clear
    echo "======================================================="
    echo "       UBUNTU ADVANCED PRIVACY & USB CLEANER           "
    echo "       Режим: Anti-Forensics & Hard Traces Wipe        "
    echo "======================================================="
}

# Функция поиска подключенных USB-устройств
scan_usb_devices() {
    > "$USB_LIST_FILE"
    
    # Сканируем блочные устройства, исключая системные диски (sda/nvme)
    local counter=1
    while read -r name size model serial; do
        if [ -n "$name" ]; then
            echo "$counter" >> "$USB_LIST_FILE"
            echo "UUID_OR_NAME_$counter"="$name" >> "$USB_LIST_FILE"
            echo "$counter" "$model ($size) [Dev: /dev/$name]" >> "$USB_LIST_FILE"
            ((counter++))
        fi
    done < <(lsblk -d -o NAME,SIZE,MODEL,SERIAL | grep -E "sd[b-z]|nvme[1-9]n[1-9]")

    if [ ! -s "$USB_LIST_FILE" ]; then
        return 1
    fi
    return 0
}

# Меню выбора конкретной флешки для точечной зачистки
select_usb_target() {
    scan_usb_devices
    if [ $? -ne 0 ]; then
        dialog --title "Внимание" --msgbox "Не обнаружено подключенных USB-накопителей в системе!\nБудет произведена общая очистка USB-логов." 7 60
        TARGET_USB="ALL"
        return
    fi

    # Формируем динамическое меню из найденных устройств
    local menu_args=()
    while read -r line; do
        # Читаем построчно для диалога
        read -r num desc
        menu_args+=("$num" "$desc")
    done < <(grep -v "=" "$USB_LIST_FILE")

    menu_args+=("ALL" "Очистить следы ВСЕХ когда-либо подключаемых флешек")
    menu_args+=("CANCEL" "Отмена / Пропустить выбор флешки")

    local selected
    selected=$(dialog --clear \
                      --backtitle "Ubuntu Privacy Cleaner" \
                      --title " [ Выбор USB-устройства для стирания ] " \
                      --menu "Выберите целевую флешку из списка:" 16 70 6 \
                      "${menu_args[@]}" \
                      3>&1 1>&2 2>&3)

    if [ "$selected" = "CANCEL" ] || [ -z "$selected" ]; then
        TARGET_USB="NONE"
    elif [ "$selected" = "ALL" ]; then
        TARGET_USB="ALL"
    else
        # Извлекаем реальное имя устройства по номеру
        TARGET_USB=$(grep "UUID_OR_NAME_$selected=" "$USB_LIST_FILE" | cut -d'=' -f2)
    fi
}

# Главное меню настроек (чекбоксы)
show_settings_menu() {
    dialog --backtitle "Ubuntu Privacy & USB Cleaner" \
           --title " [ Настройка параметров очистки ] " \
           --checklist "Отметьте компоненты для уничтожения (Пробел — выбор):" 20 70 10 \
           "TARGET_USB_WIPE" "Точечно стереть выбранную флешку из логов" ON \
           "SYS_JOURNAL"     "Затереть systemd journal (включая следы устройств)" ON \
           "KERNEL_DMESG"    "Очистить буфер ядра dmesg (аппаратные логи)" ON \
           "VAR_LOGS"        "Очистить стандартные логи (/var/log/*)" ON \
           "SHELL_HISTORY"   "Стереть историю терминала (bash, zsh, history)" ON \
           "USER_TRASH_REC"  "Очистить корзину и недавние файлы (recently-used)" ON \
           "APT_SNAP_CACHE"  "Очистить кэш пакетных менеджеров (apt, snap)" OFF \
           "TMP_SYSTEM"      "Очистить временные директории (/tmp, /var/tmp)" ON \
           "SELF_WIPE_LOGS"  "Удалить логи работы самого этого клинера" ON 2> "$CONFIG_FILE"

    return $?
}

# ==============================================================================
# ПРОЦЕДУРА ГЛУБОКОЙ ОЧИСТКИ
# ==============================================================================

execute_cleanup() {
    local choices
    choices=$(cat "$CONFIG_FILE")

    if [ -z "$choices" ]; then
        dialog --title "Отмена" --msgbox "Не выбрано ни одного параметра." 5 40
        return
    fi

    (
        echo "5"; sleep 0.2
        echo "# Остановка служб логирования для доступа к файлам..."
        systemctl stop systemd-journald.socket systemd-journald.service 2>/dev/null
        systemctl stop rsyslog 2>/dev/null

        # 1. Точечная или полная очистка USB
        if [[ "$choices" =~ "TARGET_USB_WIPE" ]]; then
            echo "20"; sleep 0.3
            if [ "$TARGET_USB" = "ALL" ]; then
                echo "# Уничтожение всех записей об USB в системе..."
                journalctl --vacuum-time=1s >/dev/null 2>&1
                rm -rf /var/log/udev* 2>/dev/null
                rm -rf /var/lib/udisks2/* 2>/dev/null
                find /var/log -type f -exec sed -i '/usb/Id' {} + 2>/dev/null
            elif [ "$TARGET_USB" != "NONE" ] && [ -n "$TARGET_USB" ]; then
                echo "# Вымарывание следов устройства $TARGET_USB..."
                # Удаляем строки, содержащие имя устройства или его серийник из логов
                local dev_serial=$(udevadm info --name=/dev/$TARGET_USB --attribute-walk | grep -m1 "serial" | cut -d'"' -f2)
                if [ -n "$dev_serial" ]; then
                    find /var/log -type f -exec grep -l "$dev_serial" {} + 2>/dev/null | xargs -I {} sed -i "/$dev_serial/d" {}
                fi
                find /var/log -type f -exec grep -l "$TARGET_USB" {} + 2>/dev/null | xargs -I {} sed -i "/$TARGET_USB/d" {}
            fi
        fi

        # 2. Очистка systemd journal
        if [[ "$choices" =~ "SYS_JOURNAL" ]]; then
            echo "35"; sleep 0.3
            echo "# Очистка и ротация системного журнала..."
            journalctl --rotate >/dev/null 2>&1
            journalctl --vacuum-time=1s >/dev/null 2>&1
            rm -rf /var/log/journal/* 2>/dev/null
        fi

        # 3. Очистка буфера ядра dmesg
        if [[ "$choices" =~ "KERNEL_DMESG" ]]; then
            echo "50"; sleep 0.2
            echo "# Сброс буфера ядра (dmesg)..."
            dmesg -C >/dev/null 2>&1
        fi

        # 4. Очистка системных логов /var/log
        if [[ "$choices" =~ "VAR_LOGS" ]]; then
            echo "65"; sleep 0.3
            echo "# Зануление системных логов..."
            find /var/log -type f -name "*.log" -exec truncate -s 0 {} + 2>/dev/null
            find /var/log -type f -name "*.gz" -delete 2>/dev/null
            find /var/log -type f -name "*.1" -delete 2>/dev/null
        fi

        # 5. Очистка истории терминала
        if [[ "$choices" =~ "SHELL_HISTORY" ]]; then
            echo "75"; sleep 0.2
            echo "# Очистка истории команд (bash, zsh)..."
            history -c 2>/dev/null
            history -w 2>/dev/null
            for home_dir in /root /home/*; do
                if [ -d "$home_dir" ]; then
                    rm -f "$home_dir/.bash_history" "$home_dir/.zsh_history" 2>/dev/null
                    touch "$home_dir/.bash_history" "$home_dir/.zsh_history" 2>/dev/null
                    chown -R $(basename "$home_dir"):$(basename "$home_dir") "$home_dir/.bash_history" "$home_dir/.zsh_history" 2>/dev/null
                fi
            done
        fi

        # 6. Очистка пользовательских треков (Корзина, Recently-used)
        if [[ "$choices" =~ "USER_TRASH_REC" ]]; then
            echo "85"; sleep 0.2
            echo "# Очистка корзины и недавних файлов..."
            for home_dir in /home/*; do
                if [ -d "$home_dir" ]; then
                    rm -rf "$home_dir/.local/share/Trash/*" 2>/dev/null
                    rm -f "$home_dir/.local/share/recently-used.xbel" 2>/dev/null
                    rm -rf "$home_dir/.cache/thumbnails/*" 2>/dev/null
                fi
            done
        fi

        # 7. APT & Snap кэш
        if [[ "$choices" =~ "APT_SNAP_CACHE" ]]; then
            echo "90"; sleep 0.2
            echo "# Очистка кэша приложений..."
            apt-get clean -y >/dev/null 2>&1
            rm -rf /var/lib/snapd/cache/* 2>/dev/null
        fi

        # 8. Временные файлы
        if [[ "$choices" =~ "TMP_SYSTEM" ]]; then
            echo "95"; sleep 0.2
            echo "# Очистка временных директорий..."
            rm -rf /tmp/* /var/tmp/* 2>/dev/null
        fi

        # Перезапуск системных служб
        systemctl start systemd-journald.socket systemd-journald.service 2>/dev/null
        systemctl start rsyslog 2>/dev/null

        # 9. Самоочистка следов работы клинера
        if [[ "$choices" =~ "SELF_WIPE_LOGS" ]]; then
            echo "# Уничтожение следов выполнения самого скрипта..."
            rm -f "$SCRIPT_LOG"
            # Удаляем упоминания скрипта из истории bash текущей сессии
            history -c 2>/dev/null
        fi

        echo "100"; sleep 0.4

    ) | dialog --title "Выполнение очистки" --gauge "Пожалуйста, подождите, идет зачистка..." 8 60 0

    dialog --title "Успех" --msgbox "Операция Anti-Forensics успешно завершена.\nВсе выбранные следы и логи стерты." 7 60
}

# ==============================================================================
# ГЛАВНЫЙ ЦИКЛ ПРОГРАММЫ
# ==============================================================================

while true; do
    draw_header
    
    MAIN_CHOICE=$(dialog --clear \
                         --backtitle "Ubuntu Privacy & USB Cleaner" \
                         --title " [ Главное меню ] " \
                         --menu "Сделайте выбор:" 16 65 5 \
                         1 "Выбрать флешку и настроить очистку" \
                         2 "Запустить очистку по текущим настройкам" \
                         3 "Справка по безопасности (Anti-Forensics)" \
                         4 "Выход" \
                         3>&1 1>&2 2>&3)

    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        break
    fi

    case $MAIN_CHOICE in
        1)
            select_usb_target
            show_settings_menu
            if [ $? -eq 0 ]; then
                execute_cleanup
            fi
            ;;
        2)
            if [ ! -s "$CONFIG_FILE" ]; then
                # По умолчанию создаем конфиг со всеми включенными флагами
                echo "TARGET_USB_WIPE SYS_JOURNAL KERNEL_DMESG VAR_LOGS SHELL_HISTORY USER_TRASH_REC TMP_SYSTEM SELF_WIPE_LOGS" > "$CONFIG_FILE"
                TARGET_USB="ALL"
            fi
            execute_cleanup
            ;;
        3)
            dialog --title "Справка" --msgbox "Данный скрипт разработан с учетом стандартов цифровой гигиены.\n\n- Он не оставляет следов запуска в стандартных логах (если включена самоочистка).\n- Зачищает блоки ядра dmesg, куда ОС записывает серийные номера USB-устройств при подключении.\n- Очищает кэши udisks2 и монтирования." 12 65
            ;;
        4)
            break
            ;;
    esac
done

# Финальная зачистка временных файлов интерфейса
rm -f "$CONFIG_FILE" "$USB_LIST_FILE"
clear
echo "[+] Работа скрипта завершена. Система очищена."