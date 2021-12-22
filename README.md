# General



At Gray Alien Ventures, a lot of our projects involve a React frontend with a WordPress backend, or sometimes even just a WordPress site. Using WordPress in this way provides us out-of-the-box functionality for authentication, user management, API endpoints, and so forth, while still maintaining the upsides of using React for the frontend website and/or app.

  

# Hosting

  

A **Virtual Private Server**, or **VPS**, is the machine that hosts your code. It is a low-cost alternative to managing a **dedicated server** and is used in most web and mobile app development.

  

We use [DigitalOcean](https://m.do.co/c/8b231954196d) for most of our projects.

  

When [creating a new Droplet](https://m.do.co/c/8b231954196d), select the latest LTS distribution of Ubuntu.

  

![Droplet OS Image - Ubuntu](https://github.com/grayalienventures/server-setup/blob/main/images/os_image.jpg)

  

Then, select whichever CPU options and Droplet plan is right for your project. Because the bulk of our contracts are with early stage companies seeking to develop a **Minimum Viable Product**, or **MVP**, our resource requirements are low enough that the Regular Intel CPU with SSD option for $5.00 per month suffices.

  

![Droplet CPU Option - Regular Intel CPU with SSD option for $5.00](https://github.com/grayalienventures/server-setup/blob/main/images/droplet_plan.jpg)

  

After this, select a data center closest to where you anticipate most of your traffic to come from, create a password, choose a hostname that is similar or the same to your project’s name, and click `Create Droplet`. If you know how to use SSH keys, then use this option instead of using a password, but this should be obvious to those that do.

  

# Domain Name

  

Now that you have your host setup, you will most likely need a **domain name**, unless you wish to tell people your IP address each time. *You do not.*

  

[NameCheap](https://namecheap.pxf.io/qnmagq) is where we purchase our domain names.
