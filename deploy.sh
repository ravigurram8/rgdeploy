#!/bin/bash

if [ $? -lt 5 ]; then
  echo 'Usage: deploy.sh <amiid> <bucketname> <rgurl> '
  echo '       Param 1:  The AMI from which the EC2 for Research Gateway should be created'
  echo '       Param 2:  The S3 bucket to create for holding the CFT templates'
  echo '                 A random suffix will be added to uniquify the name'
  echo '       Param 3:  The VPC in which to launch the Research Gateway EC2 instance'
  echo '       Param 4:  The Subnet in which to launch the Research Gateway EC2 instance'
  echo '       Param 5:  The Key Pair to use for launching the EC2 instance.'
  echo '       Param 6:  (Optional) The URL at which Research Gateway will be accessed'
#  exit 1
fi
amiid=$1
bucketname=$2
vpcid=$3
subnetid=$4
keypairname=$5
rgurl=$6
localhome=`pwd`
adminusername='admin'
adminpassword=$(openssl rand -hex 24)
appuser='rguser'
appuserpassword=$(openssl rand -hex 24)
runid=$(openssl rand -hex 4)
bucketstackname="RG-Portal-Bucket-$runid"
BUCKET_TEST=`aws s3api head-bucket --bucket $bucketname 2>&1`
if [ -z "$BUCKET_TEST" ]; then
  echo "Bucket $bucketname exists, Hit Enter to continue, Ctrl-C to exit"
  read a && echo "Copying files to bucket $bucketname"
else
  echo "An S3 bucket with name $bucketname  doesn't exist in current AWS account. Creating..."
  bucketname="$bucketname-$runid"

  # Create S3 bucket to copy RG Deployment files, ensure --stack-name 'name'
  # should be unique and it does not exist as part of current stacks.
  echo "Deploying the bucket stack"
  aws cloudformation deploy --template-file rgdeploybucket.yml --stack-name "$bucketstackname" \
                            --parameter-overrides S3NewBucketName="$bucketname"
  echo "Waiting for stack $bucketname to finish deploying..."
  aws cloudformation wait stack-create-complete --stack-name $bucketstackname
  if [ $? -eq 255 ]; then
    echo "Failed to deploy stack $bucketstackname Exiting"
    exit 1
  fi
fi
# Populate the new S3 bucket with RG Deployment files default source bucketname rg-newdeployment-docs
echo "Synching RG Deployment Files to new S3 bucket $bucketname"
start=$(date +%s.%N)
aws s3 sync s3://rg-deployment-docs s3://$bucketname
duration=$(echo "$(date +%s.%N) - $start" | bc)
execution_time=`printf "%.2f seconds" $duration`
echo "S3 Sync Execution Time: $execution_time"

#Create local folder to store RG Deployment Files and a subfolder for cft templates and scripts
mkdir -p "$localhome/rg-deployment-docs/rg-cft-templates"

#Download RG Deployment files from S3 to the local folder created above,
echo "Copying RG Deployment Files to local folder"
start=$(date +%s.%N)
aws s3 cp s3://rg-deployment-docs/ $localhome/rg-deployment-docs --recursive
duration=$(echo "$(date +%s.%N) - $start" | bc)
execution_time=`printf "%.2f seconds" $duration`
echo "S3 Download Execution Time: $execution_time"
# Extract cft templates locally
echo "Extracting CFTs locally"
tar -xvf $localhome/rg-deployment-docs/rg-cft-templates.tar.gz -C $localhome/rg-deployment-docs/rg-cft-templates/

#Modify file RG_UserPool_CFT_final.yml to refer new S3 bucket
sed -i -e "s/rg-deployment-docs/$bucketname/" $localhome/rg-deployment-docs/RG_UserPool_CFT_final.yml

#Copy extracted cft template to the new bucket
echo "Copying deployment files to new bucket"
aws s3 sync $localhome/rg-deployment-docs/rg-cft-templates/ s3://$bucketname

#Creating the Cognito User Pool
echo "Creating Cognito User Pool"
userpoolstackname="RG-Portal-UserPool-$runid"
aws cloudformation deploy --template-file $localhome/rg-deployment-docs/RG_UserPool_CFT_final.yml \
                          --stack-name "$userpoolstackname" \
                          --parameter-overrides UserPoolNameParam="$userpoolstackname" PortalURLParam="$rgurl" \
                            Function1Name="UserManagementAfterSuccessSignup-$runid" Function2Name="UserManagement-$runid" \
                          --capabilities CAPABILITY_IAM

aws cloudformation wait stack-create-complete --stack-name "$userpoolstackname"

if [ $? -gt 0 ]; then
   echo " $userpoolstackname Stack Failed to Create "
   exit 1
fi

#Capture User Pool Client ID
userpoolclient_id=$(aws cloudformation describe-stack-resources --stack-name "$userpoolstackname" --logical-resource-id CognitoUserPoolClient | jq -r '.StackResources [] | .PhysicalResourceId')
#Capture User Pool ID
userpool_id=$(aws cloudformation describe-stack-resources --stack-name "$userpoolstackname" --logical-resource-id CognitoUserPool | jq -r '.StackResources [] | .PhysicalResourceId')

#update the AMI id in the RGMainStak CFT
sed -i -E "s/ami-[0-9a-zA-Z]+/$amiid/" $localhome/rg-deployment-docs/RGMainStack.yml

#Creating Main stack
echo "Deploying main stack (roles, ec2 instance etc.)"
mainstackname="RG-Portal-$runid"
aws cloudformation deploy --template-file $localhome/rg-deployment-docs/RGMainStack.yml --stack-name "$mainstackname" --parameter-overrides ClientId="$userpoolclient_id" UserPoolId="$userpool_id" CFTBucketName="$bucketname" RGUrl="$rgurl" UserPassword="$appuserpassword" AdminPassword="$adminpassword" VPC="$vpcid" Subnet1="$subnetid" KeyName1="$keypairname" --capabilities CAPABILITY_NAMED_IAM

aws cloudformation wait stack-create-complete --stack-name "$mainstackname"
if [ $? -gt 0 ]; then 
   echo " $mainstackname Stack Failed to Create "
   exit 1
else
   portalinstance_id=$(aws cloudformation describe-stack-resources --stack-name "$mainstackname" --logical-resource-id "RGEC2Instance" | jq -r '.StackResources[] | .PhysicalResourceId')
   echo "Research Gateway has been successfully deployed. You can access the EC2 instance using $portalinstance_id"   
fi
