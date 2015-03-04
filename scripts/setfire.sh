#!/bin/bash
sudo sh -c "echo \"Defaults:service  !requiretty\" >> /etc/sudoers"
sudo yum install nc -y 
