#!/bin/bash

# Ждем запуска PostgreSQL серверов
sleep 20

# Копируем конфигурационный файл
cp /etc/pgpool2/pgpool.conf /etc/pgpool2/pgpool.conf.backup

# Создаем директорию для PID файла
mkdir -p /var/run/pgpool/
chown pgpool:pgpool /var/run/pgpool/

# Запускаем pgpool
/usr/sbin/pgpool -n -f /etc/pgpool2/pgpool.conf -a /etc/pgpool2/pool_hba.conf