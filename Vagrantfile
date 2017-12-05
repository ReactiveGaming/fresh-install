# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-17.10"
  config.vm.box_check_update = true
  
  # Set up some port forwarding
  config.vm.network :forwarded_port, guest: 80, host: 11011
  config.vm.network :forwarded_port, guest: 8080, host: 11012
  config.vm.network :forwarded_port, guest: 3697, host: 11013
  config.vm.network :forwarded_port, guest: 6001, host: 11014
  config.vm.network :forwarded_port, guest: 22, host: 11015, id: 'ssh'
  config.vm.network :private_network, ip: "192.168.99.101"
  
  # Add any synched folders you need
  # config.vm.synced_folder "../Projects/", "/home/vagrant/projects"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = "2048"
  end
end
