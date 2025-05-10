#!/bin/bash

echo "=== ЭТАП 1: ДЕМОНСТРАЦИЯ ОБРАБОТКИ ТРАНЗАКЦИЙ ОБОИМИ СЕРВЕРАМИ ==="

echo -e "\n1. Перезапуск контейнеров с новой конфигурацией..."
docker-compose down
docker-compose up -d

echo "   Ожидание запуска серверов..."
sleep 20

# Проверка готовности
until docker exec postgres-vm1 pg_isready -U postgres -h localhost; do
    sleep 2
done
until docker exec postgres-vm2 pg_isready -U postgres -h localhost; do
    sleep 2
done

echo -e "\n2. Создание БД и таблиц на ОБОИХ серверах..."
# Создаем БД на обоих серверах
docker exec postgres-vm1 psql -U postgres -h localhost -c "DROP DATABASE IF EXISTS testdb;"
docker exec postgres-vm2 psql -U postgres -h localhost -c "DROP DATABASE IF EXISTS testdb;"

docker exec postgres-vm1 psql -U postgres -h localhost -c "CREATE DATABASE testdb;"
docker exec postgres-vm2 psql -U postgres -h localhost -c "CREATE DATABASE testdb;"

# Создаем таблицы с полем для идентификации сервера
docker exec postgres-vm1 psql -U postgres -h localhost -d testdb -c "
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    server_ip VARCHAR(50) DEFAULT inet_server_addr()
);"

docker exec postgres-vm2 psql -U postgres -h localhost -d testdb -c "
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    server_ip VARCHAR(50) DEFAULT inet_server_addr()
);"

docker exec postgres-vm1 psql -U postgres -h localhost -d testdb -c "
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    stock INT,
    server_ip VARCHAR(50) DEFAULT inet_server_addr()
);"

docker exec postgres-vm2 psql -U postgres -h localhost -d testdb -c "
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    stock INT,
    server_ip VARCHAR(50) DEFAULT inet_server_addr()
);"

echo -e "\n3. Проверка статуса узлов..."
docker exec pgpool-vm3 psql -h localhost -p 5432 -U postgres -c "show pool_nodes;"

echo -e "\n4. ДЕМОНСТРАЦИЯ: Балансировка транзакций ЗАПИСИ между серверами..."
echo "   Выполняем 10 INSERT операций через pgpool:"

for i in {1..10}; do
    result=$(docker exec pgpool-vm3 psql -h localhost -p 5432 -U postgres -d testdb -t -c "INSERT INTO orders (customer_name, amount) VALUES ('Customer $i', $((i * 100))) RETURNING id, server_ip;")
    echo "   INSERT $i результат: $result"
done

echo -e "\n5. Проверка распределения данных между серверами..."
echo "   Записи на сервере 1 (192.168.1.101):"
docker exec postgres-vm1 psql -U postgres -h localhost -d testdb -c "SELECT COUNT(*) as order_count, server_ip FROM orders GROUP BY server_ip;"
docker exec postgres-vm1 psql -U postgres -h localhost -d testdb -c "SELECT * FROM orders ORDER BY id;"

echo -e "\n   Записи на сервере 2 (192.168.1.102):"
docker exec postgres-vm2 psql -U postgres -h localhost -d testdb -c "SELECT COUNT(*) as order_count, server_ip FROM orders GROUP BY server_ip;"
docker exec postgres-vm2 psql -U postgres -h localhost -d testdb -c "SELECT * FROM orders ORDER BY id;"

echo -e "\n6. ДЕМОНСТРАЦИЯ: Транзакции с множественными операциями..."
echo "   Транзакция 1:"
docker exec pgpool-vm3 psql -h localhost -p 5432 -U postgres -d testdb -c "
BEGIN;
INSERT INTO products (product_name, price, stock) VALUES ('Laptop', 999.99, 50);
INSERT INTO orders (customer_name, amount) VALUES ('Transaction Customer 1', 999.99);
COMMIT;
SELECT 'Transaction 1 completed on server:', server_ip FROM orders WHERE customer_name = 'Transaction Customer 1';"

echo -e "\n   Транзакция 2:"
docker exec pgpool-vm3 psql -h localhost -p 5432 -U postgres -d testdb -c "
BEGIN;
INSERT INTO products (product_name, price, stock) VALUES ('Mouse', 29.99, 200);
INSERT INTO orders (customer_name, amount) VALUES ('Transaction Customer 2', 29.99);
COMMIT;
SELECT 'Transaction 2 completed on server:', server_ip FROM orders WHERE customer_name = 'Transaction Customer 2';"

echo -e "\n7. ДЕМОНСТРАЦИЯ: Параллельные сессии..."
echo "   Запуск 2 параллельных сессий с транзакциями:"

{
    docker exec pgpool-vm3 psql -h localhost -p 5432 -U postgres -d testdb -c "
    BEGIN;
    INSERT INTO orders (customer_name, amount) VALUES ('Parallel Session 1', 111.11);
    SELECT pg_sleep(1);
    COMMIT;
    SELECT 'Session 1 on server:', server_ip FROM orders WHERE customer_name = 'Parallel Session 1';"
} &

{
    docker exec pgpool-vm3 psql -h localhost -p 5432 -U postgres -d testdb -c "
    BEGIN;
    INSERT INTO orders (customer_name, amount) VALUES ('Parallel Session 2', 222.22);
    COMMIT;
    SELECT 'Session 2 on server:', server_ip FROM orders WHERE customer_name = 'Parallel Session 2';"
} &

wait

echo -e "\n8. ДЕМОНСТРАЦИЯ: Балансировка чтения..."
echo "   Выполняем 5 SELECT запросов:"
for i in {1..5}; do
    echo "   SELECT $i:"
    docker exec pgpool-vm3 psql -h localhost -p 5432 -U postgres -d testdb -t -c "SELECT inet_server_addr() as reading_from_server, COUNT(*) as record_count FROM orders GROUP BY inet_server_addr();"
done

echo -e "\n9. Финальная статистика..."
docker exec pgpool-vm3 psql -h localhost -p 5432 -U postgres -c "show pool_nodes;"

echo -e "\n10. ИТОГОВАЯ ПРОВЕРКА..."
echo "   Общее количество записей на сервере 1:"
docker exec postgres-vm1 psql -U postgres -h localhost -d testdb -t -c "SELECT COUNT(*) FROM orders;"
echo "   Общее количество записей на сервере 2:"
docker exec postgres-vm2 psql -U postgres -h localhost -d testdb -t -c "SELECT COUNT(*) FROM orders;"

echo -e "\n=== РЕЗУЛЬТАТЫ ДЕМОНСТРАЦИИ ==="
echo "1. ОБА сервера обрабатывают транзакции ЗАПИСИ"
echo "2. ОБА сервера обрабатывают транзакции ЧТЕНИЯ"
echo "3. Данные распределены между серверами"
echo "4. Каждый сервер содержит только свою часть данных"
echo "5. Это демонстрирует проблему балансировки без репликации"