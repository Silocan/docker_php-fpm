FROM php:7.2-fpm

RUN apt update && apt search openjdk

RUN set -ex; \
    \
    apt update; \
    apt install -y \
    libpng-dev \
    libxml2-dev \
    msmtp \
    git \
    zip \
    unzip \
    libxml2-dev \
    openssh-client \
    python2 \
    wget \
    ; \
    rm -rf /var/lib/apt/lists/*;

# Java
RUN mkdir -p /usr/share/man/man1 && apt-get update && \
    apt-get install -y openjdk-11-jdk && \
    apt clean;

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