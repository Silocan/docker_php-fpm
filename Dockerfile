FROM curlimages/curl:7.83.1

FROM php:7.4-fpm-alpine

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
    libzip-dev \
    vim \
    libxml2-dev \
    ssmtp \
    openssl-dev \
    libssh2 \
    libssh2-dev \
    libssh2-dev \
    pkgconfig \
    openssh-client \
    imagemagick-dev \
    imap-dev \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    \
    docker-php-ext-configure mysqli; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install intl opcache pdo pdo_mysql gd zip bcmath xml json mysqli curl calendar sockets imap;

# fix work iconv library with alphine
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.12/community/ gnu-libiconv=1.15-r2
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

# Install and configure MongoDB Ext
RUN apk --update add --virtual build-dependencies build-base openssl-dev autoconf \
  && pecl install mongodb \
  && docker-php-ext-enable mongodb \
  && apk del build-dependencies build-base openssl-dev autoconf \
  && rm -rf /var/cache/apk/*
  
# Install and configure Redis Ext
RUN apk --update add --virtual build-dependencies build-base openssl-dev autoconf \
    && pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

# Enable LDAP
RUN apk add --update --no-cache \
          libldap && \
      # Build dependancy for ldap \
      apk add --update --no-cache --virtual .docker-php-ldap-dependancies \
          openldap-dev && \
      docker-php-ext-configure ldap && \
      docker-php-ext-install ldap && \
      apk del .docker-php-ldap-dependancies && \
      php -m;

# Install and configure Imagick
RUN apk add --update --no-cache autoconf g++ imagemagick-dev libtool make pcre-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && apk del autoconf g++ libtool make pcre-dev

# Composer 
RUN set -ex; \     
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \     
    chmod +x /usr/local/bin/composer

RUN set -ex; \     
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer1 --version=1.10.26 ; \     
    chmod +x /usr/local/bin/composer1

RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(uname -m) \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/$architecture/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8307\nblackfire.apm_enabled=0\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY --from=0 /usr/bin/curl /usr/bin/curl
COPY --from=0 /usr/include/curl /usr/include/curl
COPY --from=0 /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4.8.0
RUN ln -sf /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4
RUN ln -sf /usr/lib/libcurl.so.4 /usr/lib/libcurl.so

WORKDIR /var/www

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]