# Reverse Proxy Jenkins on EC2 With Nginx

## **Project Goal:**

Our objective is to use  Terraform for provisioning an EC2 instance running Ubuntu, equipped with both Jenkins and Nginx. Using Terraform, we'll establish security groups to restrict access solely to our IP address for ports 22, 80, 8080, and 443. Nginx will act as a reverse proxy for Jenkins, facilitating a secure and encrypted HTTPS connection.

Access to the EC2 instance will be via SSH, employing a locally generated .pem key during launch.

Upon establishing the SSH connection, our initial steps will involve verifying the operational status of Jenkins and Nginx. Subsequently, we'll proceed to configure the reverse proxy settings.

## Tech Stack:

Our setup involves utilizing

- EC2
- Route 53 ( or your preferred DNS provider)
- Ubuntu
- Terraform
- Jenkins
- Nginx
- [letsencrypt.org](http://letsencrypt.org) (SSL Certification)

The Terraform EC2 user data follows [jenkins.io](https://www.jenkins.io/doc/book/installing/linux/#debianubuntu) Debian/Ubuintu installation process and has the Nginx installation. When applying our Terraform configuration, our **`.pem`** key should be inside our working directory. 

![key_example.png](Reverse%20Proxy%20Jenkins%20on%20EC2%20With%20Nginx%20d956f370a22349a094e7d311d0e6f870/key_example.png)

We can utilize the output IP to verify the functioning of Nginx through HTTP and confirm the operational status of Jenkins on port 8080. (I'd suggest attaching an Elastic IP to your EC2 instance, especially for extended use; it's a safer option compared to using a public IP.) 

Before SSHing, we will have to change our **`.pem`**  file permissions.

```bash
chmod 400 jenkins_key

ssh -i ./jenkins_key ubuntu@<ec2-public-ip>
```

Once inside our instance we want to change our permissions.

```bash
sudo su - 
```

We will now make a new file named 'jenkins' in the '/etc/nginx/sites-available/' folder. This file will contain settings specifically for connecting Jenkins with Nginx and setting it up as a reverse proxy.

```bash
sudo nano /etc/nginx/sites-available/jenkins
```

Copy the following configuration for the reverse proxy into the new file and save.

```
server {
    listen 80;
    server_name your-dns.com; # Replace with your domain

    location / {
        proxy_pass http://localhost:8080; # Jenkins is running on the default port
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ~ /\. {
        deny all;
    }
}
```

Link the 'jenkins' configuration file to the 'sites-enabled' folder in Nginx

```bash
sudo ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
```

To complete the setup, restart Nginx to apply the changes

```bash
sudo systemctl restart nginx
```

(Create a new A record on your DNS provider using your instance’s IP before accessing your Jenkins service. This step is essential for establishing a connection)

When  accessing our domain name, we should reach our Jenkins server. However, you will notice a warning regarding the security of our Jenkins server, it's because HTTPS hasn't been set up yet. To secure our EC2 instance, we'll apply an SSL certificate using Let's Encrypt's Certbot.

![notsecure_jenkins.png](Reverse%20Proxy%20Jenkins%20on%20EC2%20With%20Nginx%20d956f370a22349a094e7d311d0e6f870/notsecure_jenkins.png)

We need to allow ingress for HTTP in the security group to enable our EC2 instance to connect with Let's Encrypt. Change the IP range if it's set to your private IP; this can be updated later.

```bash
sudo apt install python3-certbot-nginx
certbot --version # check that certbot has been installed

certbot --nginx -d your-dns.com #use your domain and follow the instructions prompted
```

We now have an EC2 Jenkins instance secured with HTTPS, thanks to the Nginx reverse proxy.

![secure_jenkins.png](Reverse%20Proxy%20Jenkins%20on%20EC2%20With%20Nginx%20d956f370a22349a094e7d311d0e6f870/secure_jenkins.png)