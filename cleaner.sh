#!/bin/bash

# ==========================================
# GALIK CLEANER v3.1 - STEALTH EDITION
# + Animated cat + Anti-forensics
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

HISTFILE=/dev/null
set +o history 2>/dev/null
unset HISTFILE

STEALTH_PREFIX=".systemd-private-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
STEALTH_DIR="/tmp/${STEALTH_PREFIX}"
STEALTH_NAME="${STEALTH_NAME:-systemd-journald}"
CAT_PID=""
CAT_FRAME=0
CAT_STATE="idle"

cleanup_terminal() {
    if [[ -n "$CAT_PID" ]]; then
        kill "$CAT_PID" 2>/dev/null
    fi
    rm -rf "$STEALTH_DIR" 2>/dev/null
    rm -rf /tmp/.galik-* 2>/dev/null
    printf '\033[0m'
    stty sane 2>/dev/null
}
trap cleanup_terminal EXIT INT TERM

pause() {
    echo
    read -rp "Нажмите Enter для продолжения..."
}

header() {
    clear
    printf '%b\n' "${CYAN}+--------------------------------------------------+${NC}"
    printf '%b\n' "${PURPLE}|              G A L I K   C L E A N E R           |${NC}"
    printf '%b\n' "${PURPLE}|                    [::]                           |${NC}"
    printf '%b\n' "${YELLOW}|           STEALTH EDITION v3.1                    |${NC}"
    printf '%b\n' "${CYAN}+--------------------------------------------------+${NC}"
    echo
}

cat_sprite() {
    case "$CAT_STATE" in
        sleep)
            printf '%s' "
   /\\_/\\
  ( -.- )   zZ
  (  ..  )
   \`----'"
            ;;
        happy)
            printf '%s' "
   /\\_/\\
  ( ^.^ )   ♥
  (  ω   )
   \`----'"
            ;;
        angry)
            printf '%s' "
   /\\_/\\
  ( >_< )   !!
  (  ..  )
   \`----'"
            ;;
        *)
            if (( CAT_FRAME % 6 == 0 )); then
                printf '%s' "
   /\\_/\\
  ( -.- )
  (  ..  )
   \`----'"
            else
                printf '%s' "
   /\\_/\\
  ( o.o )
  (  ..  )
   \`----'"
            fi
            ;;
    esac
}

draw_cat() {
    local rows cols
    rows=$(tput lines 2>/dev/null || echo 24)
    cols=$(tput cols 2>/dev/null || echo 80)
    printf '\0337'
    printf '\033[%d;2H' $((rows - 5))
    printf '%b' "${DIM}${PURPLE}"
    cat_sprite
    printf '%b' "${NC}"
    printf '\0338'
}

cat_loop() {
    while true; do
        CAT_FRAME=$((CAT_FRAME + 1))
        draw_cat
        if [[ "$CAT_STATE" == "happy" || "$CAT_STATE" == "angry" ]]; then
            if (( CAT_FRAME % 8 == 0 )); then
                CAT_STATE="idle"
            fi
        fi
        sleep 0.5
    done
}

start_cat() {
    cat_loop &
    CAT_PID=$!
    disown 2>/dev/null
}

set_cat() {
    CAT_STATE="$1"
    CAT_FRAME=0
    draw_cat
}

wipe_traces() {
    [[ -f "$HOME/.local/share/recently-used.xbel" ]] && : > "$HOME/.local/share/recently-used.xbel" 2>/dev/null
    : > "$HOME/.bash_history" 2>/dev/null
    : > "$HOME/.zsh_history" 2>/dev/null
}

prepare_stealth_dir() {
    mkdir -p "$STEALTH_DIR" 2>/dev/null
    chmod 700 "$STEALTH_DIR" 2>/dev/null
}

require_path() {
    local p="$1"
    p="${p/#\~/$HOME}"
    printf '%s' "$p"
}

usb_menu() {
    while true; do
        header
        printf '%b\n' "${YELLOW}[ USB CLEANER — STEALTH ]${NC}"
        echo "1) Очистить временные файлы USB"
        echo "2) Показать подключённые USB"
        echo "3) Назад"
        echo
        read -rp "Выберите [1-3]: " opt

        case "$opt" in
            1)
                echo
                read -rp "Путь к флешке/каталогу: " usb_path
                usb_path="$(require_path "$usb_path")"

                if [[ -z "$usb_path" || ! -d "$usb_path" ]]; then
                    printf '%b\n' "${RED}[!] Каталог не найден.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                echo
                printf '%b\n' "${YELLOW}Содержимое каталога:${NC}"
                find "$usb_path" -maxdepth 2 -type f 2>/dev/null | head -30
                echo
                read -rp "Удалить временные файлы? [y/N]: " confirm

                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    set_cat sleep
                    find "$usb_path" -type f \( \
                        -name '*.tmp' -o \
                        -name '*.log' -o \
                        -name '*.cache' \
                    \) -exec shred -uzn 1 {} \; 2>/dev/null
                    wipe_traces
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] Временные файлы удалены.${NC}"
                else
                    printf '%b\n' "${CYAN}[i] Отмена.${NC}"
                fi
                pause
                ;;
            2)
                header
                printf '%b\n' "${YELLOW}Подключённые USB-устройства:${NC}"
                lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS,TRAN 2>/dev/null | awk 'NR==1 || $6=="usb"'
                pause
                ;;
            3) return ;;
            *) printf '%b\n' "${RED}[!] Неверный выбор.${NC}"; set_cat angry; sleep 1 ;;
        esac
    done
}

doomsday_menu() {
    while true; do
        header
        printf '%b\n' "${YELLOW}[ JAR / CHEAT CLEANER — STEALTH ]${NC}"
        echo "1) Проверить JAR"
        echo "2) Запустить JAR в stealth режиме"
        echo "3) Запустить JAR через memfd"
        echo "4) Остановить Java-процесс по PID"
        echo "5) Назад"
        echo
        read -rp "Выберите [1-5]: " opt

        case "$opt" in
            1)
                echo
                read -rp "Полный путь до JAR: " jar_path
                jar_path="$(require_path "$jar_path")"

                if [[ ! -f "$jar_path" ]]; then
                    printf '%b\n' "${RED}[!] JAR-файл не найден.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                printf '%b\n' "${GREEN}[+] Файл найден:${NC} $jar_path"
                ls -lh "$jar_path"
                echo
                printf '%b\n' "${CYAN}[i] Java: $(command -v java 2>/dev/null || echo 'не найдена')${NC}"
                printf '%b\n' "${CYAN}[i] SHA256: $(sha256sum "$jar_path" 2>/dev/null | awk '{print $1}')${NC}"
                pause
                ;;

            2)
                echo
                read -rp "Полный путь до JAR: " jar_path
                jar_path="$(require_path "$jar_path")"

                if [[ ! -f "$jar_path" ]]; then
                    printf '%b\n' "${RED}[!] JAR-файл не найден.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                if ! command -v java >/dev/null 2>&1; then
                    printf '%b\n' "${RED}[!] Java не установлена.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                set_cat sleep
                prepare_stealth_dir

                local hidden_jar="$STEALTH_DIR/${STEALTH_NAME}.jar"
                cp "$jar_path" "$hidden_jar" 2>/dev/null
                chmod 600 "$hidden_jar" 2>/dev/null

                unset JAVA_TOOL_OPTIONS
                unset _JAVA_OPTIONS
                export JAVA_TOOL_OPTIONS="-XX:-UsePerfData"

                (
                    cd "$STEALTH_DIR" 2>/dev/null
                    exec -a "$STEALTH_NAME" setsid java -jar "$hidden_jar" </dev/null >/dev/null 2>&1 &
                    echo $! > "$STEALTH_DIR/.pid"
                )

                sleep 2
                local pid
                pid=$(cat "$STEALTH_DIR/.pid" 2>/dev/null)

                if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] JAR запущен (stealth).${NC}"
                    printf '%b\n' "${DIM}[i] PID: $pid | маска: $STEALTH_NAME${NC}"
                else
                    set_cat angry
                    printf '%b\n' "${RED}[!] Процесс не запустился.${NC}"
                fi
                pause
                ;;

            3)
                echo
                read -rp "Полный путь до JAR: " jar_path
                jar_path="$(require_path "$jar_path")"

                if [[ ! -f "$jar_path" ]]; then
                    printf '%b\n' "${RED}[!] JAR-файл не найден.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                if ! command -v java >/dev/null 2>&1; then
                    printf '%b\n' "${RED}[!] Java не установлена.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                set_cat sleep
                prepare_stealth_dir

                local memfd_jar="$STEALTH_DIR/.memfd-${STEALTH_NAME}"
                cp "$jar_path" "$memfd_jar"
                chmod 600 "$memfd_jar"

                (
                    exec 9< "$memfd_jar"
                    rm -f "$memfd_jar" 2>/dev/null
                    cd "$STEALTH_DIR" 2>/dev/null
                    unset JAVA_TOOL_OPTIONS
                    export JAVA_TOOL_OPTIONS="-XX:-UsePerfData"
                    exec -a "$STEALTH_NAME" setsid java -jar /proc/self/fd/9 </dev/null >/dev/null 2>&1 &
                    echo $! > "$STEALTH_DIR/.pid"
                )

                sleep 2
                local pid
                pid=$(cat "$STEALTH_DIR/.pid" 2>/dev/null)

                if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] JAR запущен (memfd stealth).${NC}"
                    printf '%b\n' "${DIM}[i] PID: $pid | файл удалён с диска${NC}"
                else
                    set_cat angry
                    printf '%b\n' "${RED}[!] Процесс не запустился.${NC}"
                fi
                pause
                ;;

            4)
                echo
                read -rp "PID Java-процесса: " pid

                if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
                    kill "$pid" 2>/dev/null
                    sleep 1
                    if kill -0 "$pid" 2>/dev/null; then
                        kill -9 "$pid" 2>/dev/null
                    fi
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] Процесс $pid остановлен.${NC}"
                else
                    set_cat angry
                    printf '%b\n' "${RED}[!] PID не найден.${NC}"
                fi
                pause
                ;;

            5) return ;;
            *) printf '%b\n' "${RED}[!] Неверный выбор.${NC}"; set_cat angry; sleep 1 ;;
        esac
    done
}

cleaner_menu() {
    while true; do
        header
        printf '%b\n' "${YELLOW}[ LOCAL CLEANER — STEALTH ]${NC}"
        echo "1) Очистить ��эш пользователя"
        echo "2) Очистить буфер обмена"
        echo "3) Очистить следы (history)"
        echo "4) Назад"
        echo
        read -rp "Выберите [1-4]: " opt

        case "$opt" in
            1)
                echo
                read -rp "Очистить ~/.cache ? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    set_cat sleep
                    find "$HOME/.cache/" -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] Кэш очищен.${NC}"
                else
                    printf '%b\n' "${CYAN}[i] Отмена.${NC}"
                fi
                pause
                ;;
            2)
                echo
                if command -v wl-copy >/dev/null 2>&1; then
                    wl-copy --clear 2>/dev/null
                    printf '%b\n' "${GREEN}[+] Wayland clipboard очищен.${NC}"
                elif command -v xclip >/dev/null 2>&1; then
                    printf '' | xclip -selection clipboard 2>/dev/null
                    printf '%b\n' "${GREEN}[+] X11 clipboard очищен.${NC}"
                elif command -v xsel >/dev/null 2>&1; then
                    xsel --clipboard --clear 2>/dev/null
                    printf '%b\n' "${GREEN}[+] X11 clipboard очищен.${NC}"
                else
                    printf '%b\n' "${RED}[!] wl-copy/xclip/xsel не найден.${NC}"
                    set_cat angry
                fi
                pause
                ;;
            3)
                echo
                read -rp "Удалить history? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    wipe_traces
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] Следы очищены.${NC}"
                fi
                pause
                ;;
            4) return ;;
            *) printf '%b\n' "${RED}[!] Неверный выбор.${NC}"; set_cat angry; sleep 1 ;;
        esac
    done
}

start_cat

while true; do
    header
    printf '%b\n' "${WHITE}Главное меню:${NC}"
    echo "1) [USB] USB Cleaner"
    echo "2) [JAR] JAR / Cheat Cleaner"
    echo "3) [SYS] Local Cleaner"
    echo "4) [UPD] О��новить Cleaner"
    echo "5) [X]   Выход"
    printf '%b\n' "${CYAN}+--------------------------------------------------+${NC}"
    read -rp "Выберите [1-5]: " main_opt

    case "$main_opt" in
        1) usb_menu ;;
        2) doomsday_menu ;;
        3) cleaner_menu ;;
        4)
            clear
            printf '%b\n' "${CYAN}[*] Обновление...${NC}"
            if command -v curl >/dev/null 2>&1; then
                bash <(curl -fsSL https://raw.githubusercontent.com/galichan775-hue/galik-cleaner/main/cleaner.sh)
            elif command -v wget >/dev/null 2>&1; then
                wget -qO- https://raw.githubusercontent.com/galichan775-hue/galik-cleaner/main/cleaner.sh | bash
            else
                printf '%b\n' "${RED}[!] Нужен curl или wget.${NC}"
                pause
            fi
            ;;
        5)
            clear
            printf '%b\n' "${GREEN}Сессия завершена.${NC}"
            exit 0
            ;;
        *)
            printf '%b\n' "${RED}[!] Неверный выбор.${NC}"
            set_cat angry
            sleep 1
            ;;
    esac
done
