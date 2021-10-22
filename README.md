# Enterprise deployment of RLCatalyst Research Gateway

## Introduction  
Welcome to the RLCatalyst Research Gateway deployment manual. This guide is designed to provide documentation for users who will be installing and administering and using the Research Gateway product.

## What is Research Gateway 
RLCatalyst Research Gateway is a solution built on AWS, and provides a self-service portal with cost and budget management that helps consume AWS resources for Scientific Research. It can be easily integrated into existing AWS customer accounts. It provides 1-Click AWS Service Catalog assets. budget management and data access with secure governance. Universities and Research Institutions can adopt this solution with minimal upfront investments. It is available in both SaaS and Enterprise models.

This is a cost-effective pre-built solution and packaged service offerings built on AWS.
It supports both self hosting(Enterprise) and managed hosting(SaaS) options
It is easy to deploy, consume, manage and extend.
It provides easy budget and cost governance.
It provides in-built security, based on AWS Best Practices 
It provides a pre-built catalog of products which are ready to use out of the box.

# Planning for deployment

## Hardware Requirements
| Virtual Machine Purpose            | Virtual Machine Spec                                           |
|------------------------------------|----------------------------------------------------------------|
| Role: Portal                       | t2.medium 2CPU, 8GB RAM, 100GB Disk                            |
| Role: DB (Option 2) AWS DocumentDB | db.t3.large (dev) db.r5.large+ (prod)                          |

## Software Requirements

| Virtual Machine Purpose     | Software pre-requisites |
|-----------------------------|-------------------------|
| Role: Portal                | Python, Docker 20.04+   |
| Role: DB (Option 1) MongoDB | MongoDB 3.6.23          |
|                             |                         |

# Installing the required 3rd party software
The following sofware needs to be installed on the Portal EC2 instance
| Software  | Version |
|-----------|---------|
| MongoDB   | 3.6.23  |
| Redis     | 6.0.6   |
| Docker    | 20.10.9 |

If an AMI with the pre-requisites has been shared with you, you can skip this section.

## Creating the AMI with pre-requisites.
- Install packer
- Run packer build package-rg.json
- Note that AMI id from the output

## Installing Research Gateway
- Clone this repo on a machine that has AWS CLI configured
- Run deploy.sh with the following parameters
| Parameter#  | Purpose                                                                                          |
|-------------|--------------------------------------------------------------------------------------------------|
| Param 1     | The AMI from which the EC2 instance that runs Research Gateway should be created                 |
| Param 2     | Name of the S3 bucket to create which holds the CFT templates used in the Standard Catalog       |
| Param 3     | VPC Id of the VPC in which to launch the Research Gateway EC2 instance                           |
| Param 4     | Subnet Id of the subnet in which to launch the Research Gateway EC2 instance                     |
| Param 5     | The Key Pair to use for launching the EC2 Instance                                               |
| Param 6     | (Optional) The URL at which the Research Gateway will be accessed. e.g. https://myrg.example.com |



## Creating the first user
- Connect to the EC2 instance using SSH or the SSM Session Manager from the AWS Console
- Run the following command

  curl --location --request POST 'http://<application_url>/user/signup' --header 'token: <add_token_here>' --header 'Content-Type: application/json' --data-raw '{"first_name": "Add first name", "last_name": "Add last name", "email": "Add email", "password": "Add temp password", "level": 2 }

