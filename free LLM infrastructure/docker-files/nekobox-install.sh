#!/usr/bin/env bash
set -e

# ==========================================
# 1. Проверка и установка Docker
# ==========================================
install_docker() {
    echo "=========================================="
    echo " Docker не обнаружен в системе."
    echo " Выберите ваш дистрибутив Linux:"
    echo "=========================================="
    echo "1) Ubuntu / Debian"
    echo "2) CentOS / RHEL / Rocky / AlmaLinux"
    echo "3) ALT Linux"
    echo "4) Fedora"
    echo "5) Arch Linux"
    echo "6) Универсальная авто-установка (get.docker.com)"
    echo "=========================================="
    read -rp "Введите номер (1-6): " os_choice

    case $os_choice in
        1)
            echo "[+] Установка Docker для Ubuntu/Debian..."
            sudo apt-get update
            sudo apt-get install -y docker.io
            ;;
        2)
            echo "[+] Установка Docker для CentOS/RHEL..."
            if command -v dnf &> /dev/null; then
                sudo dnf install -y docker-ce docker-ce-cli containerd.io || sudo dnf install -y docker
            else
                sudo yum install -y docker
            fi
            ;;
        3)
            echo "[+] Установка Docker для ALT Linux..."
            sudo apt-get update
            sudo apt-get install -y docker-engine
            ;;
        4)
            echo "[+] Установка Docker для Fedora..."
            sudo dnf install -y docker
            ;;
        5)
            echo "[+] Установка Docker для Arch Linux..."
            sudo pacman -Sy --noconfirm docker
            ;;
        6|*)
            echo "[+] Запуск универсального скрипта установки Docker..."
            curl -fsSL https://get.docker.com | sh
            ;;
    esac

    echo "[+] Запуск и добавление Docker в автозагрузку..."
    sudo systemctl enable --now docker || sudo service docker start
}

if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "[✓] Docker уже установлен в системе."
fi

# Добавляем текущего пользователя в группу docker (если нужно)
if [ -n "$SUDO_USER" ]; then
    sudo usermod -aG docker "$SUDO_USER" 2>/dev/null || true
fi

# ==========================================
# 2. Создание Dockerfile для NekoBox
# ==========================================
echo "[1/3] Подготовка Dockerfile..."
cat << 'EOF' > Dockerfile.nekoray
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget unzip binutils iptables iproute2 \
    libqt5widgets5 libqt5network5 libqt5gui5 libqt5core5a libqt5svg5 libqt5x11extras5 \
    libgl1-mesa-glx libfontconfig1 ca-certificates \
    libxcb-xinerama0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
    libxcb-render-util0 libxcb-shape0 libxcb-randr0 libxcb-xfixes0 libx11-xcb1 libdbus-1-3 \
    && rm -rf /var/lib/apt/lists/*

# Обход проверки версии ядра (совместимость со старыми ядрами вроде CentOS 7 Linux 3.10)
RUN strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5

WORKDIR /opt

RUN wget https://github.com/MatsuriDayo/nekoray/releases/download/4.0.1/nekoray-4.0.1-2024-12-12-linux64.zip \
    && unzip nekoray-4.0.1-2024-12-12-linux64.zip \
    && rm nekoray-4.0.1-2024-12-12-linux64.zip \
    && chmod +x /opt/nekoray/nekobox

CMD ["/opt/nekoray/nekobox"]
EOF

# ==========================================
# 3. Сборка Docker-образа
# ==========================================
echo "[2/3] Сборка Docker-образа nekoray-ui..."
sudo docker build -f Dockerfile.nekoray -t nekoray-ui .

# Включаем форвардинг пакетов для TUN-режима
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

# ==========================================
# 4. Создание глобальной команды `nekobox`
# ==========================================
echo "[3/3] Создание команды запуска '/usr/local/bin/nekobox'..."

cat << 'EOF' | sudo tee /usr/local/bin/nekobox > /dev/null
#!/usr/bin/env bash
xhost +local:root >/dev/null 2>&1
sudo DISPLAY=$DISPLAY docker run -it --rm \
  --name nekoray \
  --net=host \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -v /dev/net/tun:/dev/net/tun \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/.config/nekoray:/root/.config/nekoray \
  nekoray-ui "$@"
EOF

sudo chmod +x /usr/local/bin/nekobox

echo ""
echo "=========================================="
echo " Установка успешно завершена!"
echo " Запустите приложение командой: nekobox"
echo "=========================================="
