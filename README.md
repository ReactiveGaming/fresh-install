# Setting up a Virtual Machine
```
Make sure you have VirtualBox and Vagrant installed
Put the provided Vagrantfile somewhere on your machine
In your terminal, go to that folder and type 'vagrant up'
```

# Installation on Virtual Machine
```
git clone https://github.com/ReactiveGaming/fresh-install ~/fresh
sudo ~/fresh/install.sh
rm -fR ~/fresh
```

# What does this do?
This script will configure a development environment (intended for Ubuntu 16.04) geared toward web development. More specifcally, this creates a machine that's ready to develop for Reactive Gaming, complete with the initial database and supervisor workers.

## Major Features
Uninstall Apache  
Install most packages needed for general compilation purposes  
Install PHP 7.1 (and a bunch of extensions)  
Install nginx 1.13.3  
Install Python 2.7  
Install NodeJS 9.2 and NPM  
Install Cairo, Pango, and some other image packages  
Install Redis, MySQL and Apache Cassandra  
Install Sodium  
Install Supervisor  
Install Memcached and Beanstalkd  
Update and Upgrade system
