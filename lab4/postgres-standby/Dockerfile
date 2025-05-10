FROM ubuntu:22.04

# Установка часового пояса и предотвращение интерактивных запросов
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Moscow

# Установка необходимых пакетов
RUN apt-get update && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get install -y \
    postgresql \
    postgresql-contrib \
    postgresql-client \
    openssh-server \
    vim \
    nano \
    sudo \
    net-tools \
    iputils-ping \
    telnet \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем переменные среды
ENV PGDATA=/var/lib/postgresql/data
ENV PGVERSION=14

# Разрешаем доступ к PostgreSQL
RUN echo "postgres ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Создаем пользователя ubuntu
RUN useradd -m -s /bin/bash ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "ubuntu:ubuntu" | chpasswd

# Настраиваем SSH для репликации
RUN mkdir /var/run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Создаем директорию для PostgreSQL run
RUN mkdir -p /var/run/postgresql && \
    chown postgres:postgres /var/run/postgresql

# Открываем порты
EXPOSE 5433 22

# Держим контейнер запущенным
CMD ["tail", "-f", "/dev/null"]