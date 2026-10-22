# syntax=docker/dockerfile:1

# curl avec SFTP/SCP (libssh2) — le paquet Alpine ne l'embarque pas
FROM curlimages/curl:8.12.1 AS curl

FROM php:8.3-fpm-alpine

ARG TARGETARCH

ENV LOCALTIME=Europe/Paris \
    LANG=fr_FR.UTF-8 \
    LANGUAGE=fr_FR.UTF-8 \
    VAULT_VERSION=1.19.5 \
    SHELL=/bin/bash

# Runtime + outils CI/CD (bash/rsync/ssh/wget)
# gcompat : binaire Vault officiel lié contre glibc
RUN --mount=type=cache,target=/etc/apk/cache,sharing=locked \
    apk add \
        bash \
        gcompat \
        git \
        icu-data-full \
        icu-libs \
        libssh2 \
        libxml2 \
        libzip \
        msmtp \
        openssh-client \
        openssl \
        rsync \
        tzdata \
        unzip \
        wget \
        zip \
    && ln -sf /bin/bash /bin/sh \
    && sed -i 's#/bin/ash#/bin/bash#' /etc/passwd

# Composer + install-php-extensions (images officielles)
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Extensions PHP (build deps gérées par install-php-extensions)
RUN --mount=type=cache,target=/etc/apk/cache,sharing=locked \
    install-php-extensions \
        amqp \
        bcmath \
        calendar \
        curl \
        gd \
        intl \
        ldap \
        mongodb-1.21.0 \
        mysqli \
        opcache \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        redis \
        soap \
        xdebug \
        xml \
        xsl \
        zip

# PHPUnit CLI (les projets modernes passent par composer ; helper pour la CI)
RUN wget -qO /usr/local/bin/phpunit10 https://phar.phpunit.de/phpunit-10.phar \
    && wget -qO /usr/local/bin/phpunit11 https://phar.phpunit.de/phpunit-11.phar \
    && chmod +x /usr/local/bin/phpunit10 /usr/local/bin/phpunit11 \
    && ln -sf phpunit11 /usr/local/bin/phpunit

# Vault CLI (utilisé par vault.sh / vault-v2.sh en CI)
RUN case "${TARGETARCH}" in \
        amd64) VAULT_ARCH=amd64 ;; \
        arm64) VAULT_ARCH=arm64 ;; \
        *) echo "arch non supportée: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && wget -qO /tmp/vault.zip \
        "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip" \
    && unzip -q /tmp/vault.zip -d /usr/local/bin \
    && rm -f /tmp/vault.zip \
    && chmod +x /usr/local/bin/vault \
    && vault version

# curl CLI avec SFTP (écrase éventuellement le curl système)
COPY --from=curl /usr/bin/curl /usr/bin/curl
COPY --from=curl /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4.8.0
RUN ln -sf /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4 \
    && ln -sf /usr/lib/libcurl.so.4 /usr/lib/libcurl.so

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www

EXPOSE 9000

# CVE-2026-109618 / CVE-2026-109619 : lu au démarrage via conf.d, avant le parsing des requêtes
RUN printf 'session.upload_progress.enabled = Off\n' > "${PHP_INI_DIR}/conf.d/99-disable-upload-progress.ini"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm", "-F"]

