FROM php:7.4-fpm
LABEL maintainer="nicolas@unid-consulting.fr"


RUN set -ex; \
    apt-get -yqq update; \
    apt-get -yqq install \
    libjpeg62-turbo-dev \
    libpng-dev \
    libfreetype6-dev \
    libxml2-dev \
    libicu-dev \
    msmtp \
    curl \
    git \
    zip \
    unzip \
    libzip-dev \
    openssl \
    vim \
    libxml2-dev \
    libcurl3-dev \
    libonig-dev \
    mailutils \
    ; \
    rm -rf /var/lib/apt/lists/*;

# Composer 
RUN set -ex; \     
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \     
    chmod +x /usr/local/bin/composer

RUN curl -sSLf \
    -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions

RUN install-php-extensions ldap xdebug intl opcache pdo gd zip bcmath xml mysqli curl calendar pdo_mysql redis mongodb-1.20.1 ldap soap calendar sockets imap imagick;
#RUN install-php-extensions grpc protobuf opentelemetry;

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm", "-F"]
