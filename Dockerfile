FROM php:8.2-fpm

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

# Probe blackfire
#RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
#    && architecture=$(uname -m) \
#    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/$architecture/$version \
#    && mkdir -p /tmp/blackfire \
#    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
#    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
#    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8307\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
#    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

# Client blackfire
RUN mkdir -p /tmp/blackfire \
    && architecture=$(uname -m) \
    && curl -A "Docker" -L https://blackfire.io/api/v1/releases/cli/linux/$architecture | tar zxp -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire /usr/bin/blackfire \
    && rm -Rf /tmp/blackfire

RUN install-php-extensions bcmath blackfire calendar curl gd intl ldap mongodb-1.15.1 mysqli opcache pdo pdo_mysql redis soap xdebug xml zip;

COPY --link docker/www.conf /usr/local/etc/php-fpm.d/www.conf

ENTRYPOINT ["bash", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]