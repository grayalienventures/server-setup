#!/bin/bash

echo -e "\n\n👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾
👽       GRAY ALIEN VENTURES STANDARD SERVER SETUP        👽
👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾\n\n"


os_version=$(grep -oP 'VERSION_ID="\K[\d.]+' /etc/os-release) 
current_dir=$(pwd) 
current_user=$(whoami)
includes_dir=$current_dir/"includes"


# Increase system memory
# https://www.digitalocean.com/community/questions/npm-gets-killed-no-matter-what
# https://stackoverflow.com/questions/38127667/npm-install-ends-with-killed
echo -e "👽  Increasing system memory\n\n"
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
# sudo swapon --show
sudo cp /etc/fstab /etc/fstab.bak  > /dev/null
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo sysctl vm.swappiness=10 > /dev/null
echo 'vm.swappiness = 10' | sudo tee -a /etc/sysctl.conf
sudo sysctl vm.vfs_cache_pressure=50 > /dev/null
echo 'vm.vfs_cache_pressure = 50' | sudo tee -a /etc/sysctl.conf


# Configure git
echo -e "\n\n👽  Configuring git\n\n"
echo -e "Input git user name:"
read git_user_name
echo -e "Input git user email:"
read git_user_email
git config --global user.name "$git_user_name"
git config --global user.email "$git_user_email"


# Upgrade system
echo -e "\n\n👽  Upgrading system\n\n"
sudo apt-get -y update > /dev/null
sudo apt-get -y upgrade > /dev/null


# Install Apache
echo -e "\n\n👽  Installing Apache\n\n"
sudo apt-get install -y apache2 > /dev/null


# Install PHP
echo -e "\n\n👽  Installing PHP\n\n"
sudo apt-get install -y php libapache2-mod-php php-xmlwriter php-dom php-mysql > /dev/null
sudo apt-get install -y php-fpm php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-mysql php-cli php-ldap php-zip php-curl > /dev/null


# Configure NS records
echo -e "\n\n👽  Configuring NS records\n\n"
IP=`hostname -I | awk '{print $1}'`
echo -e "Input domain name (domain.com):"
read domain
echo -e "Log into the domain registrar and go to the 'Advanced DNS' (or similar) section.  We will be creating two A-records.\n
1) host: @\tvalue: $IP
2) host: www\tvalue: $IP\n"
read -p "Press ENTER when you have saved these records to continue..."


# Install WordPress
echo -e "\n\n👽  Installing WordPress\n\n"
echo -e "Input database user name:"
read dbuser
echo -e "Input database name:"
read dbname
while true; do
	echo -e "\nInput database password (hidden input):"
	read -s dbpassword
	echo -e "\nInput database password again (hidden input):"
	read -s dbpassword2
	if [[ ! -z "$dbpassword" && "$dbpassword" = "$dbpassword2" ]];
	then
		break
	else
		echo "Please try again"
	fi
done
echo -e "Input site title:"
read sitetitle
echo -e "Input WordPress admin email:"
read admin_email
while true; do
	echo -e "\nInput WordPress admin password (hidden input):"
	read -s admin_password
	echo -e "\nEnter WordPress admin password again (hidden input):"
	read -s admin_password2
	if [[ ! -z "$admin_password" && "$admin_password" = "$admin_password2" ]];
	then
		break
	else
		echo "Please try again"
	fi
done


# Install and configure MySQL
echo -e "\n\n👽  Installing MySQL\n\n"
sudo apt-get install -y mysql-server mysql-client > /dev/null
sudo mysql -u root -e "CREATE DATABASE IF NOT EXISTS $dbname; CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpassword';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
sudo mysql -u root -e "DROP USER 'root'@'localhost'; CREATE USER 'root'@'%' IDENTIFIED BY '$dbpassword'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"


# Configure WordPress
echo -e "\n\n👽  Configuring WordPress\n\n"
slug=`echo "$domain" | sed 's/.com//g;s/.net//g;s/.io//g'`
wpdir=/var/www/html/admin
wp_config_file=$wpdir/wp-config.php
wp_config_temp_file=$wpdir/wp-config-temp.php
wp_home="https:\/\/www.$domain\/admin"
wp_siteurl="https:\/\/www.$domain\/admin"
path_current_site="\/admin"
admin_cookie_path="\/"
wget -c http://wordpress.org/latest.tar.gz > /dev/null
tar -xzvf latest.tar.gz > /dev/null
sudo mkdir $wpdir
sudo mv ./wordpress/* $wpdir > /dev/null
rmdir wordpress
sudo chown -R www-data:www-data $wpdir
sudo chmod -R 755 $wpdir
sudo chmod g+w $wpdir/wp-content
sudo chmod -R g+w $wpdir/wp-content/themes
sudo chmod -R g+w $wpdir/wp-content/plugins
sudo rm -rf $wpdir/wp-config-sample.php
sudo cp $includes_dir/wp-config-sample.php $wp_config_file
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
printf '%s\n' "g/secret-key-here/d" a "$SALT" . w | ed -s $wp_config_file
sudo sed -i -e "s/database_name_here/"$dbname"/;s/username_here/"$dbuser"/" $wp_config_file
sudo sed -i "s/password_here/$dbpassword/" $wp_config_file
sudo sed -i "s/wp_home_here/"$wp_home"/;s/wp_siteurl_here/"$wp_siteurl"/" $wp_config_file
sudo sed -i -e "s/domain_current_site_here/"$domain"/;s/path_current_site_here/"$path_current_site"/" $wp_config_file
sudo sed -i -e "s/admin_cookie_path_here/"$admin_cookie_path"/" $wp_config_file
sudo cp $wp_config_file $wp_config_temp_file
sudo sudo cp $includes_dir/.htaccess $wpdir
sudo systemctl restart apache2
echo -e "In a browser, go to $IP/admin and fill out the requested information."
read "Press ENTER when done to continue..."
cd $wpdir
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  > /dev/null
chmod +x wp-cli.phar  > /dev/null
sudo mv wp-cli.phar /usr/local/bin/wp  > /dev/null
sudo -u www-data wp core install --url="http://$domain" --title="$sitetitle" --admin_user="$admin_email" --admin_password="$admin_password" --admin_email="$admin_email"
sudo -u www-data wp rewrite structure '/%postname%/'
sudo -u www-data wp rewrite flush
cd $current_dir


# Install Gray Alien Ventures Core WordPress Plugin
echo -e "\n\n👽  Installing Gray Alien Ventures Core WordPress Plugin\n\n"
plugin_name="wp-core-plugin-setup"
plugin_dir="$current_dir/$plugin_name"
plugin_file_zip="$plugin_dir/$plugin_name.zip"
plugin_file_zip_target="$wpdir/wp-core-plugin.zip"
git clone https://github.com/grayalienventures/wp-core-plugin-setup.git
cd $plugin_dir
git archive --format zip --output "$plugin_name.zip" main
sudo mv $plugin_file_zip $plugin_file_zip_target
sudo rm -rf $plugin_dir
cd $wpdir
sudo -u www-data wp plugin install wp-core-plugin.zip --activate
sudo rm -rf $plugin_file_zip_target
cd $current_dir


# Install and configure NGINX
echo -e "\n\n👽  Installing NGINX\n\n"
sudo apt-get install -y nginx > /dev/null
sudo cp $includes_dir/example.conf ./$domain.conf
sudo sed -i "s/your_domain_here/$domain/" ./$domain.conf
sudo sed -i "s/www.your_domain_here/www.$domain/" ./$domain.conf
sudo mv ./$domain.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/
DEFAULT_FILE_NGINX=/etc/nginx/sites-available/default.conf
if [ -f "$DEFAULT_FILE_NGINX" ]; then
   sudo mv /etc/nginx/sites-available/default.conf /etc/nginx/sites-available/default.conf.disabled
fi


# Install NodeJS and NPM
echo -e "\n\n👽  Installing NodeJS and NPM\n\n"
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - > /dev/null
sudo apt-get install -y nodejs > /dev/null
sudo apt-get install -y npm > /dev/null
sudo npm i -g nodemon > /dev/null
sudo npm i -g concurrently > /dev/null
sudo npm i -g npx > /dev/null
cd $current_dir


# Install React and scaffold React app
echo -e "\n\n👽  Installing React and scaffolding React app template\n\n"
cd ..
dir=$(pwd)
dir_node=$dir/"$slug"_node
dir_prototype_node=$dir/prototype-node
sudo -u $USER git clone https://github.com/grayalienventures/prototype-node.git
sudo -u $USER mv $dir_prototype_node $dir_node
sudo rm -rf $dir_prototype_node
sudo -u $USER cp $includes_dir/.env $dir_node/.env
sudo -u $USER sed -i -e "s/yourdomainhere/$domain/;s/yourtitlehere/$sitetitle/" $dir_node/.env
sudo -u $USER cp $includes_dir/webpack.config.js $dir_node/webpack.config.js
sudo -u $USER cp $includes_dir/localConfig.js $dir_node/src/localConfig.js
sudo -u $USER sed -i -e "s/yourslughere/$slug/" $dir_node/src/localConfig.js
cd $dir_node
sudo -u $USER npm i
sudo -u $USER npm rebuild
sudo -u $USER npm i
sudo -u $USER npm run start-build-prod </dev/null &>/dev/null &
cd $current_dir


# Configure NGINX reverse proxy
echo -e "\n\n👽  Configuring NGINX reverse proxy\n\n"
sudo mkdir /etc/nginx/ssl
sudo chown -R root:root /etc/nginx/ssl
sudo chmod -R 600 /etc/nginx/ssl
sudo a2enmod ssl
sudo a2enmod rewrite
sudo systemctl stop apache2
sudo systemctl stop nginx
sudo mkdir /etc/systemd/system/nginx.service.d
sudo printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
sudo cp $includes_dir/ports.conf /etc/apache2/ports.conf
echo -e "\n<IfModule mod_rewrite>\n\tRewriteEngine On\n</IfModule>" | sudo tee -a /etc/apache2/apache2.conf > /dev/null
sudo cp $includes_dir/000-default.conf $includes_dir/temp-000-default.conf
sudo sed -i "s/your_domain_here/$domain/g" $includes_dir/temp-000-default.conf > /dev/null
sudo mv $includes_dir/temp-000-default.conf /etc/apache2/sites-available/000-default.conf
DEFAULT_FILE_NGINX=/etc/nginx/sites-available/default.conf
if [ -f "$DEFAULT_FILE_NGINX" ]; then
  sudo rm /etc/nginx/sites-available/default
  sudo rm /etc/nginx/sites-enabled/default
fi


# Install Certbot
echo -e "\n\n👽  Installing Certbot\n\n"
cd $current_dir
echo | sudo openssl genrsa  -out $domain-key.pem 2048  2>/dev/null
echo | sudo openssl req -new -key $domain-key.pem -out $domain-csr.pem \
 -subj "/C=US/ST=WA/L=Seattle/CN=$domain/emailAddress=someEmail@$domain"  2>/dev/null 
echo | sudo openssl x509 -req -in $domain-csr.pem -signkey $domain-key.pem -out $domain-cert.pem 2>/dev/null
sudo mv $domain-cert.pem /etc/nginx/ssl/$domain.chained.crt
sudo mv $domain-key.pem /etc/nginx/ssl/$domain.key
sudo rm -rf $domain-csr.pem
sudo systemctl start nginx
sudo systemctl start apache2
sudo systemctl daemon-reload
sudo service apache2 restart
sudo service nginx restart
sudo snap install --classic certbot> /dev/null
certbot --nginx -d "$domain" -d "www.$domain" -m admin@$domain --agree-tos -n
certbot renew --dry-run
cd $current_dir
cronjob="0 12 * * * /usr/bin/certbot renew --quiet"
crontab_new_file=$current_dir/certbot_renew
crontab -l > $crontab_new_file
echo "$cronjob" >> $crontab_new_file
crontab $crontab_new_file