# syntax=docker/dockerfile:1

FROM php:7.4-fpm

ARG TARGETARCH

ENV LOCALTIME=Europe/Paris \
    LANG=fr_FR.UTF-8 \
    LANGUAGE=fr_FR.UTF-8 \
    VAULT_VERSION=1.19.5 \
    SHELL=/bin/bash

# Bullseye est archivé : les paquets security ne sont plus sur deb.debian.org
RUN set -eux; \
    sed -i \
        -e 's|http://deb.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
        -e 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
        -e 's|http://deb.debian.org/debian |http://archive.debian.org/debian |g' \
        /etc/apt/sources.list \
    && sed -i '/bullseye-updates/d' /etc/apt/sources.list \
    && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99no-check-valid-until

# Runtime + outils CI/CD. curl Debian est déjà compilé avec libssh2 (SFTP).
# LibreOffice tire python3 ; python2 + python-is-python2 gardent `python` sur 2.7.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        libssh2-1 \
        msmtp \
        openssh-client \
        openssl \
        rsync \
        tzdata \
        unzip \
        wget \
        zip \
        supervisor \
        openjdk-11-jre \
        libreoffice \
        python2 \
        python2-dev \
        python-is-python2 \
    && ln -sf python2 /usr/bin/python \
    && python -c 'import sys; assert sys.version_info[0] == 2' \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor /var/run /etc/supervisor/conf.d

COPY --from=composer:2.2 /usr/bin/composer /usr/local/bin/composer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Extensions PHP (build deps gérées puis retirées par install-php-extensions)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
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
COPY pdftk-all.jar /usr/local/bin/pdftk.jar
RUN chmod 755 /usr/local/bin/pdftk /usr/local/bin/pdftk.jar

COPY docker/supervisord.conf /etc/supervisor/supervisord.conf

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www

EXPOSE 9000

# CVE-2026-109618 / CVE-2026-109619 : lu au démarrage via conf.d, avant le parsing des requêtes
RUN printf 'session.upload_progress.enabled = Off\n' > "${PHP_INI_DIR}/conf.d/99-disable-upload-progress.ini"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
