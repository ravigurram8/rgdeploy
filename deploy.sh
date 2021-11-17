#!/bin/bash
# Verify that utilities we use in this script are installed on the machine
echo "Verifying utilities are installed"
apps=(jq aws)
for program in "${apps[@]}"; do
    if ! command -v "$program" > /dev/null 2>&1; then
        echo "$program not found. This Script needs jq and aws cli. Please install the application/s and restart deployment, Exiting."
        exit
else
        echo "$program found"
    fi
done
region=$(aws configure list | grep region | awk '{print $2}')
echo "current aws region is $region"

if [ "$1" = "-f" ]; then
  if [ -z "$2" ]; then
    echo "Need a filename with -f option"
    exit 1
  fi
  if ! [ -f $2 ]; then
    echo "Could not find file $2"
    exit 1
  fi
  echo "Reading past run details from $2"
  myinput=`cat $2`
  amiid=$(jq -r '.params.amiid' <<< ${myinput})
  bucketname=$(jq -r '.params.bucketname' <<< ${myinput})
  vpcid=$(jq -r '.params.vpcid' <<< ${myinput})
  subnet1id=$(jq -r '.params.subnet1id' <<< ${myinput})
  subnet2id=$(jq -r '.params.subnet2id' <<< ${myinput})
  subnet3id=$(jq -r '.params.subnet3id' <<< ${myinput})
  keypairname=$(jq -r '.params.keypairname' <<< ${myinput})
  rgurl=$(jq -r '.params.rgurl' <<< ${myinput})
  tgarn=$(jq -r '.params.tgarn' <<< ${myinput})

  runid=$(jq -r '.runid' <<< ${myinput})
  appuser=$(jq -r '.appuser' <<< ${myinput})
  appuserpassword=$(jq -r '.appuserpassword' <<< ${myinput})
  adminpassword=$(jq -r '.adminpassword' <<< ${myinput})
  echo "Run ID: $runid"
  echo "APPUSER: $appuser"
  echo "APPUSERPWD: $appuserpassword"
  echo "ADMINPWD: $adminpassword"
  echo "AMIID: $amiid"
  echo "BUCKET: $bucketname"
  echo "VPCID: $vpcid"
  echo "SUBNET1: $subnet1id"
  echo "SUBNET2: $subnet2id"
  echo "SUBNET3: $subnet3id"
  echo "KEYPAIR: $keypairname"
  echo "RGURL: $rgurl"
  echo "TGARN: $tgarn"

elif [ $# -lt 7 ]; then
  echo 'Usage: deploy.sh <amiid> <bucketname> <rgurl> '
  echo '       Param 1:  The AMI from which the EC2 for Research Gateway should be created'
  echo '       Param 2:  The S3 bucket to create for holding the CFT templates'
  echo '                 A random suffix will be added to uniquify the name'
  echo '       Param 3:  The VPC in which to launch the Research Gateway EC2 instance, DocumentDB'
  echo '       Param 4:  The Subnet1 in which to launch the Research Gateway DocumentDB'
  echo '       Param 5:  The Subnet2 in which to launch the Research Gateway DocumentDB'
  echo '       Param 6:  The Subnet3 in which to launch the Research Gateway DocumentDB'
  echo '       Param 7:  The Key Pair to use for launching the EC2 instance.'
  echo '       Param 8:  (Optional) The URL at which Research Gateway will be accessed'
  echo '       Param 9:  (Optional) The Target Group to which the Portal EC2 instance should be added'
  exit 1
else
  echo "New run"
  amiid=$1
  bucketname=$2
  vpcid=$3
  subnet1id=$4
  subnet2id=$5
  subnet3id=$6
  keypairname=$7
  rgurl=$8
  tgarn=$9
  runid=$(date +%s | sha256sum | base64 | tr -dc _a-z-0-9| head -c 4 ; echo)
  appuser='rguser'
  appuserpassword=$(date +%s | sha256sum | base64 | tr -dc _a-z-0-9| head -c 24 ; echo)
  adminpassword=$(date +%s | sha256sum | base64 | tr -dc _a-z-0-9| head -c 24 ; echo)
  cat << EOT >> "$runid.json"
  {
    "runid": "$runid",
    "appuser": "$appuser",
    "appuserpassword": "$appuserpassword",
    "adminpassword": "$adminpassword",
    "params": {
      "amiid":  "$amiid",
      "bucketname":  "$bucketname",
      "vpcid":  "$vpcid",
      "subnet1id":  "$subnet1id",
      "subnet2id":  "$subnet2id",
      "subnet3id":  "$subnet3id",
      "keypairname":  "$keypairname",
      "rgurl":  "$rgurl",
      "tgarn":  "$tgarn"
    }
  }
EOT
fi
aws ec2 describe-images --image-id $amiid >/dev/null 2>&1
if [ $? -gt 0 ]; then
   echo "The AMI $amiid does not exist. Exiting"
   exit 1
fi

if ! [ `echo $bucketname | grep -P '(?=^.{3,63}$)(?!^xn\-\-)(?!.*s3alias$)(?!^(\d+\.)+\d+$)(^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])$)'` ]; then
  echo "Invalid bucketname passed"
  echo "See https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html"
  exit 1
fi

aws ec2 describe-vpcs --vpc-id $vpcid >/dev/null 2>&1
if [ $? -gt 0 ]; then
   echo "The VPC $vpcid does not exist. Exiting."
   exit 1
fi

aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpcid --subnet-ids $subnet1id >/dev/null 2>&1
if [ $? -gt 0 ]; then
   echo "The subnet $subnet1id does not belong to $vpcid. Exiting."
   exit 1
fi

aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpcid --subnet-ids $subnet2id >/dev/null 2>&1
if [ $? -gt 0 ]; then
   echo "The subnet $subnet2id does not belong to $vpcid. Exiting."
   exit 1
fi

aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpcid --subnet-ids $subnet3id >/dev/null 2>&1
if [ $? -gt 0 ]; then
   echo "The subnet $subnet3id does not belong to $vpcid. Exiting."
   exit 1
fi

aws ec2 describe-key-pairs --key-name $keypairname >/dev/null 2>&1
if [ $? -gt 0 ]; then
   echo "The KeyPair provided is not found. Exiting."
   exit 1
fi

echo $rgurl | grep -i -e '^http'
if [ $? -gt 0 ]; then
   echo "The URL $rgurl must begin with http. Exiting."
   exit 1
fi

aws elbv2 describe-target-groups --target-group-arns $tgarn > /dev/null
if [ $? -gt 0 ]; then
   echo "The Target Group ARN $tgarn does not exists. Exiting."
   exit 1
fi

function calculate_duration() {
   mylabel=$1
   mystarttime=$2
   myelapsedtime=$(( SECONDS - mystarttime ))
   eval "echo $mylabel Elapsed time: $(date -ud "@$myelapsedtime" +'$((%s/3600/24)) %M min %S sec')"
}

localhome=`pwd`
bucketstackname="RG-PortalStack-Bucket-$runid"
start_time=$SECONDS

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
  aws cloudformation deploy --template-file rg_deploy_bucket.yml --stack-name "$bucketstackname" \
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
s3_sync_start_time=$SECONDS
aws s3 sync s3://rg-deployment-docs s3://$bucketname
calculate_duration "S3 Sync" $s3_sync_start_time

#Create local folder to store RG Deployment Files and a subfolder for cft templates and scripts
mkdir -p "$localhome/rg-cft-templates"

#Download RG Deployment files from S3 to the local folder created above,
echo "Copying RG Deployment Files to local folder"
s3_copy_start_time=$SECONDS
aws s3 cp s3://rg-deployment-docs/ $localhome/rg-deployment-docs --recursive
calculate_duration "S3 Copy" $s3_copy_start_time

# Extract cft templates locally
echo "Extracting CFTs locally"
tar -xvf $localhome/rg-deployment-docs/rg-cft-templates.tar.gz -C $localhome/rg-cft-templates/

#Modify file rg_userpool.yml to refer new S3 bucket
sed -i -e "s/S3Bucket:.*/S3Bucket: $bucketname/" $localhome/rg_userpool.yml

#Copy extracted cft template to the new bucket
echo "Copying deployment files to new bucket"
aws s3 sync $localhome/rg-cft-templates/ s3://$bucketname

#Creating the Cognito User Pool
echo "Creating Cognito User Pool"
userpoolstackname="RG-PortalStack-UserPool-$runid"
aws cloudformation deploy --template-file $localhome/rg_userpool.yml \
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

#Create DocumentDB stack
docdb_start_time=$SECONDS
echo "Creating DocumentDB Stack for Research Gateway"
docdbstackname="RG-PortalStack-DocDB-$runid"
aws cloudformation deploy --template-file $localhome/rg_document_db.yml --stack-name "$docdbstackname" \
                          --parameter-overrides MasterUser="$appuser" MasterPassword="$appuserpassword" \
                            DBClusterName="RGCluster-$runid" DBInstanceName="RGInstance-$runid" DBInstanceClass="db.t3.medium" \
                            Subnet1="$subnet1id" Subnet2="$subnet2id" Subnet3="$subnet3id" VPC="$vpcid" \
                            SecurityGroupName="RGDB-SG-$runid" DocDBSubnetGroupName="RGDBSubnet-$runid"
echo "Waiting for stack $docdbstackname to finish deploying..."
aws cloudformation wait stack-create-complete --stack-name "$docdbstackname"

if [ $? -gt 0 ]; then
   echo " $docdbstackname Stack Failed to Create "
   exit 1
fi
calculate_duration "DocumentDB Instance Creation" $docdb_start_time

#Capture DocumentDB Instance Id
docdburl_id=$(aws cloudformation describe-stacks --stack-name $docdbstackname | jq -r '.Stacks[] | .Outputs[] | select(.OutputKey=="InstanceEndpoint")|.OutputValue')

#Creating Main stack
#update the AMI id in the RGMainStack CFT
echo $amiid | grep -E '^ami-[0-9a-zA-Z]+'
if [ $? -eq 0 ]; then
  echo "Valid AMI Id $amiid passed. Replacing in RGMainStack"
  sed -i -E "s/ami-[0-9a-zA-Z]+/$amiid/" $localhome/rg_main_stack.yml
fi

echo "Deploying main stack (roles, ec2 instance etc.)"
mainstack_start_time=$SECONDS
mainstackname="RG-PortalStack-$runid"
aws cloudformation deploy --template-file $localhome/rg_main_stack.yml \
                          --stack-name "$mainstackname" \
                          --parameter-overrides ClientId="$userpoolclient_id" UserPoolId="$userpool_id" \
                            CFTBucketName="$bucketname" RGUrl="$rgurl" UserPassword="$appuserpassword" AdminPassword="$adminpassword" \
                            VPC="$vpcid" Subnet1="$subnet1id" KeyName1="$keypairname" TGARN="$tgarn" \
                            DocumentDBInstanceURL="$docdburl_id" \
                          --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name "$mainstackname"
if [ $? -gt 0 ]; then
   echo " $mainstackname Stack Failed to Create "
   exit 1
else
   portalinstance_id=$(aws cloudformation describe-stack-resources --stack-name "$mainstackname" --logical-resource-id "RGEC2Instance" | jq -r '.StackResources[] | .PhysicalResourceId')
   echo "Research Gateway has been successfully deployed. You can access the EC2 instance using $portalinstance_id"
fi
calculate_duration "MainStack Creation" $mainstack_start_time
calculate_duration "Research Gateway Deployment" $start_time
