#!/bin/bash

# ==========================================
# GALIK CLEANER v2.0 - SYSTEM UTILITY
# ==========================================

# Кольорова палітра
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Перевірка на наявність root-прав при виконанні критичних системних дій
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[!] Ця операція вимагає прав root (sudo).${NC}"
        return 1
    fi
    return 0
}

draw_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${PURPLE}║  ██████╗  █████╗ ██╗     ██╗██╗  ██╗  ██████╗██╗     ║${NC}"
    echo -e "${BOLD}${PURPLE}║ ██╔════╝ ██╔══██╗██║     ██║██║ ██╔╝  ██╔═══╝██║     ║${NC}"
    echo -e "${BOLD}${PURPLE}║ ██║  ███╗███████║██║     ██║█████╔╝   ██║    ██║     ║${NC}"
    echo -e "${BOLD}${PURPLE}║ ██║   ██║██╔══██║██║     ██║██╔═██╗   ██║    ██║     ║${NC}"
    echo -e "${BOLD}${PURPLE}║ ╚██████╔╝██║  ██║███████╗██║██║  ██╗  ╚█████████████╗║${NC}"
    echo -e "${BOLD}${PURPLE}║  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝   ╚═════╝╚══════╝║${NC}"
    echo -e "${BOLD}${YELLOW}║               --- ADVANCED CLEANER v2.0 ---          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
}

pause() {
    echo ""
    read -rp "Натисніть Enter для продовження..."
}

# --- КАТАЛОГ 1: USB DOOMSDAY ---
usb_menu() {
    draw_banner
    echo -e "${YELLOW}[ МОДУЛЬ: USB CLEANER ]${NC}"
    echo -e "1) ${RED}Стирання слідів поточного USB-пристрою${NC}"
    echo -e "2) Повернутися в головне меню"
    echo ""
    read -rp "Оберіть опцію [1-2]: " usb_opt

    if [ "$usb_opt" = "1" ]; then
        check_root || { pause; return; }

        echo -e "${CYAN}[*] Пошук змонтованих USB-накопичувачів...${NC}"
        
        # Знаходимо точку монтування USB
        mount_point=$(lsblk -o MOUNTPOINT,TRAN | grep 'usb' | awk '{print $1}' | head -n 1)
        usb_dev=$(lsblk -o PATH,TRAN | grep 'usb' | awk '{print $1}' | head -n 1)

        if [ -n "$mount_point" ]; then
            echo -e "${YELLOW}[*] Демонтування $mount_point...${NC}"
            umount -f "$mount_point" 2>/dev/null
        fi

        if [ -n "$usb_dev" ]; then
            echo -e "${YELLOW}[*] Відключення USB-пристрою на рівні шини...${NC}"
            dev_name=$(basename "$usb_dev")
            sys_path=$(readlink -f /sys/class/block/"$dev_name"/../..)
            if [ -e "$sys_path/driver/unbind" ]; then
                echo "$(basename "$sys_path")" > "$sys_path/driver/unbind" 2>/dev/null
            fi
        fi

        echo -e "${YELLOW}[*] Перезавантаження правил udev...${NC}"
        udevadm control --reload-rules && udevadm trigger

        echo -e "${GREEN}[+] USB-пристрій відключено та видалено з активної пам'яті шини.${NC}"
        echo -e "${CYAN}[i] При повторному підключенні пристрій буде розпізнано заново.${NC}"
        pause
    fi
}

# --- КАТАЛОГ 2: DOOMSDAY (ФАЙЛИ ТА ПРОЦЕСИ) ---
doomsday_menu() {
    draw_banner
    echo -e "${YELLOW}[ МОДУЛЬ: DOOMSDAY (ПРОЦЕСИ ТА ФАЙЛИ) ]${NC}"
    echo -e "1) ${RED}Повне знищення цільових JAR/процесів та логів${NC}"
    echo -e "2) Прихований запуск JAR (без фонового виводу)${NC}"
    echo -e "3) Повернутися в головне меню"
    echo ""
    read -rp "Оберіть опцію [1-3]: " doom_opt

    if [ "$doom_opt" = "1" ]; then
        read -rp "Введіть маску або назву файлу для знищення (наприклад, cheat або test.jar): " target_pattern
        
        if [ -z "$target_pattern" ]; then
            echo -e "${RED}[!] Маску не вказано.${NC}"
            pause
            return
        fi

        echo -e "${RED}[*] Зупинка відповідних Java-процесів...${NC}"
        pkill -f "$target_pattern" 2>/dev/null

        echo -e "${YELLOW}[*] Безповоротне видалення файлів (shred)...${NC}"
        # Shred: 3 проходи затирання + затирання нулями + видалення
        find ~ /tmp /var/tmp -maxdepth 4 -name "*${target_pattern}*" -type f -exec shred -u -z -n 3 {} \; 2>/dev/null

        echo -e "${YELLOW}[*] Очищення тимчасового кешу додатків...${NC}"
        rm -rf ~/.cache/* 2>/dev/null

        echo -e "${GREEN}[+] Процеси зупинено, відповідні файли безповоротно знищено.${NC}"
        pause

    elif [ "$doom_opt" = "2" ]; then
        read -rp "Введіть повний шлях до JAR файлу: " jar_path
        
        # Розгортання ~ у повний шлях
        jar_path="${jar_path/#\~/$HOME}"

        if [ ! -f "$jar_path" ]; then
            echo -e "${RED}[!] Файл не знайдено за вказаним шляхом!${NC}"
            pause
            return
        fi

        echo -e "${CYAN}[*] Автономний запуск у фоновому режимі...${NC}"
        
        # Відв'язуємо процес від терміналу і глушимо stdout/stderr
        nohup java -jar "$jar_path" >/dev/null 2>&1 &
        disown

        echo -e "${GREEN}[+] Файл успішно запущено автономно.${NC}"
        pause
    fi
}

# --- КАТАЛОГ 3: CLEANER (САМОЗНИЩЕННЯ СЛІДІВ) ---
cleaner_menu() {
    draw_banner
    echo -e "${YELLOW}[ МОДУЛЬ: CLEANER (ОЧИЩЕННЯ ІСТОРІЇ) ]${NC}"
    echo -e "1) ${RED}Очистити буфер обміну та історію команд${NC}"
    echo -e "2) Повернутися в головне меню"
    echo ""
    read -rp "Оберіть опцію [1-2]: " clean_opt

    if [ "$clean_opt" = "1" ]; then
        echo -e "${YELLOW}[*] Очищення буфера обміну (X11 / Wayland)...${NC}"
        
        # Перевірка інструментів буфера обміну
        if command -v wl-copy &>/dev/null; then
            wl-copy --clear
        fi
        if command -v xclip &>/dev/null; then
            echo -n "" | xclip -selection clipboard 2>/dev/null
            echo -n "" | xclip -selection primary 2>/dev/null
        fi
        if command -v xsel &>/dev/null; then
            xsel -cb 2>/dev/null
            xsel -cp 2>/dev/null
        fi

        echo -e "${YELLOW}[*] Видалення згадок скрипта з файлів історії shell...${NC}"
        
        script_name=$(basename "$0")
        
        if [ -f ~/.bash_history ]; then
            sed -i "/$script_name/d" ~/.bash_history
            sed -i "/galik/d" ~/.bash_history
        fi
        
        if [ -f ~/.zsh_history ]; then
            sed -i "/$script_name/d" ~/.zsh_history
            sed -i "/galik/d" ~/.zsh_history
        fi

        # Скидання історії в поточній сесії
        history -c 2>/dev/null

        echo -e "${GREEN}[+] Буфер обміну та історію shell-файлів зачищено!${NC}"
        pause
        exit 0
    fi
}

# --- ГОЛОВНИЙ ЦИКЛ ---
while true; do
    draw_banner
    echo -e "${BOLD}${BLUE}Головне меню:${NC}"
    echo -e "1) 📁 Каталог: ${CYAN}USB DoomsDay Cleaner${NC}"
    echo -e "2) 📁 Каталог: ${RED}DoomsDay (Процеси та файли)${NC}"
    echo -e "3) 📁 Каталог: ${GREEN}Cleaner (Самознищення слідів)${NC}"
    echo -e "4) ❌ Вийти"
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    read -rp "Будь ласка, оберіть каталог [1-4]: " main_opt

    case "$main_opt" in
        1) usb_menu ;;
        2) doomsday_menu ;;
        3) cleaner_menu ;;
        4) clear; echo -e "${GREEN}Сесію завершено.${NC}"; exit 0 ;;
        *) echo -e "${RED}Невірний вибір.${NC}"; sleep 1 ;;
    esac
done
