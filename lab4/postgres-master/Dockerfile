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
    openssh-client \
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Копируем файлы (но не запускаем автоматически)
COPY postgresql.conf /postgresql.conf
COPY init.sh /init.sh
RUN chmod +x /init.sh

# Устанавливаем переменные среды
ENV PGDATA=/var/lib/postgresql/data
ENV PGVERSION=14

# Разрешаем доступ к PostgreSQL
RUN echo "postgres ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Открываем порт
EXPOSE 5433

# Просто держим контейнер запущенным
CMD ["tail", "-f", "/dev/null"]