FROM ubuntu:22.04

# Установка часового пояса и предотвращение интерактивных запросов
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Moscow

# Установка необходимых пакетов для pgpool и клиента
RUN apt-get update && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get install -y \
    pgpool2 \
    postgresql-client \
    vim \
    nano \
    sudo \
    net-tools \
    iputils-ping \
    telnet \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Создаем пользователя для работы
RUN useradd -m -s /bin/bash ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "ubuntu:ubuntu" | chpasswd

# Создаем директорию для pgpool
RUN mkdir -p /var/run/pgpool && \
    chown ubuntu:ubuntu /var/run/pgpool

# Открываем порт для pgpool
EXPOSE 5432

# Держим контейнер запущенным
CMD ["tail", "-f", "/dev/null"]