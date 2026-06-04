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
    openssl-dev \
    pkgconfig \
    openssh-client \
    libssh2 \
    libssh2-dev \
    qpdf \
    bash \
    rsync \
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

RUN install-php-extensions grpc opentelemetry protobuf;
RUN install-php-extensions bcmath calendar curl gd intl ldap mongodb-2.3.0 mysqli opcache pdo pdo_mysql pdo_pgsql pdo_sqlsrv redis soap xdebug xml zip;

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy curl
#COPY --from=0 /usr/bin/curl /usr/bin/curl
#COPY --from=0 /usr/include/curl /usr/include/curl
#COPY --from=0 /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4.8.0
#RUN ln -sf /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4
#RUN ln -sf /usr/lib/libcurl.so.4 /usr/lib/libcurl.so

# install vector for data aggregation
#RUN curl --proto '=https' --tlsv1.2 -sSfL https://sh.vector.dev | sh -s -- -y --prefix /usr/local
#RUN rc-update add vector

# Installation de Vault
ENV VAULT_VERSION="1.19.5"
ENV VAULT_ZIP="vault_${VAULT_VERSION}_linux_amd64.zip"

RUN wget https://releases.hashicorp.com/vault/$VAULT_VERSION/$VAULT_ZIP && \
	unzip $VAULT_ZIP -d /usr/sbin && rm $VAULT_ZIP

WORKDIR /var/www

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]
