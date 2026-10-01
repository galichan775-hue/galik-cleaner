#!/bin/bash

# ==========================================
# GALIK CLEANER v3.0 - SAFE USB/JAR UTILITY
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

cleanup_terminal() {
    printf '\033[0m'
    stty sane 2>/dev/null
}
trap cleanup_terminal EXIT INT TERM

pause() {
    echo
    read -rp "Натисніть Enter для продовження..."
}

header() {
    clear
    printf '%b\n' "${CYAN}+--------------------------------------------------+${NC}"
    printf '%b\n' "${PURPLE}|              G A L I K   C L E A N E R           |${NC}"
    printf '%b\n' "${PURPLE}|                    [::]                           |${NC}"
    printf '%b\n' "${YELLOW}|              ADVANCED CLEANER v3.0               |${NC}"
    printf '%b\n' "${CYAN}+--------------------------------------------------+${NC}"
    echo
}

require_path() {
    local p="$1"
    p="${p/#\~/$HOME}"
    printf '%s' "$p"
}

usb_menu() {
    while true; do
        header
        printf '%b\n' "${YELLOW}[ USB CLEANER ]${NC}"
        echo "1) Очистити вказаний каталог USB"
        echo "2) Показати підключені USB-пристрої"
        echo "3) Назад"
        echo
        read -rp "Виберіть [1-3]: " opt

        case "$opt" in
            1)
                echo
                read -rp "Шлях до флешки/каталогу: " usb_path
                usb_path="$(require_path "$usb_path")"

                if [[ -z "$usb_path" || ! -d "$usb_path" ]]; then
                    printf '%b\n' "${RED}[!] Каталог не знайдено.${NC}"
                    pause
                    continue
                fi

                echo
                printf '%b\n' "${YELLOW}Вміст каталогу:${NC}"
                find "$usb_path" -maxdepth 2 -type f 2>/dev/null | head -30
                echo
                read -rp "Видалити тимчасові файли (*.tmp, *.log, *.cache)? [y/N]: " confirm

                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    find "$usb_path" -type f \( \
                        -name '*.tmp' -o \
                        -name '*.log' -o \
                        -name '*.cache' \
                    \) -delete 2>/dev/null

                    printf '%b\n' "${GREEN}[+] Тимчасові файли очищено.${NC}"
                else
                    printf '%b\n' "${CYAN}[i] Операцію скасовано.${NC}"
                fi
                pause
                ;;
            2)
                header
                printf '%b\n' "${YELLOW}Підключені USB-пристрої:${NC}"
                lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS,TRAN 2>/dev/null | \
                    awk 'NR==1 || $6=="usb"'
                pause
                ;;
            3) return ;;
            *) printf '%b\n' "${RED}[!] Невірний вибір.${NC}"; sleep 1 ;;
        esac
    done
}

doomsday_menu() {
    while true; do
        header
        printf '%b\n' "${YELLOW}[ DOOMSDAY / JAR ]${NC}"
        echo "1) Перевірити JAR"
        echo "2) Запустити JAR без виводу в термінал"
        echo "3) Зупинити Java-процес за PID"
        echo "4) Назад"
        echo
        read -rp "Виберіть [1-4]: " opt

        case "$opt" in
            1|2)
                echo
                read -rp "Повний шлях до DoomsDay .jar: " jar_path
                jar_path="$(require_path "$jar_path")"

                if [[ ! -f "$jar_path" ]]; then
                    printf '%b\n' "${RED}[!] JAR-файл не знайдено.${NC}"
                    pause
                    continue
                fi

                # Розширення не перевіряємо: Java може запускати JAR,
                # навіть якщо файл має довільне ім'я або розширення.
                printf '%b\n' "${GREEN}[+] Файл знайдено:${NC} $jar_path"
                ls -lh "$jar_path"

                if [[ "$opt" == "2" ]]; then
                    if ! command -v java >/dev/null 2>&1; then
                        printf '%b\n' "${RED}[!] Java не встановлена або не знайдена в PATH.${NC}"
                        pause
                        continue
                    fi

                    echo
                    printf '%b\n' "${CYAN}[*] Запуск JAR...${NC}"

                    # Вивід програми не засмічує поточний термінал.
                    # Процес залишається звичайним видимим процесом ОС.
                    nohup java -jar "$jar_path" >/dev/null 2>&1 &
                    pid=$!

                    sleep 1

                    if kill -0 "$pid" 2>/dev/null; then
                        printf '%b\n' "${GREEN}[+] Запущено. PID: ${WHITE}$pid${NC}"
                    else
                        printf '%b\n' "${RED}[!] Java-процес завершився одразу після запуску.${NC}"
                    fi
                    pause
                else
                    echo
                    printf '%b\n' "${CYAN}[i] Файл доступний для запуску.${NC}"
                    printf '%b\n' "Java: $(command -v java 2>/dev/null || echo 'не знайдена')"
                    pause
                fi
                ;;
            3)
                echo
                read -rp "PID Java-процесу: " pid

                if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
                    kill "$pid" 2>/dev/null
                    printf '%b\n' "${GREEN}[+] Процес $pid зупинено.${NC}"
                else
                    printf '%b\n' "${RED}[!] PID не знайдено або процес недоступний.${NC}"
                fi
                pause
                ;;
            4) return ;;
            *) printf '%b\n' "${RED}[!] Невірний вибір.${NC}"; sleep 1 ;;
        esac
    done
}

cleaner_menu() {
    while true; do
        header
        printf '%b\n' "${YELLOW}[ LOCAL CLEANER ]${NC}"
        echo "1) Очистити кеш користувача"
        echo "2) Очистити буфер обміну"
        echo "3) Назад"
        echo
        read -rp "Виберіть [1-3]: " opt

        case "$opt" in
            1)
                echo
                read -rp "Очистити ~/.cache? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -rf "$HOME/.cache/"* 2>/dev/null
                    printf '%b\n' "${GREEN}[+] Кеш користувача очищено.${NC}"
                else
                    printf '%b\n' "${CYAN}[i] Операцію скасовано.${NC}"
                fi
                pause
                ;;
            2)
                echo
                if command -v wl-copy >/dev/null 2>&1; then
                    wl-copy --clear 2>/dev/null
                    printf '%b\n' "${GREEN}[+] Wayland clipboard очищено.${NC}"
                elif command -v xclip >/dev/null 2>&1; then
                    printf '' | xclip -selection clipboard 2>/dev/null
                    printf '%b\n' "${GREEN}[+] X11 clipboard очищено.${NC}"
                elif command -v xsel >/dev/null 2>&1; then
                    xsel --clipboard --clear 2>/dev/null
                    printf '%b\n' "${GREEN}[+] X11 clipboard очищено.${NC}"
                else
                    printf '%b\n' "${RED}[!] wl-copy/xclip/xsel не встановлено.${NC}"
                fi
                pause
                ;;
            3) return ;;
            *) printf '%b\n' "${RED}[!] Невірний вибір.${NC}"; sleep 1 ;;
        esac
    done
}

while true; do
    header
    printf '%b\n' "${WHITE}Головне меню:${NC}"
    echo "1) [USB] USB Cleaner"
    echo "2) [JAR] DoomsDay"
    echo "3) [SYS] Local Cleaner"
    echo "4) [UPD] Оновити Cleaner з GitHub"
    echo "5) [X]   Вийти"
    printf '%b\n' "${CYAN}+--------------------------------------------------+${NC}"
    read -rp "Виберіть [1-4]: " main_opt

    case "$main_opt" in
        1) usb_menu ;;
        2) doomsday_menu ;;
        3) cleaner_menu ;;
        4)
            clear
            printf '%b\n' "${CYAN}[*] Оновлення з GitHub...${NC}"
            if command -v curl >/dev/null 2>&1; then
                bash <(curl -fsSL https://raw.githubusercontent.com/galichan775-hue/galik-cleaner/main/cleaner.sh)
            elif command -v wget >/dev/null 2>&1; then
                wget -qO- https://raw.githubusercontent.com/galichan775-hue/galik-cleaner/main/cleaner.sh | bash
            else
                printf '%b\n' "${RED}[!] Потрібен curl або wget.${NC}"
                pause
            fi
            ;;
        5)
            clear
            printf '%b\n' "${GREEN}Сесію завершено.${NC}"
            exit 0
            ;;
        *)
            printf '%b\n' "${RED}[!] Невірний вибір.${NC}"
            sleep 1
            ;;
    esac
done
