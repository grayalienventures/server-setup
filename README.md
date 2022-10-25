# Rapid React App and Server Setup



The server setup described in this article establishes a **ReactJS frontend** that communicates with a **WordPress backend**.  An NGINX reverse proxy server is used to appropriately handle requests for the NodeJS and Apache servers.  Finally, the script generates and enables an SSL via CertBot.  All of this is accomplished by running a single script!



[![YouTube Tutorial](https://img.youtube.com/vi/sLDz6UC6Ycs/hqdefault.jpg)](https://www.youtube.com/watch?v=sLDz6UC6Ycs)

*You can also watch this tutorial for setup information.*



This configuration is useful for both websites and web apps, and the backend can be used for mobile apps as well.  Leveraging WordPress’s extensive library, the core plugin that is automatically uploaded and activated via the install.sh script allows developers to start building at a further stage with fully functioning authentication, API endpoints, and database structure.  Further, clients are able to easily change content via the WordPress admin panel, an ergonomic method that removes the requirement for the developer to be involved in content updates.



![Rapid React App and Server Setup Overview](https://github.com/grayalienventures/server-setup/blob/main/images/script_server_setup.png)



# Prerequisites



A **VPS**, or Virtual Private Server, and domain name are required prior to running the script.  [DigitalOcean](https://m.do.co/c/8b231954196d) is the best place for VPS hosting, and as of the time of writing this, they are offering a $60 credit if you sign up via this [referral link](https://m.do.co/c/8b231954196d).  For domain names, [NameCheap](https://namecheap.pxf.io/qnmagq) is our preferred source and they often provide discounts with this [referral link](https://namecheap.pxf.io/qnmagq).

When creating your droplet, or DigitalOcean VPS instance, select the latest stable version of Ubuntu.  The 1 GB Regular SSD CPU for $6.00 per month suffices for most projects.



![DigitalOcean Droplet Pricing](https://github.com/grayalienventures/server-setup/blob/main/images/droplet_pricing.png)



# Creating Non-root User



Once your VPS is created, SSH into it as root and add a new user.



```bash

adduser newuser

```



Then, add this user to the sudoers file.



```bash

visudo

```



![Add user to visudo](https://github.com/grayalienventures/server-setup/blob/main/images/visudo.png)



# Run install.sh



SSH back into your VPS as the non-root user, clone the [Gray Alien Ventures `server-setup` repo](https://github.com/grayalienventures/server-setup), enter the directory, and run install.sh as sudo.



```bash

git clone https://github.com/grayalienventures/server-setup
cd server-setup
sudo ./install.sh

```



# Completion



To view your website, go to the domain name you entered in the script.  Note that it may take about a minute or so for your site to be built, before which time you will see a ‘Not found.’ error.  You can log in and out to the app skeleton, as well as set personal information in the ‘Settings’ menu item.

To access the WordPress backend, go to `https://<your domain>/admin/wp-admin`.

Happy hacking 👽 
