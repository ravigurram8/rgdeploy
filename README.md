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
## Research Gateway Architecture
   ![image](https://user-images.githubusercontent.com/73109773/141417964-3738d959-99a2-471d-bf34-15f15637eac8.png)

## 1. Hardware Requirements
| Virtual Machine Purpose            | Virtual Machine Spec                                           |
|------------------------------------|----------------------------------------------------------------|
| Role: Portal                       | t2.large 2CPU, 8GB RAM, 100GB Disk                            |
| Role: DB (Option 2) AWS DocumentDB | db.t3.large (dev) db.r5.large+ (prod)                          |

## 2. Network Requirements
   a. VPC  
   b. 3 Public Subnets  
   c. 3 Private Subnets  
   d. IGW  
   e. NAT Instance / NAT Gateway  
   f. Bastion Hosts  
   g. Appliation Load Balancer  
   h. Listener  
   i. ACM or External Certificates for SSL  
   j. Target Group  
   
 ### Create #2a - #2c above using the following quick-start:  
 
 [![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://us-west-2.console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/create/review?templateURL=https://aws-quickstart.s3.amazonaws.com/quickstart-aws-vpc/templates/aws-vpc.template.yaml&param_NumberOfAZs=3)

## 3. Software Requirements

| Virtual Machine Purpose     | Software pre-requisites |
|-----------------------------|-------------------------|
| Role: Portal                | Python, Docker 20.04+   |
| Role: DB (Option 1) MongoDB | MongoDB 3.6.23          |
|                             |                         |

The software above will be available pre-deployed on the AMI shared with you.

## AWS Services required
- AWS Cognito
- Amazon S3
- AWS CloudFormation
- AWS DocumentDB

# Installing the required 3rd party software
The following sofware needs to be installed on the Portal EC2 instance
| Software  | Version |
|-----------|---------|
| MongoDB   | 3.6.23  |
| Docker    | 20.10.9 |

For your convenience we have created packer scripts which allow you to create the AMI in your account.
If an AMI with the pre-requisites has been shared with you, you can skip this section. 

## Creating the AMI with pre-requisites.

You can create the AMI with pre-requisites yourself by following these steps:
- Install packer
- Export AWS Access Keys and Secret Keys 
   - export AWS_ACCESS_KEY_ID="your_Access_Key"
   - export AWS_SECRET_ACCESS_KEY="your_Secret_Key"
   - export AWS_DEFAULT_REGION="Your_Region"
- Clone this repo on a machine.
- Create a Role and attach a policy which permits ECR and EC2 actions and Replace the "iam-instance_profile" :"<your_rolename>" in builders section which is in the packer-rg.json.
- Run packer build packer-rg.json
- packer build -var 'awsRegion=your_region' -var 'vpcId=your_VPCID' -var 'subnetId=your_SubnetID' packer-rg.json
- At Run time pass VPCID, SubnetID, AWSRegion as variables declared in packer-rg.json
- Note that AMI id from the output

## Installing Research Gateway
- Clone this repo on a machine that has AWS CLI configured with Default output format as JSON.
- Run deploy.sh with the following parameters

| Parameter#  | Purpose                                                                                          |
|-------------|--------------------------------------------------------------------------------------------------|
| Param 1     | The AMI from which the EC2 instance that runs Research Gateway should be created                 |
| Param 2     | Name of the S3 bucket to create which holds the CFT templates used in the Standard Catalog       |
| Param 3     | VPC Id of the VPC in which to launch the Research Gateway EC2 instance                           |
| Param 4     | The Subnet1 in which to launch the Research Gateway DocumentDB                                   |
| Param 5     | The Subnet2 in which to launch the Research Gateway DocumentDB                                   |
| Param 6     | The Subnet3 in which to launch the Research Gateway DocumentDB                                   |
| Param 7     | The Key Pair to use for launching the EC2 Instance                                               |
| Param 8     | Choose the environment - one of PROD, STAGE, QA, DEV |
| Param 9     | The URL at which the Research Gateway will be accessed. e.g. https://myrg.example.com |
| Param 10     | The Target Group ARN to which the Portal EC2 instance should be added                     |

## Creating the first user
- Connect to the EC2 instance using SSH or the SSM Session Manager from the AWS Console
- Run the following command
  - create_rg_admin_user.sh
- Enter the details prompted
   - First Name
   - Last Name
   - Email Id
- Ensure you get a success message.
- Check your email for an email with a verification link. You may need to check your spam folder for an email from 
no-reply@verificationemail.com
- Click on the verification link in the email and change your password.
- You can now access the Research Gateway at the URL (Param 9 above) with the email id and password.
- Refer to the [help pages](https://researchgateway.readthedocs.io/en/latest/) for more details on using Research Gateway

