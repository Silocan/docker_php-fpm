FROM php:8.2.35-fpm

RUN apt update; \
    apt install \
    git \
    zip \
    unzip \
    vim \
    ssmtp \
    curl \
    openssh-client \
    bash \
    qpdf \
    ; \
    rm -rf /var/lib/apt/lists/*;

# LibreOffice. Debian Trixie n'a plus openjdk-11 : openjdk-21-jre-headless.
# Polices : ttf-dejavu -> fonts-dejavu, font-noto -> fonts-noto, font-noto-cjk -> fonts-noto-cjk
RUN apt update; \
    apt install -y --no-install-recommends \
    libreoffice \
    openjdk-21-jre-headless \
    fonts-dejavu \
    fonts-noto \
    fonts-noto-cjk \
    ; \
    rm -rf /var/lib/apt/lists/*;

RUN curl -sSLf \
    -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions


COPY --link docker/msmtp/msmtprc /etc/msmtprc
COPY --link docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www

# Composer 
RUN set -ex; \     
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \     
    chmod +x /usr/local/bin/composer

RUN install-php-extensions bcmath blackfire calendar curl gd intl ldap mongodb-1.15.1 mysqli opcache pdo pdo_mysql pdo_sqlsrv redis soap xdebug xml zip;

COPY --link docker/www.conf /usr/local/etc/php-fpm.d/www.conf

# CVE-2026-109618 / CVE-2026-109619 : lu au démarrage via conf.d, avant le parsing des requêtes
RUN printf 'session.upload_progress.enabled = Off\n' > "${PHP_INI_DIR}/conf.d/99-disable-upload-progress.ini"

ENTRYPOINT ["bash", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]