#!/bin/bash
xtrargs='default'
if [ $# -gt 0 ]; then
	xtrargs="$1"
fi
function get_arn_for_pipeline() {
	pipeline="$1"
	jqcmd='.imagePipelineList | map(select(.name=='"\"$pipeline\""'))'
	aws imagebuilder list-image-pipelines --profile "$xtrargs" | jq -r "$jqcmd" | jq -r '.[0].arn'
}

function get_ami_list_for_pipeline() {
	pipeline_arn=$1
	[ -z "$pipeline" ] && return
	aws imagebuilder list-image-pipeline-images --image-pipeline-arn "$pipeline_arn" --profile "$xtrargs" |
		jq -r '.imageSummaryList' |
		jq -r 'map(select(.state.status=="AVAILABLE")|  .u=(.dateCreated[:16] | strptime("%Y-%m-%dT%H:%M") | mktime))' |
		jq -r 'sort_by(.u)| .[-1] | .outputResources.amis | map({(.|.region):(.|.image)})'
}

tmp="[]"
jq -c '.[]' img-builder-config.json |
	while IFS=$'\n' read -r c; do
		product=$(echo "$c" | jq -r '.product')
		pipeline=$(echo "$c" | jq -r '.pipeline')
		ami_path=$(echo "$c" | jq -r '.path')
		product_arn=$(get_arn_for_pipeline "$pipeline")
		amilist=$(get_ami_list_for_pipeline "$product_arn")
		jqcmd='.+=[{Name:'"\"$product\""',ami_id_list:'"$amilist"',ami_path:'"\"$ami_path\""'}]'
		tmp=$(echo "$tmp" | jq -r "$jqcmd")
		# trunk-ignore(shellcheck/SC2086)
		echo $tmp
	done | tail -1 | jq -r '{EventType: "UPDATE_AMI_ID", Products: (.)}'
