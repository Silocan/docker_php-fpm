FROM php:8.4-fpm

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

RUN install-php-extensions bcmath calendar curl gd intl ldap mongodb-1.20.1 mysqli opcache pdo pdo_mysql pdo_pgsql pdo_sqlsrv redis soap xdebug xml zip;

COPY --link docker/www.conf /usr/local/etc/php-fpm.d/www.conf

ENTRYPOINT ["bash", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]