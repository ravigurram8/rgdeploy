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

## Installing MongoDB

## Installing Redis

## Installing Docker
