#!/bin/bash
set -euo pipefail

LOCALTIME="${LOCALTIME:-Europe/Paris}"

# PHP__FOO=bar → "FOO = bar" dans le fichier ini cible
set_conf() {
    local prefix=$1
    local file=$2
    local sep=${3:-=}
    local key value

    : >"$file"
    while IFS= read -r line; do
        [[ -n $line ]] || continue
        key=${line%%=*}
        value=${line#*=}
        key=${key#"$prefix"}
        printf '%s %s %s\n' "$key" "$sep" "$value" >>"$file"
    done < <(printenv | grep "^${prefix}" || true)
}

if [[ $(id -u) -eq 0 ]]; then
    ln -sfn "/usr/share/zoneinfo/${LOCALTIME}" /etc/localtime

    # Contournement droits volumes ; SKIP_PERMISSIONS=1 en CI si besoin
    if [[ ${SKIP_PERMISSIONS:-0} != 1 && -d /var/www ]]; then
        chmod -R a+rwX /var/www || true
    fi
fi

# Écriture (pas append) → pas de doublons au restart
printf 'date.timezone = "%s"\n' "${LOCALTIME}" >"${PHP_INI_DIR}/conf.d/00-timezone.ini"
set_conf "PHP__" "${PHP_INI_DIR}/conf.d/40-user.ini" "="

exec "$@"
