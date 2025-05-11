# На старом master
docker exec -it -u postgres postgres-master bash
export PATH=/usr/lib/postgresql/14/bin:$PATH

# Останавливаем PostgreSQL
pg_ctl -D /var/lib/postgresql/limited_space/database stop
rm -rf /var/lib/postgresql/limited_space/database

# Проверяем освободившееся место
df -h /var/lib/postgresql/limited_space

PGPASSWORD=123 pg_basebackup -h 172.20.0.11 -p 5433 -U replicator -D database -P -v -R --wal-method=stream -C -S replica_slot_restored

#запускаем как standby
pg_ctl -D database start

# проверем, что standby
psql -p 5433 -c "SELECT pg_is_in_recovery();"

# На новом master (postgres-standby)
psql -p 5433 -c "SELECT * FROM pg_stat_replication;"


# На pgpool-client



# cat > /etc/pgpool2/pgpool.conf << EOF
# listen_addresses = '*'
# port = 5432

# # Новый master (бывший standby)
# backend_hostname0 = '172.20.0.11'
# backend_port0 = 5433
# backend_weight0 = 1

# # Восстановленный standby (бывший master)
# backend_hostname1 = '172.20.0.10'
# backend_port1 = 5433
# backend_weight1 = 1

# num_init_children = 5
# max_pool = 4

# enable_pool_hba = off
# load_balance_mode = on
# master_slave_mode = off
# EOF

pkill -9 pgpool

cat > /etc/pgpool2/pgpool.conf << EOF

listen_addresses = '*'
port = 5432



backend_hostname0 = '172.20.0.11'
backend_port0 = 5433
backend_weight0 = 1
backend_data_directory0 = '/var/lib/postgresql/database'
backend_flag0 = 'ALLOW_TO_FAILOVER'

backend_hostname1 = '172.20.0.10'
backend_port1 = 5433
backend_weight1 = 1
backend_data_directory1 = '/var/lib/postgresql/limited_space/database'
backend_flag1 = 'ALLOW_TO_FAILOVER'


num_init_children = 32
max_pool = 4

backend_clustering_mode = 'streaming_replication'       
load_balance_mode = on
master_slave_mode = on
master_slave_sub_mode = stream
statement_level_load_balance = on
disable_load_balance_on_write = off



sr_check_period = 10
sr_check_user = 'replicator'
sr_check_password = '123'
sr_check_database = 'postgres'

enable_pool_hba = off

log_min_messages = debug1
log_per_node_statement = on
pool_passwd = '/etc/pgpool2/pgpool.conf'
EOF












# сбросить статусы
rm -rf /var/log/postgresql/pgpool_status


pgpool -n -f /etc/pgpool2/pgpool.conf




# Через pgpool подключаемся и проверяем
psql -h localhost -p 5432 -U buddy -d postgres

# проверка данных
SELECT COUNT(*) FROM orders;

# проверка записи
INSERT INTO orders (customer_name) VALUES ('Cluster fully restored');

# проверяем статус узлов
SHOW pool_nodes;




