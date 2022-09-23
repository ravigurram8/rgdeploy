### Creating the AMI with pre-requisites

You can create the AMI with pre-requisites yourself by following these steps:

- [Install packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)
- Export AWS Access Keys and Secret Keys
   
      export AWS_ACCESS_KEY_ID="your_Access_Key"
      export AWS_SECRET_ACCESS_KEY="your_Secret_Key"
      export AWS_DEFAULT_REGION="Your_Region"

- Clone this repo on a machine.
- Target Account number must be added in Admin Account-ECR and give permission to access image builds
- Create a Role and attach a policy which permits ECR and EC2 actions and Replace the "iam-instance_profile" :"<your_rolename>" in builders section which is in the packer-rg.json.
- Run packer build packer-rg.json
    
      packer build -var 'awsRegion=your_region' -var 'vpcId=your_VPCID' -var 'subnetId=your_SubnetID' packer-rg.json
- At Run time pass VPCID, SubnetID, AWSRegion as variables declared in packer-rg.json
- Note that AMI id from the output