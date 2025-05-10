#!/bin/bash

# Устанавливаем владельца для директории данных
chown -R postgres:postgres /var/lib/postgresql

# Ждем запуска master сервера
sleep 10

# Создаем резервную копию с master сервера
rm -rf $PGDATA/*
su - postgres -c "PGPASSWORD=$REPLICATOR_PASSWORD /usr/lib/postgresql/14/bin/pg_basebackup -h $MASTER_HOST -p $MASTER_PORT -U replicator -D $PGDATA -P -v -R --wal-method=stream -C -S replica_slot"

# Настраиваем права доступа
chmod 700 $PGDATA
chown -R postgres:postgres $PGDATA

# Запускаем standby сервер
su - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D $PGDATA start"

# Держим контейнер запущенным
tail -f /dev/null