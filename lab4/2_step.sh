psql -h localhost -p 5432 -U buddy -d postgres

cd /var/lib/postgresql/limited_space/database



# Заполняем основную директорию
dd if=/dev/zero of=./junk1 bs=1M count=1000

# Заполняем pg_wal
dd if=/dev/zero of=./pg_wal/junk2 bs=1M count=1000


# INSERT INTO orders (customer_name) 
# SELECT 'Customer ' || generate_series 
# FROM generate_series(1, 100000);


# Промотируем standby до master
pg_ctl -D ~/database promote
psql -p 5433 -c "SELECT pg_is_in_recovery();"




# Остановка старого master
docker exec -it -u postgres postgres-master bash
export PATH=/usr/lib/postgresql/14/bin:$PATH
pg_ctl -D /var/lib/postgresql/limited_space/database stop -m immediate



# На pgpool-client
docker exec -it pgpool-client bash

pkill -9 pgpool

cat > /etc/pgpool2/pgpool.conf << EOF
listen_addresses = '*'
port = 5432

backend_hostname0 = '172.20.0.11'
backend_port0 = 5433
backend_weight0 = 1

num_init_children = 5
max_pool = 4

enable_pool_hba = off
master_slave_mode = off
load_balance_mode = off
replication_mode = off
EOF

# запускаем
pgpool -n -f /etc/pgpool2/pgpool.conf



# ПРОВЕРКА

# Подключаемся через pgpool
psql -h localhost -p 5432 -U buddy -d postgres

SELECT * FROM orders ORDER BY id DESC LIMIT 5;

INSERT INTO orders (customer_name) VALUES ('After failover test');

# Выйдите из psql
\q
