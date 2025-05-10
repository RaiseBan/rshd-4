docker exec -it -u postgres postgres-master bash
echo 'export PATH=/usr/lib/postgresql/14/bin:$PATH' >> ~/.bashrc

cd ~
mkdir database

initdb -D database

cd database
cat >> postgresql.conf << EOF
listen_addresses = '*'
port = 5433
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
hot_standby = on
EOF

cat > pg_hba.conf << EOF
local   all             all                                     trust
host    all             all             0.0.0.0/0               md5
host    replication     all             0.0.0.0/0               md5
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


# export PATH=/usr/lib/postgresql/14/bin:$PATH


mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat > ~/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAvDpZtVu8UZ3a+6QntVCBo4M3huUz3/bamPCxJ9NUAMkk8GiQ0WbdN9CUrORvZpR9wmzSAcQzIGYlsRf8sQLc7dOtrrZuAnTDhu9f3eE3WLh/NdXpz9oOQQj3KxncEfdew1eV7Z9B0HWcKA6qUB4piq3dhi0DdmeTl+z95DMAYXA6LDgRz+cbeNGeZd774H2JMHBrFPgblrMnGm2AnxtFMDujc6AnU20JtUtAvVO3kspoatOYDBB4Uu04QfuvPXJAtPhYlxZKAqBGsJ5JUQUqh85W+cmY/u0ViF5AaCRhv7s5klzbqAyIT1ygUD+a6/fhkVznk7us2CJHEe2isYzuq5JNwjHVyHqzUmFSlAvKVddGnDVANzIoquH3AWMNta88EIlQ0DBs280F2EJbYmoNv9Pi4SkKrGlT63LqBMEUuhw73hJj/1VhEOgnKbN/z7qA8zPAcFeKNz3BIlfuXtyan9IgStU/6iTyC/uIpGQTipP7EC1pIPMKxRGCtxIvPmycOVW6Pg6oEFABLxFgCEq53ylCQmlfi6rJb62yWeSwG93Ds7lmB/oqhcShmPwONINEtj5lR6/S+7IIAe+0nya3OdcyEvKDToDSzt8WKwcRqJpg7CVMIRSfHSduv9/41BvXwnJ2wDDvohQJwZWztyxELihNJxOupx/o+kWdByeV7w== postgres@postgres-master
EOF
chmod 600 ~/.ssh/authorized_keys


PGPASSWORD=123 pg_basebackup -h 172.20.0.10 -p 5433 -U replicator -D ~/database -P -v -R --wal-method=stream -C -S replica_slot

pg_ctl -D ~/database start


docker exec -it -u postgres postgres-master bash
export PATH=/usr/lib/postgresql/14/bin:$PATH
psql -p 5433 -c "SELECT * FROM pg_stat_replication;"

# on pgpool-clien node:

cat > /etc/pgpool2/pgpool.conf << EOF
listen_addresses = '*'
port = 5432

backend_hostname0 = '172.20.0.10'
backend_port0 = 5433
backend_weight0 = 1
backend_data_directory0 = '/var/lib/postgresql/database'
backend_flag0 = 'ALLOW_TO_FAILOVER'
backend_application_name0 = 'master'

backend_hostname1 = '172.20.0.11'
backend_port1 = 5433
backend_weight1 = 1
backend_data_directory1 = '/var/lib/postgresql/database'
backend_flag1 = 'ALLOW_TO_FAILOVER'
backend_application_name1 = 'standby'

num_init_children = 32
max_pool = 4
backend_clustering_mode = 'streaming_replication'
load_balance_mode = on

sr_check_period = 10
sr_check_user = 'replicator'
sr_check_password = '123'
sr_check_database = 'postgres'

enable_pool_hba = off
EOF
cd /etc/pgpool2
pg_md5 -m -u buddy 123


mkdir -p /var/run/pgpool

pgpool -n -f /etc/pgpool2/pgpool.conf > /var/log/pgpool.log 2>&1 &
ps aux | grep pgpool
netstat -nlp | grep 5432