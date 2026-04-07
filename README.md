# 🚀 Static Website Deployment with Ansible (Azure VMs)

This project demonstrates how to use Ansible to automate the deployment of a static website across multiple Azure virtual machines.

## 📌 Pre-requisites / Assumptions
Azure VMs already provisioned (at least one, ideally multiple)
VMs grouped under [web] in inventory.ini
OS: Ubuntu 22.04 (or similar)
Public IP access to each VM
SSH key-based authentication (passwordless)

## 📦 Project Source
Demo reference:
https://ebstaticwebsite.z29.web.core.windows.net
Static website source:
https://github.com/pravinmishraaws/Azure-Static-Website

## 📁 Project Structure
static-web/
├─ inventory.ini
├─ site.yml
├─ files/
│  └─ index.html
└─ README.md
inventory.ini → Defines target servers
site.yml → Multi-play Ansible playbook
files/index.html → Static website content

## ⚙️ What I Did
1. Set Up Project Structure
Created the static-web/ directory
Added inventory.ini, site.yml, and README.md
Created a files/ directory to store deployment assets

2. Retrieved Static Content
Downloaded index.html from the GitHub repository
Placed it in files/index.html
Prepared it locally on the control node for deployment using Ansible.

3. Created Multi-Play Ansible Playbook

**Play 1** — Install & Configure Web Server
Target: web group
Used become: true
Installed Nginx using apt
Ensured Nginx service is started and enabled

**Play 2** — Deploy Static Content
Target: web group
Used become: true
Copied files/index.html → /var/www/html/index.html
Set:
Owner: www-data
Permissions: 0644
Added a handler to reload Nginx when changes occur

**Play 3** — Verify Deployment
Target: localhost
Used uri module to send HTTP requests to each web server
Verified that each server returns status code 200

## ▶️ Running the Playbook
ansible-playbook -i inventory.ini site.yml

## 🔍 Manual Verification

Using curl:

curl http://<web_ip>

Or open in browser:

http://<web_ip>
