FROM php:7.2-fpm

RUN set -ex; \
    \
    apt update; \
    apt install \
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
    libxml2-dev \
    openssl-dev \
    pkgconfig \
    gnu-libiconv \
    imap-dev \
    openssh-client \
    openjdk9 \
    python2 \
    ; \
    rm -rf /var/lib/apt/lists/*;

# PdfTk
RUN wget https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar; \
    mv pdftk-all.jar /usr/local/bin/pdftk.jar

COPY --link  /docker/pdftk /usr/local/bin/pdftk 
RUN chmod 775 /usr/local/bin/pdftk*


COPY --link docker/msmtp/msmtprc /etc/msmtprc
COPY --link docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Composer v1.x
RUN set -ex; \
    curl -sS https://getcomposer.org/installer | php -- --version=1.10.26 --install-dir=/usr/local/bin --filename=composer; \     
    chmod +x /usr/local/bin/composer
# Composer v2.x
RUN set -ex; \  
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer2; \     
    chmod +x /usr/local/bin/composer2

# Client blackfire
RUN mkdir -p /tmp/blackfire \
    && architecture=$(uname -m) \
    && curl -A "Docker" -L https://blackfire.io/api/v1/releases/cli/linux/$architecture | tar zxp -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire /usr/bin/blackfire \
    && rm -Rf /tmp/blackfire

RUN curl -sSLf \
    -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions
RUN install-php-extensions blackfire xdebug intl opcache pdo gd zip bcmath xml mysqli curl calendar pdo_mysql redis mongodb ldap soap imagick apcu imap sockets;


WORKDIR /var/www

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]