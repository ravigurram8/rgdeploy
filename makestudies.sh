#!/bin/bash
while IFS=$'\n' read -r c; do
	if [ "$c" == "q" ]; then
		echo "$c" >&2
		exit 0
	fi
	echo "$c" | yq -o=json eval '.' "$c" |
		jq -r '{
            name: .Name,
            description: .Description,
            tags:.Tags,
            resourceDetails:(
                .Resources|map({
                    description: .Description,
                    arn: .ARN,
                    region: .Region,
                    type: (.Type|select(.=="S3 Bucket")| "s3")}
                    )
                ),
            moreInformation: (.License+"\n"+.Documentation+"\n"+.Contact),
            bookmarkedBy: [],
            projectId: [],
            levelOfSharing: 0,
            sharedTo: [],
            studyType: "Public",
            __v: 0,
            isDeleted: false,
            repositoryName: "Registry of Open Data on AWS",
            isShared: false,
            isLinked: false
        }'
done | jq -s
