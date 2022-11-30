#!/bin/bash
launcherstackname=${12}
Region=$2
trap '/opt/aws/bin/cfn-signal --exit-code 1 --resource EC2Instance --region ${Region} --stack ${launcherstackname}' ERR
function wait_stack_create() {
    CLUSTER_STACK_NAME=$1
    LAUNCHER_STACK_NAME=$2
    REGION=$3
    echo "Waiting for [$CLUSTER_STACK_NAME] stack creation."
    aws cloudformation wait stack-create-complete --region ${REGION} --stack-name ${CLUSTER_STACK_NAME}
    status=$?
    if [[ ${status} -ne 0 ]] ; then
        # Waiter encountered a failure state.
        echo "Stack [${CLUSTER_STACK_NAME}] creation failed. AWS error code is ${status}."
        /opt/aws/bin/cfn-signal --exit-code 1 --resource EC2Instance --region ${REGION} --stack ${LAUNCHER_STACK_NAME}
        exit 1  
    fi
}
source ~/apc-ve/bin/activate
echo "Activated Virtual Environment"
echo "Retrieving Tags from Running Instance"
INSTANCE_ID=`wget -qO- http://instance-data/latest/meta-data/instance-id`
IFS='-' read -ra TRIMMED <<< "$INSTANCE_ID"
CLUSTER_NAME=RG-Pcluster-${TRIMMED[1]}
REGION=`wget -qO- http://instance-data/latest/meta-data/placement/availability-zone | sed 's/.$//'`
aws ec2 describe-tags --region $REGION --filter "Name=resource-id,Values=$INSTANCE_ID" --query 'Tags[*].{Key:Key,Value:Value}' | jq -r '.[] | select( .Key as $a | ["cost_resource", "project_name","researcher_name"] | index($a) )' >> out.json
jq -s '.' out.json >> valid.json
echo "valid.json file is updated with Tags"
yq eval -P valid.json > valid.yaml
echo "Json file is converted to yaml"
sed -i '1 i\Tags:' valid.yaml
scheduler=$1
Region=$2
headnodeinstancetype=$3
headnodesubnetId=$4
keyname=$5
computenodeinstancetype=$6
minvpc=$7
maxvpc=$8
computenodesubnetId=$9
desiredvpc=${10}
spotbid=${11}
CustomAMI=${13}
FileSystemId=${14}
QueueCapacityType=${15}
disableSimultaneousMultithreading=${16}
efa=${17}
placementGroup=${18}
FileSystemType=${19}

IFS='-' read -ra TRIMMED <<< "$CustomAMI"
CustomAMIStartsWith=${TRIMMED[0]}
if [ "$scheduler" == "slurm" ]; then
       echo "slurm.yaml exists"
       if [ "$CustomAMIStartsWith" == "ami" ]; then
          yq -i ".Image.CustomAmi=\"$CustomAMI\"" slurm.yaml
       fi
       if [ "$FileSystemType" == "FSxForLustre" ] && [ "$FileSystemId" != "default" ]; then
          echo "Mounting $FileSystemId FSxForLustre filesystem to headnode"
          yq -i '.SharedStorage=[{"MountDir": "/fsx", "Name":"RG_Fsx_Filesysytem", "StorageType": "FsxLustre", "FsxLustreSettings":{"FileSystemId":"'$FileSystemId'"}}]' slurm.yaml
       fi
       if [ "$FileSystemType" == "EFS" ] && [ "$FileSystemId" != "default" ]; then
          echo "Mounting $FileSystemId EFS filesystem to headnode"
          yq -i '.SharedStorage=[{"MountDir": "/efs", "Name":"RG_Efs_Filesysytem", "StorageType": "Efs", "EfsSettings":{"FileSystemId":"'$FileSystemId'"}}]' slurm.yaml
       fi
       yq -i ".Region=\"$Region\"" slurm.yaml
       yq -i ".HeadNode.InstanceType=\"$headnodeinstancetype\"" slurm.yaml
       yq -i ".HeadNode.Networking.SubnetId=\"$headnodesubnetId\"" slurm.yaml
       yq -i ".HeadNode.Ssh.KeyName=\"$keyname\"" slurm.yaml
       yq -i ".Scheduling.SlurmQueues[0].CapacityType=\"$QueueCapacityType\"" slurm.yaml
       yq -i ".Scheduling.SlurmQueues[0].ComputeResources[0].InstanceType=\"$computenodeinstancetype\"" slurm.yaml
       yq -i ".Scheduling.SlurmQueues[0].ComputeResources[0].MinCount=\"$minvpc\"" slurm.yaml
       yq -i ".Scheduling.SlurmQueues[0].ComputeResources[0].MaxCount=\"$maxvpc\"" slurm.yaml
       yq -i ".Scheduling.SlurmQueues[0].ComputeResources[0].DisableSimultaneousMultithreading=\"$disableSimultaneousMultithreading\"" slurm.yaml
       yq -i ".Scheduling.SlurmQueues[0].ComputeResources[0].Efa.Enabled=\"$efa\"" slurm.yaml
       yq -i ".Scheduling.SlurmQueues[0].Networking.PlacementGroup.Enabled=\"$placementGroup\"" slurm.yaml
       yq -i ".Scheduling.SlurmQueues[0].Networking.SubnetIds[0]=\"$computenodesubnetId\"" slurm.yaml
       sed -i 's/\"//g' slurm.yaml
       yq eval-all "select(fileIndex == 1) *+ select(fileIndex == 0)" valid.yaml slurm.yaml >> cluster-config-slurm.yaml
       echo "valid.yaml file and cluster-config.yaml file is merged into cluster-config-slurm.yaml"
       echo "Modified cluster-config-slurm.yaml with Tags"
       pcluster create-cluster --cluster-name $CLUSTER_NAME --cluster-configuration cluster-config-slurm.yaml
else
       echo "batch.yaml exists"
        if [ "$CustomAMIStartsWith" == "ami" ]; then
            yq -i ".Image.CustomAmi=\"$CustomAMI\"" batch.yaml
       fi
       if [ "$FileSystemType" == "EFS" ] && [ "$FileSystemId" != "default" ]; then
          echo "Mounting $FileSystemId EFS filesystem to headnode"
          yq -i '.SharedStorage=[{"MountDir": "/efs", "Name":"RG_Efs_Filesysytem", "StorageType": "Efs", "EfsSettings":{"FileSystemId":"'$FileSystemId'"}}]' batch.yaml
       fi
       yq -i ".Region=\"$Region\"" batch.yaml
       yq -i ".HeadNode.InstanceType=\"$headnodeinstancetype\"" batch.yaml
       yq -i ".HeadNode.Networking.SubnetId=\"$headnodesubnetId\"" batch.yaml
       yq -i ".HeadNode.Ssh.KeyName=\"$keyname\"" batch.yaml
       yq -i ".Scheduling.AwsBatchQueues[0].CapacityType=\"$QueueCapacityType\"" batch.yaml
       yq -i ".Scheduling.AwsBatchQueues[0].ComputeResources[0].InstanceTypes[0]=\"$computenodeinstancetype\"" batch.yaml
       yq -i ".Scheduling.AwsBatchQueues[0].ComputeResources[0].MinvCpus=\"$minvpc\"" batch.yaml
       yq -i ".Scheduling.AwsBatchQueues[0].ComputeResources[0].MaxvCpus=\"$maxvpc\"" batch.yaml
       yq -i ".Scheduling.AwsBatchQueues[0].ComputeResources[0].DesiredvCpus=\"$desiredvpc\"" batch.yaml
       yq -i ".Scheduling.AwsBatchQueues[0].ComputeResources[0].SpotBidPercentage=\"$spotbid\"" batch.yaml
       yq -i ".Scheduling.AwsBatchQueues[0].Networking.SubnetIds[0]=\"$computenodesubnetId\"" batch.yaml
       sed -i 's/\"//g' batch.yaml
       yq eval-all "select(fileIndex == 1) *+ select(fileIndex == 0)" valid.yaml batch.yaml >> cluster-config-batch.yaml
       echo "valid.yaml file and cluster-config.yaml file is merged into cluster-config-batch.yaml"
       echo "Modified cluster-config-batch.yaml with Tags"
       pcluster create-cluster --cluster-name $CLUSTER_NAME --cluster-configuration cluster-config-batch.yaml
       
fi

wait_stack_create $CLUSTER_NAME $launcherstackname $REGION
HEAD_INSTANCE_ID=`pcluster describe-cluster -n $CLUSTER_NAME -r $REGION --query headNode | jq -r '.instanceId'`
# PRIVATE_IP_ADDRESS=`pcluster describe-cluster -n $1 --query headNode.privateIpAddress`
PARAMETER_NAME="/rg/pcluster/headnode-instance-id/${CLUSTER_NAME}"
aws ssm put-parameter --name "${PARAMETER_NAME}" --type "String" --value "${HEAD_INSTANCE_ID}" --region $REGION --overwrite
echo "Instance id of the head node is stored on ${PARAMETER_NAME}"
echo "Instance id is : ${HEAD_INSTANCE_ID}"
