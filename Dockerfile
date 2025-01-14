#FROM curlimages/curl:7.83.1
FROM curlimages/curl:latest

FROM php:8.2-fpm-alpine

RUN set -ex; \
    \
    apk update; \
    apk add \
    icu-dev \
    msmtp \
    git \
    zip \
    unzip \
    libzip-dev \
    vim \
    libxml2-dev \
    ssmtp \
    openssl-dev \
    pkgconfig \
    openssh-client \
    libssh2 \
    libssh2-dev \
    gcc make g++ zlib-dev autoconf linux-headers \
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

RUN install-php-extensions ldap xdebug intl opcache pdo gd zip bcmath xml mysqli curl calendar pdo_mysql redis mongodb-1.20.1 ldap soap;
RUN install-php-extensions grpc protobuf opentelemetry;

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy curl
COPY --from=0 /usr/bin/curl /usr/bin/curl
COPY --from=0 /usr/include/curl /usr/include/curl
COPY --from=0 /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4.8.0
RUN ln -sf /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4
RUN ln -sf /usr/lib/libcurl.so.4 /usr/lib/libcurl.so

WORKDIR /var/www

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]
