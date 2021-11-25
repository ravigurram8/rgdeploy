#!/bin/bash
if [ $# -gt 0 ] && [ -d $1 ]; then
  DEPL_HOME=$1
else
  DEPL_HOME=`pwd`
fi

a=($(cat "$DEPL_HOME/products/ami-list.json" | jq -r '.[] | [.ami_path, (.ami_id_list[] | select(.Key=="us-east-2")| .Value)] | @tsv' ))
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
