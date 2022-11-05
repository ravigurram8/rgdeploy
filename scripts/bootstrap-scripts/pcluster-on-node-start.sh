#!/bin/bash                                                                     
sudo yum update -y --security                                                          
file="/home/ec2-user/security-update.txt"                                                  
echo "last security update was on $(date)" > $file
cat $file 