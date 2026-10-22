FROM php:7.4-fpm
RUN set -eux; \
    if [ -f /etc/apt/sources.list ]; then \
      sed -i \
        -e 's|http://deb.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
        -e 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
        -e 's|http://deb.debian.org/debian |http://archive.debian.org/debian |g' \
        /etc/apt/sources.list; \
      sed -i '/buster-updates/d; /bullseye-updates/d' /etc/apt/sources.list; \
      printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99no-check-valid-until; \
    fi

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
    bash \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    ln -sf /bin/bash /bin/sh;

# Composer 
RUN set -ex; \     
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \     
    chmod +x /usr/local/bin/composer

RUN curl -sSLf \
    -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions

RUN install-php-extensions bcmath calendar curl gd imagick imap intl ldap mongodb-1.20.1 mysqli opcache pdo pdo_mysql redis soap sockets xdebug xsl xml zip;
#RUN install-php-extensions grpc protobuf opentelemetry;

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm", "-F"]

# CVE-2026-109618 / CVE-2026-109619 : lu au démarrage via conf.d, avant le parsing des requêtes
RUN printf 'session.upload_progress.enabled = Off\n' > "${PHP_INI_DIR}/conf.d/99-disable-upload-progress.ini"
