# Enterprise deployment of RLCatalyst Research Gateway

## Introduction

Welcome to the RLCatalyst Research Gateway deployment manual. This guide is designed to provide documentation for users who will be installing and administering the Research Gateway product.

## What is Research Gateway

RLCatalyst Research Gateway is a solution built on AWS, and provides a self-service portal with cost and budget management that helps consume AWS resources for Scientific Research. It can be easily integrated into existing AWS customer accounts. It provides 1-Click AWS Service Catalog assets. budget management and data access with secure governance. Universities and Research Institutions can adopt this solution with minimal upfront investments. It is available in both SaaS and Enterprise models.

This is a cost-effective pre-built solution and packaged service offerings built on AWS.
It supports both self hosting(Enterprise) and managed hosting(SaaS) options
It is easy to deploy, consume, manage and extend.
It provides easy budget and cost governance.
It provides in-built security, based on AWS Best Practices
It provides a pre-built catalog of products which are ready to use out of the box.

## Planning for deployment

### Research Gateway Architecture

![image](https://user-images.githubusercontent.com/73109773/141417964-3738d959-99a2-471d-bf34-15f15637eac8.png)

#### 1. Hardware Requirements

| Virtual Machine Purpose            | Virtual Machine Spec                  |
| ---------------------------------- | ------------------------------------- |
| Role: Portal                       | t2.large 2CPU, 8GB RAM, 100GB Disk    |
| Role: DB AWS DocumentDB            | db.t3.large (dev) db.r5.large+ (prod) |

#### 2. Network Requirements

 1. VPC  
 2. 3 Public Subnets  
 3. 3 Private Subnets  
 4. IGW  
 5. NAT Instance / NAT Gateway  
 6. Bastion Hosts  
 7. Application Load Balancer  
 8. Listener  
 9. ACM or External Certificates for SSL  
 10. Target Group

<!-- trunk-ignore(markdownlint/MD036) -->
*Create #1 - #5 above using the following quick-start*


[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://us-west-2.console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/create/review?templateURL=https://aws-quickstart.s3.amazonaws.com/quickstart-aws-vpc/templates/aws-vpc.template.yaml&param_NumberOfAZs=3)


<!-- trunk-ignore(markdownlint/MD036) -->
*Create an Application Load Balancer*

Deploying an Application Load Balancer as part of Research Gateway deployment helps in two ways:
1. Isolates your portal from being directly exposed over the internet. The ALB allows only https(s) traffic through.
2. Helps to serve the application on a secure port using SSL certificates stored in AWS ACM.

Use the AWS CLI to create an Application Load Balancer choosing all three public subnets created by the quickstart above.

    aws elbv2 create-load-balancer --name research-gw-alb --subnets subnet-abcd1234 subnet-abcd5678 subnet-abcd9876 --security-groups sg-abcd1234 --region us-east-1
The output of the command above will include the ARN of the loadbalancer. e.g. arn:aws:elasticloadbalancing:region:aws_account_id:loadbalancer/app/research-gw-alb/e5ba62739c16e642

*Create a target group*

    aws elbv2 create-target-group --name tg-research-gw --protocol HTTP --port 80 --target-type instance --vpc-id vpc-abcd1234 --region us-east-1
The output of the command will include the ARN of the target group. e.g. arn:aws:elasticloadbalancing:region:aws_account_id:targetgroup/tg-research-gw/209a844cd01825a4


*Create a certificate for your domain*

To make the Research Gateway application available securely over SSL, you need a certificate issued by a public Certificate Authority (CA). 
If you already have a certificate for your domain issued by a third-party CA, you can import it into ACM. [See how](https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html).
If you already have a certificate for your domain issued by AWS in ACM, you can skip the following step.

     aws acm request-certificate --domain-name www.example.com --validation-method DNS --idempotency-token 1234 --options CertificateTransparencyLoggingPreference=DISABLED

You will need to validate your ownership of the domain either via DNS (recommended) or via email.

Fore more details on requesting a certificate, follow this [link](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)

*Create a listener on port 443 * 

    aws elbv2 create-listener --load-balancer-arn arn:aws:elasticloadbalancing:region:aws_account_id:loadbalancer/app/research-gw-alb/e5ba62739c16e642 --protocol HTTPS --port 443 --certificates CertificateArn=arn:aws:acm:us-east-1:aws_account_id:certificate/480cdfa8-bac6-4b99-977f-5f18441de49e  --ssl-policy ELBSecurityPolicy-2016-08 --default-actions Type=forward, TargetGroupArn=arn:aws:elasticloadbalancing:region:aws_account_id:targetgroup/tg-research-gw/209a844cd01825a4 --region us-east-1

*Create a listener on port 80 *

Note: This is only recommended for test setups and some of the features like secure links for resources will not work.

    aws elbv2 create-listener arn:aws:elasticloadbalancing:region:aws_account_id:loadbalancer/app/research-gw-alb/e5ba62739c16e642 --protocol HTTPS --port 80 --default-actions Type=forward, TargetGroupArn=arn:aws:elasticloadbalancing:region:aws_account_id:targetgroup/tg-research-gw/209a844cd01825a4 --region us-east-1

<!-- trunk-ignore(markdownlint/MD036) -->
*Set up Route 53 for your domain/sub-domain*

From the AWS Console, select Route 53 service. Create a hosted zone for your domain. If you are using an existing domain you can add a CNAME record and select the public DNS name of the ALB as the value. It is also possible to create a separate hosted zone for the sub-domain used for Research Gateway.

*Note* - It is possible to use Research Gateway without a domain-name but we do not recommend that for product workloads. To do so, use the public DNS name of the ALB as the URL of the Research Gateway in the setup scripts.

#### 3. Software Requirements

| Virtual Machine Purpose     | Software pre-requisites |
| --------------------------- | ----------------------- |
| Role: Portal                | Python, Docker 20.04+   |
| Role: DB (Option 1) MongoDB | MongoDB 3.6.23          |
|                             |                         |

The application software for Research Gateway will be made available to you as a docker image shared from Relevance Lab's Elastic Container Registry instance to your AWS account.
As a part of this deployment, you will create an AMI for the portal EC2 instance which will have these softwares pre-deployed. Alternately, you can request the AMI to be shared with you by Relevance Lab and the software above will be available pre-deployed on the AMI shared with you.

#### 4. AWS Services required

- AWS Cognito
- Amazon S3
- AWS CloudFormation
- AWS DocumentDB
- AWS ImageBuilder
- AWS EC2
- AWS IAM

## Installing the required 3rd party software

The following sofware needs to be installed on the Portal EC2 instance
| Software  | Version |
|-----------|---------|
| MongoDB   | 3.6.23  |
| Docker    | 20.10.9 |
| AWS CLI   | latest  |
| jq        | latest  |
| zip       | latest  |

For your convenience we have created packer scripts which allow you to create the AMI in your account.
If an AMI with the pre-requisites has been shared with you, you can skip this section.

### Creating the AMI with pre-requisites

You can create the AMI with pre-requisites yourself by following these steps:

- [Install packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)
- Export AWS Access Keys and Secret Keys
   
      export AWS_ACCESS_KEY_ID="your_Access_Key"
      export AWS_SECRET_ACCESS_KEY="your_Secret_Key"
      export AWS_DEFAULT_REGION="Your_Region"

- Clone this repo on a machine.
- Create a Role and attach a policy which permits ECR and EC2 actions and Replace the "iam-instance_profile" :"<your_rolename>" in builders section which is in the packer-rg.json.
- Run packer build packer-rg.json
    
      packer build -var 'awsRegion=your_region' -var 'vpcId=your_VPCID' -var 'subnetId=your_SubnetID' packer-rg.json
- At Run time pass VPCID, SubnetID, AWSRegion as variables declared in packer-rg.json
- Note that AMI id from the output

### Installing Research Gateway

Clone this repo on a machine that has AWS CLI configured with Default output format as JSON.
Run deploy.sh with the following parameters

| Parameter# | Purpose                                                                                    |
| ---------- | ------------------------------------------------------------------------------------------ |
| Param 1    | The AMI from which the EC2 instance that runs Research Gateway should be created           |
| Param 2    | Name of the S3 bucket to create which holds the CFT templates used in the Standard Catalog |
| Param 3    | VPC Id of the VPC in which to launch the Research Gateway EC2 instance                     |
| Param 4    | The Private Subnet1 in which to launch the Research Gateway DocumentDB                             |
| Param 5    | The Private Subnet2 in which to launch the Research Gateway DocumentDB                             |
| Param 6    | The Private Subnet3 in which to launch the Research Gateway DocumentDB                             |
| Param 7    | The Key Pair to use for launching the EC2 Instance                                         |
| Param 8    | Choose the environment - one of PROD, STAGE, QA, DEV                                       |
| Param 9    | The URL at which the Research Gateway will be accessed. e.g. https://myrg.example.com      |
| Param 10   | The Target Group ARN to which the Portal EC2 instance should be added                      |

*Note:* If you run into errors and only some stacks are created, you can retry the same deployment by running deploy.sh as follows.
    
    ./deploy.sh -f runid.json

runid.json is created in the rgdeploy folder when you first run deploy.sh with parameters. Example jwzx.json. All the original parameters passed to deploy.sh are stored in this file and enable the process to be picked up from where it was interrupted.

### Updating the AMI list for AMI based products

The deployment creates EC2 Image Builder pipelines for building the RStudio and Nextflow AMIs that are used within Research Gateway. By default, these pipelines are set up to be manually triggered. You can change that in the AWS console if you wish to  trigger them on a schedule.

Once a build is completed, the AMIs are automatically distributed to the regions supported by Research Gateway in your account. The AMI Ids need to be updated into your database before creating any projects. 

- Note down the names of the two pipelines created for RStudio and Nextflow_Advanced. They will be of the format:
RG-PortalStack-ImageBuilder-$runid-Pipeline_RStudio
RG-PortalStack-ImageBuilder-$runid-Pipeline_Nextflow_Advanced.
The runid will be the random 4-character string generated for your instance during deployment. All the stacks created in your deployment should have that as a suffix.
- In the rgdeploy folder, cd to products folder. You will find an img-builder-config.json file there. Edit it and set the pipeline names according to the ones deployed in your account. Save the file.
- Run the script make-amilist.sh. You may have to run chmod +x make-amilist.sh if execute permissions are not set on the file.

      ./make-amilist.sh > new-ami-list.json
- Next run the following command to update your DB.

      curl -X POST -H "Content-Type: application/json" -d  new-ami-list.json http://<RG-URL>/notificationsink/updateScAmiId
- Note that these AMI-Ids will be picked up by any projects created after this update. For projects already created prior to the update, you have to update the SSM Parameter Store paths (as mentioned in img-builder-config.json) for the project account with the ami-id of the corresponding region and product.

- Store the AMI Ids in the AWS SSM Parameter store of the base account (where Research Gateway runs) by running the following commands.

      ./products/make-ami-list-json.sh <region> > ./products/ami-list.json
      ./scripts/updatessmpaths.sh

### Creating the first user

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
