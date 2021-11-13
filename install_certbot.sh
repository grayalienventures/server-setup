#!/bin/bash


current_dir=$(pwd) 
echo "************************************************************
*****          INTP LLC CERBOT CERTIFICATE SSL SETUP          *****
************************************************************"

# Input prompts
echo -e "\nEnter domain name (example.com)"
read domain
echo -e "\nEnter Email (email@example.com)"
read email
sudo snap install --classic certbot> /dev/null
certbot --nginx -d "$domain" -d "www.$domain" -m $email --agree-tos -n
certbot renew --dry-run