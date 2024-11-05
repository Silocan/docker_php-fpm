FROM php:7.2-fpm-alpine

RUN set -ex; \
    \
    apk update; \
    apk add \
    libjpeg-turbo-dev \
    libpng-dev \
    freetype-dev \
    libxml2-dev \
    icu-dev \
    msmtp \
    curl-dev \
    git \
    zip \
    unzip \
    libxml2-dev \
    openssl-dev \
    pkgconfig \
    gnu-libiconv \
    imap-dev \
    openssh-client \
    ; \
    rm -rf /var/lib/apt/lists/*;

RUN curl -sSLf \
    -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions


COPY --link docker/msmtp/msmtprc /etc/msmtprc
COPY --link docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Composer v1.x
RUN set -ex; \
    curl -sS https://getcomposer.org/installer | php -- --version=1.10.26 --install-dir=/usr/local/bin --filename=composer; \     
    chmod +x /usr/local/bin/composer
# Composer v2.x
RUN set -ex; \  
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer2; \     
    chmod +x /usr/local/bin/composer2

# Client blackfire
RUN mkdir -p /tmp/blackfire \
    && architecture=$(uname -m) \
    && curl -A "Docker" -L https://blackfire.io/api/v1/releases/cli/linux/$architecture | tar zxp -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire /usr/bin/blackfire \
    && rm -Rf /tmp/blackfire

RUN install-php-extensions blackfire xdebug intl opcache pdo gd zip bcmath xml mysqli curl calendar pdo_mysql redis mongodb ldap soap imagick apcu;


WORKDIR /var/www

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]