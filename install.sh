#!/bin/bash

echo -e "\n\n👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾
👽       GRAY ALIEN VENTURES STANDARD SERVER SETUP        👽
👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾👾\n\n"


os_version=$(grep -oP 'VERSION_ID="\K[\d.]+' /etc/os-release) 
current_dir=$(pwd) 
current_user=$(who -m | awk '{print $1;}')
includes_dir=$current_dir/"includes"
log=$current_dir/"log.log"

# Configure git
echo -e "\n\n👽  Configuring git\n\n"
echo -e "Input git user name:"
read git_user_name
echo -e "Input git user email:"
read git_user_email
git config --global user.name "$git_user_name"
git config --global user.email "$git_user_email"


# Configure NS records
echo -e "\n\n👽  Configuring NS records\n\n"
IP=`hostname -I | awk '{print $1}'`
echo -e "Input domain name (domain.com):"
read domain
echo -e "Log into the domain registrar and go to the 'Advanced DNS' (or similar) section.  We will be creating two A-records.\n
1) host: @\tvalue: $IP
2) host: www\tvalue: $IP\n"
read -p "Press ENTER when you have saved these records to continue..."


# Configure database
echo -e "\n\n👽  Configuring database\n\n"
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


# Configure WordPress
echo -e "\n\n👽  Configuring WordPress\n\n"
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


# Increase system memory
# https://www.digitalocean.com/community/questions/npm-gets-killed-no-matter-what
# https://stackoverflow.com/questions/38127667/npm-install-ends-with-killed
echo -e "👽  Increasing system memory\n\n"
sudo echo "\$nrconf{restart} = \"l\"" | sudo tee -a /etc/needrestart/needrestart.conf >> $log 2>&1
sudo fallocate -l 4G /swapfile >> $log 2>&1
sudo chmod 600 /swapfile >> $log 2>&1
sudo mkswap /swapfile >> $log 2>&1
sudo swapon /swapfile >> $log 2>&1
# sudo swapon --show
sudo cp /etc/fstab /etc/fstab.bak  >> $log 2>&1
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >> $log 2>&1
sudo sysctl vm.swappiness=10 >> $log 2>&1
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf >> $log 2>&1
sudo sysctl vm.vfs_cache_pressure=50 >> $log 2>&1 
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf >> $log 2>&1


# Upgrade system
echo -e "\n\n👽  Upgrading system\n\n"
sudo apt-get -y update >> $log 2>&1
sudo apt-get -y upgrade >> $log 2>&1


# Install Apache
echo -e "\n\n👽  Installing Apache\n\n"
sudo apt-get install -y apache2 >> $log 2>&1


# Install PHP
echo -e "\n\n👽  Installing PHP\n\n"
sudo apt-get install -y php libapache2-mod-php php-xmlwriter php-dom php-mysql >> $log 2>&1
sudo apt-get install -y php-fpm php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-mysql php-cli php-ldap php-zip php-curl >> $log 2>&1



# Install and configure MySQL
echo -e "\n\n👽  Installing MySQL\n\n"
sudo apt-get install -y mysql-server mysql-client >> $log 2>&1
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
wget -c http://wordpress.org/latest.tar.gz >> $log 2>&1
tar -xzvf latest.tar.gz >> $log 2>&1
sudo mkdir $wpdir
sudo mv ./wordpress/* $wpdir >> $log 2>&1
rmdir wordpress
sudo chown -R www-data:www-data $wpdir
sudo chmod -R 755 $wpdir
sudo chmod g+w $wpdir/wp-content
sudo chmod -R g+w $wpdir/wp-content/themes
sudo chmod -R g+w $wpdir/wp-content/plugins
sudo rm -rf $wpdir/wp-config-sample.php
sudo cp $includes_dir/wp-config-sample.php $wp_config_file
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
printf '%s\n' "g/secret-key-here/d" a "$SALT" . w | ed -s $wp_config_file >> $log 2>&1
sudo sed -i -e "s/database_name_here/"$dbname"/;s/username_here/"$dbuser"/" $wp_config_file
sudo sed -i "s/password_here/$dbpassword/" $wp_config_file
sudo sed -i "s/wp_home_here/"$wp_home"/;s/wp_siteurl_here/"$wp_siteurl"/" $wp_config_file
sudo sed -i -e "s/domain_current_site_here/"$domain"/;s/path_current_site_here/"$path_current_site"/" $wp_config_file
sudo sed -i -e "s/admin_cookie_path_here/"$admin_cookie_path"/" $wp_config_file
sudo cp $wp_config_file $wp_config_temp_file
sudo sudo cp $includes_dir/.htaccess $wpdir
sudo systemctl restart apache2 >> $log 2>&1
echo -e "In a browser, go to $IP/admin and fill out the requested information."
read "Press ENTER when done to continue..."
cd $wpdir
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  >> $log 2>&1
chmod +x wp-cli.phar  >> $log 2>&1
sudo mv wp-cli.phar /usr/local/bin/wp  >> $log 2>&1
sudo -u www-data wp core install --url="http://$domain" --title="$sitetitle" --admin_user="$admin_email" --admin_password="$admin_password" --admin_email="$admin_email" >> $log 2>&1
sudo -u www-data wp rewrite structure '/%postname%/' >> $log 2>&1
sudo -u www-data wp rewrite flush >> $log 2>&1
cd $current_dir


# Install Gray Alien Ventures Core WordPress Plugin
echo -e "\n\n👽  Installing Gray Alien Ventures Core WordPress Plugin\n\n"
plugin_name="wp-core-plugin-setup"
plugin_dir="$current_dir/$plugin_name"
plugin_file_zip="$plugin_dir/$plugin_name.zip"
plugin_file_zip_target="$wpdir/wp-core-plugin.zip"
git clone https://github.com/grayalienventures/wp-core-plugin-setup.git >> $log 2>&1
cd $plugin_dir
git archive --format zip --output "$plugin_name.zip" main >> $log 2>&1
sudo mv $plugin_file_zip $plugin_file_zip_target >> $log 2>&1
sudo rm -rf $plugin_dir >> $log 2>&1
cd $wpdir
sudo -u www-data wp plugin install wp-core-plugin.zip --activate >> $log 2>&1
sudo rm -rf $plugin_file_zip_target
cd $current_dir


# Install and configure NGINX
echo -e "\n\n👽  Installing NGINX\n\n"
sudo apt-get install -y nginx >> $log 2>&1
sudo cp $includes_dir/example.conf ./$domain.conf >> $log 2>&1
sudo sed -i "s/your_domain_here/$domain/" ./$domain.conf >> $log 2>&1
sudo sed -i "s/www.your_domain_here/www.$domain/" ./$domain.conf >> $log 2>&1
sudo mv ./$domain.conf /etc/nginx/sites-available/ >> $log 2>&1
sudo ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/
DEFAULT_FILE_NGINX=/etc/nginx/sites-available/default.conf
if [ -f "$DEFAULT_FILE_NGINX" ]; then
   sudo mv /etc/nginx/sites-available/default.conf /etc/nginx/sites-available/default.conf.disabled
fi


# Install NodeJS and NPM
echo -e "\n\n👽  Installing NodeJS and NPM\n\n"
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - >> $log 2>&1
sudo apt-get install -y nodejs >> $log 2>&1
sudo apt-get install -y npm >> $log 2>&1
sudo npm i -g nodemon >> $log 2>&1
sudo npm i -g concurrently >> $log 2>&1
sudo npm i -g npx >> $log 2>&1
cd $current_dir


# Install React and scaffold React app
echo -e "\n\n👽  Installing React and scaffolding React app template\n\n"
cd ..
dir=$(pwd)
dir_node=$dir/"$slug"_node
dir_prototype_node=$dir/prototype-node
sudo -u $current_user git clone https://github.com/grayalienventures/prototype-node.git >> $log 2>&1
sudo -u $current_user mv $dir_prototype_node $dir_node
sudo rm -rf $dir_prototype_node
sudo -u $current_user cp $includes_dir/.env $dir_node/.env
sudo -u $current_user sed -i -e "s/yourdomainhere/$domain/;s/yourtitlehere/$sitetitle/" $dir_node/.env
sudo -u $current_user cp $includes_dir/webpack.config.js $dir_node/webpack.config.js
sudo -u $current_user cp $includes_dir/localConfig.js $dir_node/src/localConfig.js
sudo -u $current_user sed -i -e "s/yourslughere/$slug/" $dir_node/src/localConfig.js
cd $dir_node
sudo -u $current_user npm i >> $log 2>&1
sudo -u $current_user npm rebuild >> $log 2>&1
sudo -u $current_user npm i >> $log 2>&1
cd $current_dir


# Configure NGINX reverse proxy
echo -e "\n\n👽  Configuring NGINX reverse proxy\n\n"
sudo mkdir /etc/nginx/ssl >> $log 2>&1
sudo chown -R root:root /etc/nginx/ssl >> $log 2>&1
sudo chmod -R 600 /etc/nginx/ssl >> $log 2>&1
sudo a2enmod ssl >> $log 2>&1
sudo a2enmod rewrite >> $log 2>&1
sudo systemctl stop apache2 >> $log 2>&1
sudo systemctl stop nginx >> $log 2>&1
sudo mkdir /etc/systemd/system/nginx.service.d >> $log 2>&1
sudo printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
sudo cp $includes_dir/ports.conf /etc/apache2/ports.conf >> $log 2>&1
echo -e "\n<IfModule mod_rewrite>\n\tRewriteEngine On\n</IfModule>" | sudo tee -a /etc/apache2/apache2.conf >> $log 2>&1
sudo cp $includes_dir/000-default.conf $includes_dir/temp-000-default.conf >> $log 2>&1
sudo sed -i "s/your_domain_here/$domain/g" $includes_dir/temp-000-default.conf >> $log 2>&1
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
sudo systemctl start nginx >> $log 2>&1
sudo systemctl start apache2 >> $log 2>&1
sudo systemctl daemon-reload >> $log 2>&1
sudo service apache2 restart
sudo service nginx restart
sudo snap install --classic certbot >> $log 2>&1
certbot --nginx -d "$domain" -d "www.$domain" -m admin@$domain --agree-tos -n >> $log 2>&1
certbot renew --dry-run >> $log 2>&1
cd $current_dir
SLEEPTIME=$(awk 'BEGIN{srand(); print int(rand()*(3600+1))}'); 
echo "0 0,12 * * * root sleep $SLEEPTIME && certbot renew --post-hook \"service nginx reload\" -q" | sudo tee -a /etc/crontab >> $log 2>&1


# Build React app
echo -e "\n\n👽  building React app\n\n"
cd $dir_node
sudo -u $current_user nohup  npm run start-build-prod  >> $log 2>&1 &
