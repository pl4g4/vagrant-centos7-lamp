vagrant-centos7-lamp
======================

Centos7 LAMP for vagrant dev

Setting things up may take some time since it's downloading all necessary packages to have LAMP.

When it is done installing you can go to http://127.0.0.1:8080

Virtual Machine Specifications
==============================

- PHP v5.4.16 
- Zend Engine v2.4.0
- Xdebug v2.3.3
- Memcached
- MYSQL Ver 14.14 Distrib 5.7.11
- Apache v2.4
- Composer
- CURL
- GIT

Connect to MYSQL
================

Connection to mysql will have to be using ssh

host: 127.0.0.1
port: 3306

SSH KEY -> Find it in your vagrant folder. [More info](https://github.com/Varying-Vagrant-Vagrants/VVV/wiki/Connect-to-Your-Vagrant-Virtual-Machine-with-PuTTY)

Login information will appear after the setup is done.

Others
======

If you do not wish to build the same vm every time you destroy it. You could create a new box image, and use it. You will have to change the vagrantfile to point to your new box.

```
vagrant package --base centos7-vagrant 
```

If will generate a new box in the project. Point to the new box and change bootstrap.sh to JUST start the services, You will need to remove or commentout most of the script.