#!/bin/bash

echo "Остановка контейнеров..."
docker stop pgpool-vm3 postgres-vm1 postgres-vm2

echo "Удаление контейнеров..."
docker rm pgpool-vm3 postgres-vm1 postgres-vm2

echo "Удаление томов данных..."
rm -rf ./data1 ./data2

echo "Очистка завершена!"