#!/bin/sh
set -e

log() {
    echo "[$0] [$(date +%Y-%m-%dT%H:%M:%S)] $*"
}

# version_greater A B returns whether A > B
version_greater() {
	[ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
	[ -z "$(ls -A "$1/")" ]
}

run_as() {
	if [ "$(id -u)" = 0 ]; then
		su - www-data -s /bin/sh -c "$1"
	else
		sh -c "$1"
	fi
}

log "Updating Thirtybees users and group..."
usermod -u "$WWW_USER_ID" www-data
groupmod -g "$WWW_GROUP_ID" www-data

log "Env:"
set
log "Copy Thirtybees source..."
cp -r /usr/src/thirtybees/* /var/www/html/
ls -la


if [ ! -d /var/www/html/conf/ ]; then
	log "Initializing Thirtybees HTML configuration directory..."
	mkdir -p /var/www/html/conf/
fi

log "Updating Thirtybees folder ownership..."
chown -R www-data:www-data /var/www

php ./install/index_cli.php --step=${THRITYBEES_STEP} \
	--newsletter=${THRITYBEES_NEWSLETTER} \
	--language=${THRITYBEES_LANGUAGE} \
	--all_language=${THRITYBEES_ALL_LANGUAGE} \
	--timezone=${THRITYBEES_TIMEZONE} \
	--country=${THRITYBEES_COUNTRY} \
	--domain=${THRITYBEES_DOMAIN} \
	--db_name=${THRITYBEES_DB_NAME} \
	--db_server=${THRITYBEES_DB_HOST}:${THRITYBEES_DB_PORT} \
	--db_user=${THRITYBEES_DB_USER} \
	--db_password=${THRITYBEES_DB_PASSWORD} \
	--db_clear=${THRITYBEES_DB_CLEAR} \
	--db_create=${THRITYBEES_DB_CREATE} \
	--prefix=${THRITYBEES_DB_PREFIX} \
	--engine=${THRITYBEES_DB_ENGINE} \
	--name=${THRITYBEES_NAME} \
	--activity=${THRITYBEES_ACTIVITY} \
	--email=${THRITYBEES_EMAIL}  \
	--send_email=${THRITYBEES_SEND__EMAIL}  \
	--firstname=${THRITYBEES_FIRSTNAME} \
	--lastname=${THRITYBEES_LASTNAME} \
	--password=${THRITYBEES_PASSWORD} \
	--license=${THRITYBEES_LICENSE}

mv ./install ../

if [ ! -d /var/www/htdocs ]; then
	log "Adding a symlink to /var/www/htdocs..."
	ln -s /var/www/html /var/www/htdocs
fi


if [ -f /var/www/documents/install.lock ]; then
	log "Updating Thirtybees installed version..."
	echo "$image_version" > /var/www/documents/.docker-container-version
fi

log "Serving Thirtybees..."
exec "$@"
