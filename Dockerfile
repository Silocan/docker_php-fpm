FROM curlimages/curl:7.83.1

FROM php:7.4-fpm-alpine

RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.15/community"  >> /etc/apk/repositories
RUN set -ex; \
    \
    apk update; \
    apk add \
    wget \
    bash \
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
    libzip-dev \
    vim \
    libxml2-dev \
    ssmtp \
    openssl-dev \
    libssh2 \
    libssh2-dev \
    libssh2-dev \
    pkgconfig \
    openssh-client \
    imagemagick-dev \
    imap-dev; \
    rm -rf /var/lib/apt/lists/*;

# Mise en place de la partie python, libs, ... \
RUN set -ex; \
    \
    apk update; \
    apk add \
    openjdk9 python2 \
    gcompat \
    libc6-compat \
    musl \
    libgcc \
    libstdc++ \
    musl-dev \
    gcc \
    make; \
    wget https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar; \
    mv pdftk-all.jar /usr/local/bin/pdftk.jar;

# Créer une bibliothèque wrapper pour les symboles glibc manquants
RUN echo '#include <math.h>' > /tmp/glibc_compat_wrapper.c && \
    echo '#include <string.h>' >> /tmp/glibc_compat_wrapper.c && \
    echo '#include <stdlib.h>' >> /tmp/glibc_compat_wrapper.c && \
    echo '#include <stdio.h>' >> /tmp/glibc_compat_wrapper.c && \
    echo 'int __isinf(double x) { return isinf(x); }' >> /tmp/glibc_compat_wrapper.c && \
    echo 'int __isinff(float x) { return isinf(x); }' >> /tmp/glibc_compat_wrapper.c && \
    echo 'int __isinfl(long double x) { return isinf(x); }' >> /tmp/glibc_compat_wrapper.c && \
    echo 'char* __strdup(const char* s) { return strdup(s); }' >> /tmp/glibc_compat_wrapper.c && \
    echo 'int __isnan(double x) { return isnan(x); }' >> /tmp/glibc_compat_wrapper.c && \
    echo 'int __isnanf(float x) { return isnan(x); }' >> /tmp/glibc_compat_wrapper.c && \
    echo 'int __isnanl(long double x) { return isnan(x); }' >> /tmp/glibc_compat_wrapper.c && \
    gcc -shared -fPIC -o /usr/lib/libglibc_compat_wrapper.so /tmp/glibc_compat_wrapper.c -lm && \
    rm /tmp/glibc_compat_wrapper.c && \
    apk del gcc make;

# install pdftk
COPY --link  ./pdftk /usr/local/bin/pdftk 
RUN chmod 775 /usr/local/bin/pdftk*

# fix work iconv library with alphine
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.12/community/ gnu-libiconv=1.15-r2

# Créer un wrapper Python pour garantir LD_PRELOAD avec gcompat et notre wrapper
RUN echo '#!/bin/sh' > /usr/local/bin/python2-wrapper && \
    echo 'export LD_PRELOAD="${LD_PRELOAD:-/usr/lib/preloadable_libiconv.so}:/usr/lib/libgcompat.so.0:/usr/lib/libglibc_compat_wrapper.so"' >> /usr/local/bin/python2-wrapper && \
    echo 'exec /usr/bin/python2 "$@"' >> /usr/local/bin/python2-wrapper && \
    chmod +x /usr/local/bin/python2-wrapper && \
    ln -sf /usr/local/bin/python2-wrapper /usr/local/bin/python-wrapper

ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so:/usr/lib/libgcompat.so.0:/usr/lib/libglibc_compat_wrapper.so

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