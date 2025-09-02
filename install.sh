#!/bin/bash
# =======================================
# Nebula Theme + Pterodactyl Installer
# Made: 09/02/2025
# Author: mominaluchifg-ship-it
# =======================================

set -e

# Vars
PANEL_DOMAIN=${PANEL_DOMAIN:-"panel.ASIDCLOUD.com"}
ADMIN_EMAIL=${ADMIN_EMAIL:-"mominaluchifg@gmail.com"}
ADMIN_USERNAME=${ADMIN_USERNAME:-"admin"}
ADMIN_FIRST=${ADMIN_FIRST:-"Admin"}
ADMIN_LAST=${ADMIN_LAST:-"User"}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-"asidowner"}
WINGS_IP=${WINGS_IP:-"0.0.0.0"}

echo "🚀 Starting Pterodactyl + Nebula Theme installation..."

# Update packages
apt update -y && apt upgrade -y

# Install dependencies
apt install -y curl unzip git software-properties-common lsb-release ca-certificates apt-transport-https gnupg

# Install MariaDB
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
apt install -y mariadb-server

# Create DB
mysql -u root <<MYSQL_SCRIPT
CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY 'StrongPassword123!';
CREATE DATABASE panel;
GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Install Panel
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache

# Install composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
composer install --no-dev --optimize-autoloader

# Env setup
cp .env.example .env
php artisan key:generate --force
php artisan p:environment:setup \
    --url="http://${PANEL_DOMAIN}" \
    --timezone="UTC" \
    --cache="redis" \
    --session="database" \
    --queue="redis" \
    --email="smtp" \
    --email-driver="smtp" \
    --email-host="mail.${PANEL_DOMAIN}" \
    --email-port="587" \
    --email-username="${ADMIN_EMAIL}" \
    --email-password="password" \
    --email-encryption="tls"

php artisan p:environment:database \
    --host="127.0.0.1" \
    --port="3306" \
    --database="panel" \
    --username="ptero" \
    --password="StrongPassword123!"

php artisan migrate --seed --force

php artisan p:user:make \
    --email="${ADMIN_EMAIL}" \
    --username="${ADMIN_USERNAME}" \
    --name-first="${ADMIN_FIRST}" \
    --name-last="${ADMIN_LAST}" \
    --password="${ADMIN_PASSWORD}" \
    --admin=1

# Install Nebula Theme
echo "🌌 Installing Nebula Theme..."
cd /var/www/pterodactyl
curl -s https://raw.githubusercontent.com/TheFonix/Pterodactyl-Themes/master/MasterThemes/Nebula/build.sh | bash

echo "✅ Installation Finished!"
echo "🌐 Panel: http://${PANEL_DOMAIN}"
echo "👤 Admin: ${ADMIN_USERNAME} / ${ADMIN_PASSWORD}"
