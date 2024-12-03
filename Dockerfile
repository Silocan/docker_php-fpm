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

RUN install-php-extensions xdebug intl opcache pdo gd zip bcmath xml mysqli curl calendar pdo_mysql redis mongodb-1.15.1 ldap soap;

COPY --link docker/www.conf /usr/local/etc/php-fpm.d/www.conf

ENTRYPOINT ["bash", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]