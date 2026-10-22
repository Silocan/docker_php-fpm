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
    \
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
    vim \
    libxml2-dev \
    libcurl3-dev \
    libonig-dev \
    mailutils \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    \    
    docker-php-ext-configure mysqli; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install intl opcache pdo pdo_mysql mbstring gd zip bcmath xml json mysqli curl calendar; \
    pecl install mongodb-1.20.1 && echo "extension=mongodb.so" >> $PHP_INI_DIR/conf.d/mongodb.ini

# Composer 
RUN set -ex; \     
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \     
    chmod +x /usr/local/bin/composer

RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm", "-F"]

# CVE-2026-109618 / CVE-2026-109619 : lu au démarrage via conf.d, avant le parsing des requêtes
RUN printf 'session.upload_progress.enabled = Off\n' > "${PHP_INI_DIR}/conf.d/99-disable-upload-progress.ini"
