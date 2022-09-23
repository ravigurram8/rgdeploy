### Create an Application Load Balancer

Deploying an Application Load Balancer as part of Research Gateway deployment helps in two ways:
1. Isolates your portal from being directly exposed over the internet. The ALB allows only https(s) traffic through.
2. Helps to serve the application on a secure port using SSL certificates stored in AWS ACM.

create an ALB security Group with the following inbound and outbound rules.
 - Inbound rules - HTTP 80 ,HTTPS 443,SSH 22 .
 - outbound Rules - All Traffic.

Use the AWS CLI to create an Application Load Balancer choosing all three public subnets created by the quickstart above.

    aws elbv2 create-load-balancer --name research-gw-alb --subnets subnet-abcd1234 subnet-abcd5678 subnet-abcd9876 --security-groups sg-abcd1234 --region us-east-1
The output of the command above will include the ARN of the loadbalancer. e.g. arn:aws:elasticloadbalancing:region:aws_account_id:loadbalancer/app/research-gw-alb/e5ba62739c16e642

### Create a target group

    aws elbv2 create-target-group --name tg-research-gw --protocol HTTP --port 80 --target-type instance --vpc-id vpc-abcd1234 --region us-east-1
The output of the command will include the ARN of the target group. e.g. arn:aws:elasticloadbalancing:region:aws_account_id:targetgroup/tg-research-gw/209a844cd01825a4

#### Create a listener on port 443  

    aws elbv2 create-listener --load-balancer-arn arn:aws:elasticloadbalancing:region:aws_account_id:loadbalancer/app/research-gw-alb/e5ba62739c16e642 --protocol HTTPS --port 443 --certificates CertificateArn=arn:aws:acm:us-east-1:aws_account_id:certificate/480cdfa8-bac6-4b99-977f-5f18441de49e  --ssl-policy ELBSecurityPolicy-2016-08 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:aws_account_id:targetgroup/tg-research-gw/209a844cd01825a4 --region us-east-1

#### Create a listener on port 80 

Note: This is only recommended for test setups and some of the features like secure links for resources will not work.

    aws elbv2 create-listener --load-balancer-arn arn:aws:elasticloadbalancing:region:aws_account_id:loadbalancer/app/research-gw-alb/e5ba62739c16e642 --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:aws_account_id:targetgroup/tg-research-gw/209a844cd01825a4 