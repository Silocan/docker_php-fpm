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
    rm -rf /var/lib/apt/lists/*; \
    \
    docker-php-ext-configure mysqli; \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include --with-jpeg-dir=/usr/include; \
    docker-php-ext-install intl opcache pdo pdo_mysql mbstring gd zip bcmath xml json curl calendar iconv sockets imap;

# Installation apcu
RUN apk add --update --no-cache --virtual .build-dependencies $PHPIZE_DEPS \
        && pecl install apcu \
        && docker-php-ext-enable apcu \
        && pecl clear-cache \
        && apk del .build-dependencies

# Install and configure Imagick
RUN apk add --update --no-cache autoconf g++ imagemagick-dev libtool make pcre-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && apk del autoconf g++ libtool make pcre-dev

# Composer v1.x
RUN set -ex; \
    curl -sS https://getcomposer.org/installer | php -- --version=1.10.26 --install-dir=/usr/local/bin --filename=composer; \     
    chmod +x /usr/local/bin/composer
# Composer v2.x
RUN set -ex; \  
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer2; \     
    chmod +x /usr/local/bin/composer2

ENV UNO_URL https://raw.githubusercontent.com/dagwieers/unoconv/master/unoconv

# LibreOffice
RUN apk update && \
    apk --no-cache add util-linux libreoffice-common libreoffice-writer \
    ttf-droid-nonlatin ttf-droid ttf-dejavu ttf-freefont ttf-liberation \
    msttcorefonts-installer fontconfig && \
    update-ms-fonts && \
    fc-cache -f && \
    rm -fr /var/cache/apk/* && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    mkdir -p ~/.config/libreoffice && chmod -R 777 ~/.config/libreoffice \
    && curl -Ls $UNO_URL -o /usr/local/bin/unoconv \
    && chmod +x /usr/local/bin/unoconv

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]