#!/bin/bash

# Команды под root
echo 'export PATH=/usr/lib/postgresql/14/bin:$PATH' >> ~/.bashrc
export PATH=/usr/lib/postgresql/14/bin:$PATH

dd if=/dev/zero of=/var/lib/postgresql/pgdisk.fs bs=1024 count=100000
mkfs.ext3 /var/lib/postgresql/pgdisk.fs
mkdir -p /var/lib/postgresql/limited_space
mount -t ext3 -o loop /var/lib/postgresql/pgdisk.fs /var/lib/postgresql/limited_space
chown postgres:postgres /var/lib/postgresql/limited_space

# Команды под postgres
su - postgres -c "
export PATH=/usr/lib/postgresql/14/bin:$PATH
cd /var/lib/postgresql/limited_space
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

psql -p 5433 -c \"CREATE USER buddy WITH PASSWORD '123';\"
psql -p 5433 -c \"CREATE USER replicator WITH REPLICATION PASSWORD '123';\"

mkdir -p ~/.ssh
ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
"