#!/bin/bash -ex

# -e: コマンドがエラーになったら直ちにスクリプトを終了する
# -x: 実行するコマンドをログに出力する

echo "--- Startup script started ---"

# パッケージリストを更新し、必要なソフトウェアをインストール
apt-get update
apt-get install -y apache2 php libapache2-mod-php php-mysql wget curl

# --- メタデータから接続情報を取得 ---
echo "--- Fetching metadata ---"
DB_HOST=$(curl -f http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_host -H "Metadata-Flavor: Google")
DB_NAME=$(curl -f http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_name -H "Metadata-Flavor: Google")
DB_USER=$(curl -f http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_user -H "Metadata-Flavor: Google")
DB_PASSWORD=$(curl -f http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_password -H "Metadata-Flavor: Google")
echo "--- Metadata fetched ---"

# --- WordPressのインストール ---
echo "--- Installing WordPress ---"
cd /var/www/html
rm -f index.html
wget https://ja.wordpress.org/latest-ja.tar.gz
tar -xzvf latest-ja.tar.gz
mv wordpress/* .
rmdir wordpress
rm latest-ja.tar.gz
echo "--- WordPress installed ---"


# --- wp-config.phpの生成 ---
echo "--- Creating wp-config.php ---"
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/$DB_NAME/g" wp-config.php
sed -i "s/username_here/$DB_USER/g" wp-config.php
sed -i "s/password_here/$DB_PASSWORD/g" wp-config.php
sed -i "s/localhost/$DB_HOST/g" wp-config.php

echo "--- Configuring salts ---"
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s wp-config.php
echo "--- wp-config.php created ---"

# --- パーミッションの設定とサービスの再起動 ---
echo "--- Setting permissions and restarting Apache ---"
chown -R www-data:www-data /var/www/html
systemctl restart apache2
echo "--- Startup script finished ---"