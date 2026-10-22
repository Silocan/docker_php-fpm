# syntax=docker/dockerfile:1
FROM php:7.4-fpm-alpine

ARG TARGETARCH

ENV LOCALTIME=Europe/Paris \
    LANG=fr_FR.UTF-8 \
    LANGUAGE=fr_FR.UTF-8 \
    VAULT_VERSION=1.19.5 \
    SHELL=/bin/bash

# Runtime + outils CI/CD
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
        curl \
        openjdk17-jre-headless \
    && ln -sf /bin/bash /bin/sh \
    && sed -i 's#/bin/ash#/bin/bash#' /etc/passwd

# iconv musl est cassé sur les binaires officiels PHP 7.4
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community gnu-libiconv=1.15-r3
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

COPY --from=composer:2.2 /usr/bin/composer /usr/local/bin/composer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Extensions PHP (build deps gérées puis retirées par install-php-extensions)
RUN --mount=type=cache,target=/etc/apk/cache,sharing=locked \
    install-php-extensions \
        amqp \
        bcmath \
        calendar \
        curl \
        gd \
        intl \
        ldap \
        mongodb \
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
        zip \
        imagick \
        imap \
        sockets

RUN wget -qO /usr/local/bin/phpunit9 https://phar.phpunit.de/phpunit-9.phar \
    && chmod +x /usr/local/bin/phpunit9 \
    && ln -sf phpunit9 /usr/local/bin/phpunit

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

COPY pdftk /usr/local/bin/pdftk
RUN wget -qO /usr/local/bin/pdftk.jar \
        https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar \
    && chmod 755 /usr/local/bin/pdftk /usr/local/bin/pdftk.jar

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www

EXPOSE 9000

# CVE-2026-109618 / CVE-2026-109619 : lu au démarrage via conf.d, avant le parsing des requêtes
RUN printf 'session.upload_progress.enabled = Off\n' > "${PHP_INI_DIR}/conf.d/99-disable-upload-progress.ini"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm", "-F"]
