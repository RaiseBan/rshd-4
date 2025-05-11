docker exec -it -u root postgres-master bash

echo 'export PATH=/usr/lib/postgresql/14/bin:$PATH' >> ~/.bashrc
export PATH=/usr/lib/postgresql/14/bin:$PATH


dd if=/dev/zero of=/var/lib/postgresql/pgdisk.fs bs=1024 count=100000
mkfs.ext3 /var/lib/postgresql/pgdisk.fs
mkdir -p /var/lib/postgresql/limited
mount -t ext3 -o loop /var/lib/postgresql/pgdisk.fs /var/lib/postgresql/limited
chown postgres:postgres /var/lib/postgresql/limited

cd /var/lib/postgresql/limited
mkdir database

initdb -D database

cd database
cat > postgresql.conf << EOF
listen_addresses = '*'
port = 5433
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
hot_standby = on
EOF

cat > pg_hba.conf << EOF
local   all             all                                     trust
host    all             all             0.0.0.0/0               password
host    replication     all             0.0.0.0/0               password
EOF

cd ..
pg_ctl -D database start

psql -p 5433 -c "CREATE USER buddy WITH PASSWORD '123';"
psql -p 5433 -c "CREATE USER replicator WITH REPLICATION PASSWORD '123';"

mkdir -p ~/.ssh
ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub


#switch to standby node

docker exec -it -u postgres postgres-standby bash

echo 'export PATH=/usr/lib/postgresql/14/bin:$PATH' >> ~/.bashrc


export PATH=/usr/lib/postgresql/14/bin:$PATH


mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat > ~/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/8NSXih57D9lkrqlZCCOHcMe9PLYI4jrMC1BplsYTv0QkGpmj52lTcUoc/+zDYfSS2swKkfSoMGF11Mu3c3x1joVVD0TbAI6Vpxf2a30IYLtM7haFMT1/aLoMEvYrXVqzHuHmRj2XRdNoG3dccIaFKqPa73oZfz2M80v8TvM849wcNeiZCGOaPuZYn3xAAmIY2Gmr00UfOhD8DtzWVr7bQqCFgDs6ZYYIlN/siRuSYe+rjNunlStjMhIFmfVkEiBDYGD+sED1e28ObLocNfLBXy1eTOU+FYUEmcLzfCVPS4XWMsiO/W0veP30TROs+KGtmXVZ5Gwp+FFeVexBhJ71g8JE3vrolW3t7UJs6kspT8oQglEhMGF/+lXSQW2+SDglXcSaahJekg3gYGMZ7EZ7e0XCLTDvTLkuSvNEoJ1PFRaay6FWL/GIDCoRDBquGC3lHtxGE2TbfzYDVPyolGMJkXSpqroOSTagCY3Xtf5G1ZqURQeNVrY98t1KWnzeDcfJT5zZmzP2TmK4vJ/EEue+dRyiYH4VDUTdhjFWJxjSgitcFm4HGpuHxRMEdAA6Ne06HhuaXMB2OCtBEVBJlLa19oqZfCywGW4Anbo1rJkEas5r2/52FMOUjUmV1swBTv5LSI15DPiBUyFnYe5nqbgn6H/Of8GLwwqVUCtNt4gOuw== postgres@postgres-master
EOF
chmod 600 ~/.ssh/authorized_keys


PGPASSWORD=123 pg_basebackup -h 172.20.0.10 -p 5433 -U replicator -D ~/database -P -v -R --wal-method=stream -C -S replica_slot

pg_ctl -D ~/database start

exit

docker exec -it -u postgres postgres-master bash
export PATH=/usr/lib/postgresql/14/bin:$PATH
psql -p 5433 -c "SELECT * FROM pg_stat_replication;"

# on pgpool-clien node:




cat > /etc/pgpool2/pool_hba.conf << EOF
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD
local   all         all                               trust
host    all         all         127.0.0.1/32          password
host    all         all         ::1/128               password
host    all         all         0.0.0.0/0             password
EOF


cat > /etc/pgpool2/pgpool.conf << EOF
listen_addresses = '*'
port = 5432

backend_hostname0 = '172.20.0.10'
backend_port0 = 5433
backend_weight0 = 1
backend_data_directory0 = '/var/lib/postgresql/limited_space/database'
backend_flag0 = 'ALLOW_TO_FAILOVER'

backend_hostname1 = '172.20.0.11'
backend_port1 = 5433
backend_weight1 = 1
backend_data_directory1 = '/var/lib/postgresql/database'
backend_flag1 = 'ALLOW_TO_FAILOVER'

backend_clustering_mode = 'streaming_replication'

log_connections = on
log_hostname = on
log_statement = on
log_per_node_statement = on
log_min_messages = debug5
log_error_verbosity = verbose

EOF


# test

cat > /etc/pgpool2/pgpool.conf << EOF

listen_addresses = '*'
port = 5432

backend_hostname0 = '172.20.0.10'
backend_port0 = 5433
backend_weight0 = 1
backend_data_directory0 = '/var/lib/postgresql/limited_space/database'
backend_flag0 = 'ALLOW_TO_FAILOVER'

backend_hostname1 = '172.20.0.11'
backend_port1 = 5433
backend_weight1 = 1
backend_data_directory1 = '/var/lib/postgresql/database'
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



enable_pool_hba = on
backend_clustering_mode = 'streaming_replication'

mkdir -p /var/run/pgpool

pgpool -n -f /etc/pgpool2/pgpool.conf > /var/log/pgpool.log 2>&1 &

ps aux | grep pgpool
netstat -nlp | grep 5432

# test balancing and replication
psql -h localhost -p 5433 -U buddy -d postgres

CREATE TABLE test_replication (
    id SERIAL PRIMARY KEY,
    data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO test_replication (data) VALUES ('Test data 1'), ('Test data 2');

# check results of replication:

docker exec -u postgres postgres-master psql -p 5433 -c "SELECT * FROM test_replication;"

docker exec -u postgres postgres-standby psql -p 5433 -c "SELECT * FROM test_replication;"

# ВАЖНО если не работает подключение с локалки, то скорее всего у вас занят порт 5432, или изменить порт на другой при запуске контейнера или убить процесс postgresql

#powershell
Get-NetTCPConnection -LocalPort 5432 -ErrorAction SilentlyContinue
Get-Process -Id 7204,14564 | Select-Object Id, ProcessName, Path


