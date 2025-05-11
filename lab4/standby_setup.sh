echo 'export PATH=/usr/lib/postgresql/14/bin:$PATH' >> ~/.bashrc


export PATH=/usr/lib/postgresql/14/bin:$PATH

mkdir -p ~/.ssh
chmod 700 ~/.ssh


cat > ~/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBhp/QKn/aOtyOXJ6fvOTD/hro6bIy/C/HUDNdYPoGI6/z3yGXus+AqgXXpFXnlUtLhWvR93BQ5qq8F+tbrytucyOyD6oS5xBjMtSMf3ZzciAA+TLhu7SUgIdIM9C8vhfRxNjo43sXL450bBfqe1FRYDKGwVMpia3QrkWdCa+geBhIawQcuw2FufIQfXKSAeH+Usq+V0VAJ+jPoC0UtjsdBwJCgWfssRNLrl87RVjTqPbphTjPtRdlSwoiVSR3l1aDrsrOLR8gC1TgRUHd9Juw6uO624Z0ReQclU2EQAfDHg/bQN/HJH0YV4nCHm/zTIYO16hdaad9fC8ZEoDmi7THvJLw5qumYWBCeN9ixGmAEq4mdcJ+dM/maqKIaHA/NxX3NxcKjWydJMCJw+yklYSuJv/h/XROO2X8GMg2zGlpS3kiL7py3AmXGdAOPZfIBa6zrIGBl3rWsAmKWIICvyQHibPXCPf3+lyyapjfFiozks1dzmdF2WJ4LHHLK5u6X201eOKoE69xcX8YEinqDO1gddepXKc6JaDmkBRGjGYRgCaLfkhJ/aC/66hvWRqw+4PcktIrrfy+6rnD8/aEupnKbLh8cTeJ4BxQguxeT5EBqmT13QL7DN3S5XlW8iUGJthRDr+KHf0oZxWr/anM41eVeySHUXulOPfYzWeNYMDvlw== postgres@postgres-master
EOF

chmod 600 ~/.ssh/authorized_keys


PGPASSWORD=123 pg_basebackup -h 172.20.0.10 -p 5433 -U replicator -D ~/database -P -v -R --wal-method=stream -C -S replica_slot

pg_ctl -D ~/database start

