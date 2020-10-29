#!/bin/bash
set -e

if [ "$USER" = "root" ]; then

    # set localtime
    ln -sf /usr/share/zoneinfo/$LOCALTIME /etc/localtime
fi

#
# functions

function set_conf {
    echo ''>$2; IFSO=$IFS; IFS=$(echo -en "\n\b")
    for c in `printenv|grep $1`; do echo "`echo $c|cut -d "=" -f1|awk -F"$1" '{print $2}'` $3 `echo $c|cut -d "=" -f2`" >> $2; done;
    IFS=$IFSO
}

#
# PHP

echo "date.timezone = \"${LOCALTIME}\"" >> $PHP_INI_DIR/conf.d/00-default.ini
set_conf "PHP__" "$PHP_INI_DIR/conf.d/40-user.ini" "="

chmod 777 -Rf /var/www

echo "Check composer";
if [[ -f /var/www/composer.json && $COMPOSER_INSTALL -eq 1 ]]; then
    echo "Composer install";
    cd /var/www
    composer install --prefer-dist --no-progress --no-suggest --no-interaction && composer dump-autoload -o
fi


echo -e "GENERATE_API_KEY = ${GENERATE_API_KEY}\n"
echo -e "jwt_passhrase = ${jwt_passhrase}\n"
if [[ $GENERATE_API_KEY -eq 1 && -z "$jwt_passphrase" ]]; then
    echo "Generation de la clef d'API"
    cd /var/www
    mkdir -p var/jwt
    echo "$jwt_passhrase" | openssl genpkey -out var/jwt/private.pem -pass stdin -aes256 -algorithm rsa -pkeyopt rsa_keygen_bits:4096
    echo "$jwt_passhrase" | openssl pkey -in var/jwt/private.pem -passin stdin -out var/jwt/public.pem -pubout
fi

if [[ -f /var/www/bin/console && -f /var/www/.env && $DOCTRINE_LOAD -eq 1 ]]; then
    echo "--- Doctrine initialisation";
    cd /var/www

    echo ".. Création de la base"
    php bin/console doctrine:database:create --if-not-exists --no-interaction
    echo ".. Mise à jour de la structure"
    php bin/console doctrine:migration:migrate  --allow-no-migration --no-interaction
    #echo ".. Chargement des fixtures"
    #php bin/console doctrine:fixtures:load --append
fi

exec "$@"
