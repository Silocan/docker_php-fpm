FROM curlimages/curl:7.83.1

FROM php:7.4-fpm
LABEL maintainer="nicolas@unid-consulting.fr"


RUN set -ex; \
    apt-get -yqq update; \
    apt-get -yqq install \
    bash \
    supervisor \
    libjpeg62-turbo-dev \
    libpng-dev \
    libfreetype6-dev \
    libxml2-dev \
    libicu-dev \
    msmtp \
    curl \
    git \
    zip \
    unzip \
    libzip-dev \
    openssl \
    vim \
    libxml2-dev \
    libcurl3-dev \
    libonig-dev \
    mailutils \
    wget \
    imagemagick \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /var/log/supervisor /var/run /etc/supervisor/conf.d;

# Mise en place de la partie python, libs, ... \
RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    python2 \
    python2-dev \
    wget \
    ca-certificates \
    openjdk-11-jre \
    libreoffice; \
    \
    rm -rf /var/lib/apt/lists/*;
# Copie de pdftk 
# https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar
COPY --link pdftk-all.jar /usr/local/bin/pdftk.jar

# install pdftk
COPY --link  ./pdftk /usr/local/bin/pdftk 
RUN chmod 775 /usr/local/bin/pdftk*


# Composer 
RUN set -ex; \     
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \     
    chmod +x /usr/local/bin/composer

RUN set -ex; \     
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer1 --version=1.10.26 ; \     
    chmod +x /usr/local/bin/composer1


RUN curl -sSLf \
    -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions

RUN install-php-extensions amqp bcmath calendar curl gd imagick imap intl ldap mongodb-1.20.1 mysqli opcache pdo pdo_mysql redis soap sockets xdebug xsl xml zip;
#RUN install-php-extensions grpc protobuf opentelemetry;

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
COPY docker/supervisord.conf /etc/supervisor/supervisord.conf
#COPY docker/supervisor/conf.d/*.conf /etc/supervisor/conf.d/
RUN chmod +x /entrypoint.sh

# Suppresion de la regle de securité pour Imagick et la conversion image en pdf
RUN sed -i '/policy domain="coder" rights="none" pattern="PDF"/d' /etc/ImageMagick-6/policy.xml

COPY --from=0 /usr/bin/curl /usr/bin/curl
COPY --from=0 /usr/include/curl /usr/include/curl
COPY --from=0 /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4.8.0
RUN ln -sf /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4; \
    ln -sf /usr/lib/libcurl.so.4 /usr/lib/libcurl.so;


WORKDIR /var/www

ENTRYPOINT ["bash", "/entrypoint.sh"]

# Par défaut, lancer supervisor qui gère php-fpm et les consumers
# Pour lancer uniquement php-fpm : docker run ... php-fpm -F
# Pour lancer uniquement un consumer : docker run ... php bin/console messenger:consume async_email
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]