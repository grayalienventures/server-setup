#!/bin/bash
current_dir=$(pwd) 
echo "************************************************************
*****          INTP LLC STANDARD SERVER SETUP          *****
************************************************************"

# Input prompts
echo -e "\nEnter domain name (example.com)"
read domain
echo -e "\nEnter site title"
read sitetitle
echo -e "\nEnter database name"
read dbname
echo -e "\nEnter database user"
read dbuser
echo -e "\nEnter database password (hidden input)"
read -s dbpassword


slug=`echo "$domain" | sed 's/.com//g;s/.net//g;s/.io//g'`

# System memory increased
# https://www.digitalocean.com/community/questions/npm-gets-killed-no-matter-what
# https://stackoverflow.com/questions/38127667/npm-install-ends-with-killed
create_swapfile(){
	sudo fallocate -l 1G /swapfile
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile
	sudo swapon /swapfile
	sudo swapon --show
	sudo cp /etc/fstab /etc/fstab.bak
	echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
	sudo sysctl vm.swappiness=10
	echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
	sudo sysctl vm.vfs_cache_pressure=50
	echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf

}


# Upgrade system

upgrade_system(){
	echo -e "\nBegin system update..."
	sudo apt-get -y update > /dev/null
	echo "End system update"
	echo -e "\nBegin system upgrade..."
	sudo apt-get -y upgrade > /dev/null
	echo "End system upgrade"
}

# Install Apache
install_apache(){
	echo -e "\nBegin Apache installation..."
	sudo apt-get install -y apache2 > /dev/null
	echo "End Apache installation"
	
}

# Install PHP and PHP-FPM modules
install_php(){
	echo -e "\nBegin PHP installation..."
	sudo apt-get install -y php libapache2-mod-php php-xmlwriter php-dom php-mysql > /dev/null
	sudo apt-get install -y php-fpm php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-mysql php-cli php-ldap php-zip php-curl > /dev/null
	echo "End PHP installation"
}


# Install and configure MySQL
install_mysql(){
	echo -e "\nBegin MySQL installation and configuration..."
	sudo apt-get install -y mysql-server mysql-client > /dev/null
	sudo mysql -u root -e "CREATE DATABASE $dbname; CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpassword';"
	sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
	sudo mysql -u root -e "DROP USER 'root'@'localhost'; CREATE USER 'root'@'%' IDENTIFIED BY '$dbpassword'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
	echo "End MySQL installation and configuration"
}



# Configure NS records
config_ns_records(){
	echo -e "\nBegin NS records configuration..."
	IP=`hostname -I | awk '{print $1}'`
	echo -e "Log into the domain registrar and go to the 'Advanced DNS' (or similar) section.  We will be creating two A-records.\n
	1) host: @\tvalue: $IP
	2) host: www\tvalue: $IP\n"
	read -p "Press ENTER when you have saved these records to continue..."
	echo "End NS records configuration"
}


# Install WordPress
install_wp(){
	echo -e "\nBegin WordPress installation and configuration"
	# variables
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
	# remove first install wp-config
	sudo rm -rf $wpdir/wp-config-sample.php
	# copy our config 
	sudo cp ./wp-config-sample.php $wp_config_file
    SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
    printf '%s\n' "g/secret-key-here/d" a "$SALT" . w | ed -s $wp_config_file
    sudo sed -i -e "s/database_name_here/"$dbname"/;s/username_here/"$dbuser"/" $wp_config_file
    sudo sed -i "s/password_here/$dbpassword/" $wp_config_file
    sudo sed -i "s/wp_home_here/"$wp_home"/;s/wp_siteurl_here/"$wp_siteurl"/" $wp_config_file
    sudo sed -i -e "s/domain_current_site_here/"$domain"/;s/path_current_site_here/"$path_current_site"/" $wp_config_file
    sudo sed -i -e "s/admin_cookie_path_here/"$admin_cookie_path"/" $wp_config_file
	sudo cp $wp_config_file $wp_config_temp_file
	sudo sudo cp ./.htaccess $wpdir
	# sudo chown -R $USER:www-data /var/www/html
	sudo systemctl restart apache2
	echo -e "In your browser, go to $IP/admin and fill out the information."
	read "Press ENTER when done to continue..."
	echo "End WordPress installation and configuration"

}


# Install and configure NGINX
install_nginx(){		
	echo -e "\nBegin NGINX installation and configuration..."
	sudo apt-get install -y nginx > /dev/null
	sudo cp ./example.conf ./$domain.conf
	sudo sed -i "s/your_domain_here/$domain/" ./$domain.conf
	sudo sed -i "s/www.your_domain_here/www.$domain/" ./$domain.conf
	sudo mv ./$domain.conf /etc/nginx/sites-available/
	sudo ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/
	sudo mv /etc/nginx/sites-available/default.conf /etc/nginx/sites-available/default.conf.disabled
	echo "End NGINX installation and configuration"

}

# Install NodeJS and NPM
install_node(){
	echo -e "\nBegin NodeJS and NPM installation..."
	curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
	sudo apt-get install -y nodejs > /dev/null
	sudo apt-get install -y npm > /dev/null
	# update nodejs
	# sudo npm cache clean -f
	# sudo npm install -g n
	# sudo n stable
	sudo ln -s /usr/bin/nodejs /usr/local/bin/node
	sudo npm i -g nodemon > /dev/null
	sudo npm i -g concurrently > /dev/null
	sudo npm i -g npx > /dev/null

	echo "End NodeJS and NPM installation"
}

# Install and configure React
install_react_app(){
	echo -e "\nBeginning React installation and configuration..."
	cd ~
	dir=$(pwd) 
	dir_node=$dir/"$slug"_node
	dir_prototype_node=$dir/prototype-node

	
	git clone https://github.com/grayalienventures/prototype-node.git
	mv $dir_prototype_node $dir_node
	# make sure remove folder prototype_node
	sudo rm -rf $dir_prototype_node
	# copy .env
	cp $current_dir/.env $dir_node/.env
	# add domain to .env
	sed -i -e "s/yourdomainhere/"$domain"/;s/yourtitlehere/"$sitetitle"/" $dir_node/.env
	# add domain to .env
	cp $current_dir/webpack.config.js $dir_node/webpack.config.js
	# copy .localConfig
	cp $current_dir/localConfig.js $dir_node/src/localConfig.js
	# add domain to .localConfig
	sed -i -e "s/yourslughere/"$slug"/" $dir_node/src/localConfig.js
	cd $dir_node
	# install dependencies
	npm i
	npm run start-build </dev/null &>/dev/null &
	
	echo "End React installation and configuration"

	cd $current_dir
}

# Install and configure SSL
install_certificate_ssl(){
	echo -e "\nBegin SSL installation and configuration..."
	sudo mkdir /etc/nginx/ssl
	sudo chown -R root:root /etc/nginx/ssl
	sudo chmod -R 600 /etc/nginx/ssl
	sudo a2enmod ssl
	sudo a2enmod rewrite
	sudo systemctl stop apache2
	sudo systemctl stop nginx
	sudo mkdir /etc/systemd/system/nginx.service.d
	sudo printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
	sudo cp ./ports.conf /etc/apache2/ports.conf
	echo -e "\n<IfModule mod_rewrite>\n\tRewriteEngine On\n</IfModule>" | sudo tee -a /etc/apache2/apache2.conf > /dev/null
	sudo cp 000-default.conf temp-000-default.conf
	sudo sed -i "s/your_domain_here/$domain/g" temp-000-default.conf > /dev/null
	sudo mv ./temp-000-default.conf /etc/apache2/sites-available/000-default.conf
	sudo rm /etc/nginx/sites-available/default
	sudo rm /etc/nginx/sites-enabled/default
	sudo openssl genrsa -out server-key.pem 2048;
	sudo openssl req -new -key server-key.pem -out server-csr.pem
	sudo openssl x509 -req -in server-csr.pem -signkey server-key.pem -out server-cert.pem
	sudo cp server-cert.pem /etc/nginx/ssl/$domain.chained.crt
	sudo cp server-key.pem /etc/nginx/ssl/$domain.key

	sudo systemctl start nginx
	sudo systemctl start apache2

	sudo systemctl daemon-reload
	sudo systemctl restart apache2
	sudo systemctl restart nginx
	echo "End SSL installation and configuration"
}


create_swapfile
upgrade_system 
install_apache 
install_php
install_mysql 
config_ns_records 
install_wp 
install_nginx 
install_react_app 
install_certificate_ssl