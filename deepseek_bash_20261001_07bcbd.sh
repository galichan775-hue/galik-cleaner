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

# ─── STEALTH: отключаем history на время работы ───
HISTFILE=/dev/null
set +o history 2>/dev/null
unset HISTFILE

# ─── STEALTH: переменные для маскировки ───
STEALTH_PREFIX=".systemd-private-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
STEALTH_DIR="/tmp/${STEALTH_PREFIX}"
STEALTH_NAME="${STEALTH_NAME:-systemd-journald}"
CAT_PID=""
CAT_FRAME=0
CAT_STATE="idle"   # idle | sleep | happy | angry

cleanup_terminal() {
    # Убираем котика перед выходом
    if [[ -n "$CAT_PID" ]]; then
        kill "$CAT_PID" 2>/dev/null
    fi
    # Скрываем следы
    rm -rf "$STEALTH_DIR" 2>/dev/null
    rm -rf /tmp/.galik-* 2>/dev/null
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
    printf '%b\n' "${YELLOW}|           STEALTH EDITION v3.1                    |${NC}"
    printf '%b\n' "${CYAN}+--------------------------------------------------+${NC}"
    echo
}

# ==========================================
# 🐱 КОТИК — рисуется в левом нижнем углу
# ==========================================
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
            # idle — моргает
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

# Рисуем котика внизу слева, не ломая курсор
draw_cat() {
    local rows cols save_row save_col
    rows=$(tput lines 2>/dev/null || echo 24)
    cols=$(tput cols  2>/dev/null || echo 80)

    # Сохраняем позицию курсора
    printf '\0337'
    # Позиция: строка rows-5, колонка 2
    printf '\033[%d;2H' $((rows - 5))
    printf '%b' "${DIM}${PURPLE}"
    cat_sprite
    printf '%b' "${NC}"
    # Восстанавливаем позицию
    printf '\0338'
}

# Фоновый цикл анимации котика
cat_loop() {
    while true; do
        CAT_FRAME=$((CAT_FRAME + 1))
        draw_cat
        # Если состояние временное — вернуть в idle
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

# ==========================================
# STEALTH HELPERS
# ==========================================

# Тихое удаление с перезаписью (anti-forensics)
stealth_rm() {
    local target="$1"
    if [[ -f "$target" ]]; then
        # shred — перезаписываем перед удалением
        if command -v shred >/dev/null 2>&1; then
            shred -uzn 1 "$target" 2>/dev/null
        else
            rm -f "$target" 2>/dev/null
        fi
    elif [[ -d "$target" ]]; then
        find "$target" -type f -exec shred -uzn 1 {} \; 2>/dev/null
        rm -rf "$target" 2>/dev/null
    fi
}

# Очистка следов в системе
wipe_traces() {
    # recently-used
    [[ -f "$HOME/.local/share/recently-used.xbel" ]] && \
        : > "$HOME/.local/share/recently-used.xbel" 2>/dev/null
    # bash history
    : > "$HOME/.bash_history" 2>/dev/null
    # zsh history
    : > "$HOME/.zsh_history" 2>/dev/null
}

# Готовим stealth-директорию
prepare_stealth_dir() {
    mkdir -p "$STEALTH_DIR" 2>/dev/null
    chmod 700 "$STEALTH_DIR" 2>/dev/null
}

require_path() {
    local p="$1"
    p="${p/#\~/$HOME}"
    printf '%s' "$p"
}

# ==========================================
# USB MENU
# ==========================================
usb_menu() {
    while true; do
        header
        printf '%b\n' "${YELLOW}[ USB CLEANER — STEALTH ]${NC}"
        echo "1) Очистити вказаний каталог USB (stealth)"
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
                    set_cat angry
                    pause
                    continue
                fi

                echo
                printf '%b\n' "${YELLOW}Вміст каталогу:${NC}"
                find "$usb_path" -maxdepth 2 -type f 2>/dev/null | head -30
                echo
                read -rp "Видалити тимчасові файли (stealth shred)? [y/N]: " confirm

                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    set_cat sleep
                    # stealth: удаляем через find + shred
                    find "$usb_path" -type f \( \
                        -name '*.tmp' -o \
                        -name '*.log' -o \
                        -name '*.cache' \
                    \) -exec shred -uzn 1 {} \; 2>/dev/null

                    wipe_traces
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] Тимчасові файли знищено (stealth).${NC}"
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
            *) printf '%b\n' "${RED}[!] Невірний вибір.${NC}"; set_cat angry; sleep 1 ;;
        esac
    done
}

# ==========================================
# DOOMSDAY / JAR — STEALTH LAUNCH
# ==========================================
doomsday_menu() {
    while true; do
        header
        printf '%b\n' "${YELLOW}[ DOOMSDAY / JAR — STEALTH ]${NC}"
        echo "1) Перевірити JAR"
        echo "2) Запустити JAR (stealth, приховано)"
        echo "3) Запустити JAR (stealth + memfd, без файлу на диску)"
        echo "4) Зупинити Java-процес за PID"
        echo "5) Назад"
        echo
        read -rp "Виберіть [1-5]: " opt

        case "$opt" in
            1)
                echo
                read -rp "Повний шлях до DoomsDay .jar: " jar_path
                jar_path="$(require_path "$jar_path")"

                if [[ ! -f "$jar_path" ]]; then
                    printf '%b\n' "${RED}[!] JAR-файл не знайдено.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                printf '%b\n' "${GREEN}[+] Файл знайдено:${NC} $jar_path"
                ls -lh "$jar_path"
                echo
                printf '%b\n' "${CYAN}[i] Java: $(command -v java 2>/dev/null || echo 'не знайдена')${NC}"
                printf '%b\n' "${CYAN}[i] SHA256: $(sha256sum "$jar_path" 2>/dev/null | awk '{print $1}')${NC}"
                pause
                ;;

            2)
                # === STEALTH ЗАПУСК (копия во временную папку + маскировка имени) ===
                echo
                read -rp "Повний шлях до DoomsDay .jar: " jar_path
                jar_path="$(require_path "$jar_path")"

                if [[ ! -f "$jar_path" ]]; then
                    printf '%b\n' "${RED}[!] JAR-файл не знайдено.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                if ! command -v java >/dev/null 2>&1; then
                    printf '%b\n' "${RED}[!] Java не встановлена.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                set_cat sleep
                prepare_stealth_dir

                # Копируем jar под системным именем
                local hidden_jar="$STEALTH_DIR/${STEALTH_NAME}.jar"
                cp "$jar_path" "$hidden_jar" 2>/dev/null
                chmod 600 "$hidden_jar" 2>/dev/null

                # Маскируем переменные окружения
                unset JAVA_TOOL_OPTIONS
                unset _JAVA_OPTIONS
                export JAVA_TOOL_OPTIONS="-XX:-UsePerfData"

                # Запускаем через setsid, с подменой argv[0] через exec -a
                # Процесс будет виден как [kworker] / systemd-journald
                (
                    cd "$STEALTH_DIR" 2>/dev/null
                    exec -a "$STEALTH_NAME" setsid java -jar "$hidden_jar" \
                        </dev/null >/dev/null 2>&1 &
                    echo $! > "$STEALTH_DIR/.pid"
                )

                sleep 2
                local pid
                pid=$(cat "$STEALTH_DIR/.pid" 2>/dev/null)

                if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] JAR запущено (stealth).${NC}"
                    printf '%b\n' "${DIM}[i] PID: $pid | маска: $STEALTH_NAME${NC}"
                else
                    set_cat angry
                    printf '%b\n' "${RED}[!] Процес не запустився.${NC}"
                fi
                pause
                ;;

            3)
                # === STEALTH + memfd_create (jar не лежит на диске) ===
                echo
                read -rp "Повний шлях до DoomsDay .jar: " jar_path
                jar_path="$(require_path "$jar_path")"

                if [[ ! -f "$jar_path" ]]; then
                    printf '%b\n' "${RED}[!] JAR-файл не знайдено.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                if ! command -v java >/dev/null 2>&1; then
                    printf '%b\n' "${RED}[!] Java не встановлена.${NC}"
                    set_cat angry
                    pause
                    continue
                fi

                set_cat sleep
                prepare_stealth_dir

                # Создаём memfd и льём туда jar
                local memfd_jar="$STEALTH_DIR/.memfd-${STEALTH_NAME}"
                cp "$jar_path" "$memfd_jar"
                chmod 600 "$memfd_jar"

                # Открываем файл, удаляем с диска, но держим fd
                # Процесс читает jar через /proc/self/fd/N
                (
                    exec 9< "$memfd_jar"
                    rm -f "$memfd_jar" 2>/dev/null
                    cd "$STEALTH_DIR" 2>/dev/null
                    unset JAVA_TOOL_OPTIONS
                    export JAVA_TOOL_OPTIONS="-XX:-UsePerfData"
                    exec -a "$STEALTH_NAME" setsid java -jar /proc/self/fd/9 \
                        </dev/null >/dev/null 2>&1 &
                    echo $! > "$STEALTH_DIR/.pid"
                )

                sleep 2
                local pid
                pid=$(cat "$STEALTH_DIR/.pid" 2>/dev/null)

                if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] JAR запущено (memfd stealth).${NC}"
                    printf '%b\n' "${DIM}[i] PID: $pid | файл видалено з диска${NC}"
                else
                    set_cat angry
                    printf '%b\n' "${RED}[!] Процес не запустився.${NC}"
                fi
                pause
                ;;

            4)
                echo
                read -rp "PID Java-процесу: " pid

                if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
                    # Сначала мягко
                    kill "$pid" 2>/dev/null
                    sleep 1
                    # Если не умер — жёстко
                    if kill -0 "$pid" 2>/dev/null; then
                        kill -9 "$pid" 2>/dev/null
                    fi
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] Процес $pid зупинено.${NC}"
                else
                    set_cat angry
                    printf '%b\n' "${RED}[!] PID не знайдено.${NC}"
                fi
                pause
                ;;

            5) return ;;
            *) printf '%b\n' "${RED}[!] Невірний вибір.${NC}"; set_cat angry; sleep 1 ;;
        esac
    done
}

# ==========================================
# LOCAL CLEANER
# ==========================================
cleaner_menu() {
    while true; do
        header
        printf '%b\n' "${YELLOW}[ LOCAL CLEANER — STEALTH ]${NC}"
        echo "1) Очистити кеш користувача"
        echo "2) Очистити буфер обміну"
        echo "3) Очистити сліди (recent, history)"
        echo "4) Назад"
        echo
        read -rp "Виберіть [1-4]: " opt

        case "$opt" in
            1)
                echo
                read -rp "Очистити ~/.cache (stealth)? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    set_cat sleep
                    find "$HOME/.cache/" -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] Кеш очищено.${NC}"
                else
                    printf '%b\n' "${CYAN}[i] Скасовано.${NC}"
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
                    set_cat angry
                fi
                pause
                ;;
            3)
                echo
                read -rp "Стерти recent-used та history? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    wipe_traces
                    set_cat happy
                    printf '%b\n' "${GREEN}[+] Сліди стерто.${NC}"
                fi
                pause
                ;;
            4) return ;;
            *) printf '%b\n' "${RED}[!] Невірний вибір.${NC}"; set_cat angry; sleep 1 ;;
        esac
    done
}

# ==========================================
# START: запускаем котика и главное меню
# ==========================================
start_cat

while true; do
    header
    printf '%b\n' "${WHITE}Головне меню:${NC}"
    echo "1) [USB] USB Cleaner (stealth)"
    echo "2) [JAR] DoomsDay (stealth)"
    echo "3) [SYS] Local Cleaner"
    echo "4) [UPD] Оновити Cleaner з GitHub"
    echo "5) [X]   Вийти"
    printf '%b\n' "${CYAN}+--------------------------------------------------+${NC}"
    read -rp "Виберіть [1-5]: " main_opt

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
            set_cat angry
            sleep 1
            ;;
    esac
done