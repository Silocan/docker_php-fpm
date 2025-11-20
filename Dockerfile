FROM curlimages/curl:7.83.1

FROM php:7.4-fpm
LABEL maintainer="nicolas@unid-consulting.fr"


RUN set -ex; \
    apt-get -yqq update; \
    apt-get -yqq install \
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
    ; \
    rm -rf /var/lib/apt/lists/*;

# Mise en place de la partie python, libs, ... \
RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    python2 \
    python2-dev \
    wget \
    ca-certificates; \
    \
    # Installation d'OpenJDK 9 depuis les archives Adoptium \
    wget https://github.com/adoptium/temurin9-binaries/releases/download/jdk-9%2B181/OpenJDK9U-jdk_x64_linux_hotspot_9_181.tar.gz -O /tmp/openjdk9.tar.gz && \
    mkdir -p /usr/lib/jvm && \
    tar -xzf /tmp/openjdk9.tar.gz -C /usr/lib/jvm && \
    mv /usr/lib/jvm/jdk-9+181 /usr/lib/jvm/java-9-openjdk-amd64 && \
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-9-openjdk-amd64/bin/java 1 && \
    update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-9-openjdk-amd64/bin/javac 1 && \
    update-alternatives --set java /usr/lib/jvm/java-9-openjdk-amd64/bin/java && \
    rm /tmp/openjdk9.tar.gz; \
    \
    wget https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar; \
    mv pdftk-all.jar /usr/local/bin/pdftk.jar; \
    rm -rf /var/lib/apt/lists/*;

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

RUN install-php-extensions bcmath calendar curl gd imagick imap intl ldap mongodb-1.20.1 mysqli opcache pdo pdo_mysql redis soap sockets xdebug xml zip;
#RUN install-php-extensions grpc protobuf opentelemetry;

COPY docker/msmtp/msmtprc /etc/msmtprc
COPY docker/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY --from=0 /usr/bin/curl /usr/bin/curl
COPY --from=0 /usr/include/curl /usr/include/curl
COPY --from=0 /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4.8.0
RUN ln -sf /usr/lib/libcurl.so.4.8.0 /usr/lib/libcurl.so.4; \
    ln -sf /usr/lib/libcurl.so.4 /usr/lib/libcurl.so;


WORKDIR /var/www

ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD ["php-fpm", "-F"]