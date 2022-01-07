#!//bin/bash
xtrargs="--region us-east-2 --profile default"
# Array of products
products=(Nextflow_Advanced RStudio)

function get_arn_for_pipeline() {
  pipeline="$1"
  jqcmd='.imagePipelineList | map(select(.name=='"\"$pipeline\""'))'
  #echo $jqcmd
  myarn=`aws imagebuilder list-image-pipelines $xtrargs | jq -r "$jqcmd" | jq -r '.[0].arn'`
  echo $myarn 

}

function get_ami_list_for_pipeline() {
  pipeline_arn=$1
  jqcmd1='.imageSummaryList | map(select(.state.status=='"\"AVAILABLE\""')|  .u=(.dateCreated[:16] | strptime("%Y-%m-%dT%H:%M") | mktime)) | sort_by(.u)| .[-1]'
  echo $(aws imagebuilder list-image-pipeline-images --image-pipeline-arn "$pipeline_arn" |\
      jq -r "$jqcmd1")  | jq -r '.outputResources.amis | map({Key:(.|.region),Value:(.|.image)})|from_entries'

}

# set -- "${products[@]}"
# echo "["
# while (($#))
# do
#   product="$1"
#   echo "{"
#   echo "\"Name\": \"$product\","
#   echo "\"ami_id_list\":"
#   product_arn=$(get_images_for_product "$product")
#   jqcmd1='.imageSummaryList | map(select(.state.status=='"\"AVAILABLE\""')|  .u=(.dateCreated[:16] | strptime("%Y-%m-%dT%H:%M") | mktime)) | sort_by(.u)| .[-1]'
#   echo $(aws imagebuilder list-image-pipeline-images --image-pipeline-arn "$product_arn" |\
#       jq -r "$jqcmd1")  | jq -r '.outputResources.amis | map({Key:(.|.region),Value:(.|.image)})'
#   shift
#   echo ",\"ami_path\": \"\/RL\/RG\/StandardCatalog\/$product\""
#   echo "}"
#   if (($#))
#   then
#     echo ","
#   fi
# done
# echo "]"

img_builder_config=$(cat img-builder-config.json)
tmp="[]"
echo $img_builder_config | jq -c '.[]' |
while IFS=$"\n" read -r c; do
    product=$(echo "$c" | jq -r '.product')
    pipeline=$(echo "$c" | jq -r '.pipeline')
    ami_path=$(echo "$c" | jq -r '.path')
    product_arn=$(get_arn_for_pipeline "$pipeline")
    amilist=$(get_ami_list_for_pipeline "$product_arn")
    jqcmd='.+=[{Name:'"\"$product\""',ami_id_list:'"[$amilist]"',ami_path:'"\"$ami_path\""'}]'
    #echo $jqcmd
    tmp=$(echo $tmp | jq -r "$jqcmd")
    echo $tmp
    
done | tail -1 | jq -r

#get_images_for_product $1
