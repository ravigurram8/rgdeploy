#!/bin/bash
if [ $# -lt 1 ]; then
  echo " Usage: updatessmpaths.sh <repo-dir> <aws-region>"
  echo "    Param 1: AWS Region where the Research Gateway is deployed e.g us-east-2"
  echo "    Param 2: (Optional) Full path to rgdeploy repo. e.g. /home/ubuntu/rgdeploy"
  exit 0
fi

region=$1
xtrargs="--region $region"

if [ $# -gt 1 ] && [ -d $1 ]; then
  DEPL_HOME=$2
else
  echo "Invalid folder $2 passed."
  DEPL_HOME=`pwd`
fi
echo "Using $DEPL_HOME as base folder"

jqcmd='.[] | [.ami_path, (.ami_id_list[] | select(.Key=='"\"$region\""')| .Value)] | @tsv'
a=($(cat "$DEPL_HOME/products/ami-list.json" | jq -r "$jqcmd" ))
set -- "${a[@]}"

#xtrargs=" --profile prod --region us-east-2"
ssm_param_paths=`aws ssm describe-parameters $xtraargs` 
while (($#))
do
  param_name=$1
  shift
  param_val=$1
  shift
  #echo "Param Name: $param_name"
  #echo "Param Value: $param_value"
  jqcmd=".Parameters[]|select(.Name==\"$param_name\")|.Name"
  #echo $jqcmd
  #echo "jq -r $jqcmd"
  path_exists=$(echo $ssm_param_paths | jq -r $jqcmd | wc -l)
  #echo "$path_exists path exists"
  if [ "$path_exists" == "0" ]; then
    echo "Path $param_name does not exist. Creating"
    echo "aws ssm put-parameter --name \"${param_name}\" --value \"${param_val}\""
    aws ssm put-parameter --name "${param_name}" --value "${param_val}" --type String $xtrargs
  else
    echo "Path $param_name exists. Deleting and recreating"
    echo "aws ssm delete-parameter --name \"$param_name\""
    aws ssm delete-parameter --name "$param_name" $xtrargs
    echo "aws ssm put-parameter --name \"${param_name}\" --value \"${param_val}\""
    aws ssm put-parameter --name "${param_name}" --value "${param_val}" --type String $xtrargs
  fi
  echo "-----------------------------------------------------------"
done
