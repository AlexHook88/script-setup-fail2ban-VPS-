#!/bin/bash

set -e

# Проверяем права root
if [ "$EUID" -ne 0 ]; then
    echo "Запусти скрипт от root или через sudo"
    exit 1
fi

echo "===== Установка Fail2ban ====="

apt update
apt install -y fail2ban nano

echo "===== Создание конфигурации ====="

cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 5

[sshd]
enabled = true
backend = systemd
port = ssh
maxretry = 5
bantime = 10m
findtime = 10m
EOF

echo "===== Запуск Fail2ban ====="

systemctl enable fail2ban
systemctl restart fail2ban

echo "===== Ожидание готовности Fail2ban ====="

READY=0

for i in {1..15}; do
    if fail2ban-client ping >/dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo "ОШИБКА: Fail2ban не запустился!"
    systemctl status fail2ban --no-pager -l
    exit 1
fi

echo "===== Проверка работы ====="

fail2ban-client status
fail2ban-client status sshd

echo "===== Параметры защиты ====="

echo "Время блокировки:"
fail2ban-client get sshd bantime

echo "Период подсчёта:"
fail2ban-client get sshd findtime

echo "Количество попыток:"
fail2ban-client get sshd maxretry

echo "===== ГОТОВО! ====="
