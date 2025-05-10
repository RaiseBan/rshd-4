#!/bin/bash

# Устанавливаем владельца для директории данных
chown -R postgres:postgres /var/lib/postgresql

# Инициализируем базу данных если её нет
if [ ! -d "$PGDATA" ]; then
    su - postgres -c "/usr/lib/postgresql/14/bin/initdb -D $PGDATA"
fi

# Копируем конфигурационный файл
cp /etc/postgresql/postgresql.conf $PGDATA/postgresql.conf

# Настраиваем pg_hba.conf для разрешения подключений
cat > $PGDATA/pg_hba.conf << EOF
local   all             all                                     trust
host    all             all             0.0.0.0/0               md5
host    replication     all             0.0.0.0/0               md5
EOF

# Запускаем PostgreSQL
su - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D $PGDATA start"

# Ждем запуска сервера
sleep 5

# Создаем пользователей и базу данных
su - postgres -c "psql -p 5433 -c \"CREATE USER buddy WITH PASSWORD '123';\""
su - postgres -c "psql -p 5433 -c \"CREATE USER replicator WITH REPLICATION PASSWORD 'replicator123';\""
su - postgres -c "psql -p 5433 -c \"CREATE DATABASE testdb;\""

# Создаем тестовые таблицы
su - postgres -c "psql -p 5433 -d testdb -c \"CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(100), email VARCHAR(100));\""
su - postgres -c "psql -p 5433 -d testdb -c \"CREATE TABLE orders (id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id), amount DECIMAL(10,2), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);\""

# Добавляем тестовые данные
su - postgres -c "psql -p 5433 -d testdb -c \"INSERT INTO users (name, email) VALUES ('User 1', 'user1@test.com'), ('User 2', 'user2@test.com');\""
su - postgres -c "psql -p 5433 -d testdb -c \"INSERT INTO orders (user_id, amount) VALUES (1, 100.50), (2, 250.75);\""

# Держим контейнер запущенным
tail -f /dev/null