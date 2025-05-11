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

mkdir -p /var/run/pgpool

pgpool -n -f /etc/pgpool2/pgpool.conf > /var/log/pgpool.log 2>&1 &