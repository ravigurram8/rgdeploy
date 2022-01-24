#!/usr/bin/env bash

# This script bootstraps a workspace instance by preparing S3 study data to be
# mounted via the mount_s3.sh environment script.
# Note that mounting cannot be performed during initial bootstrapping
# because the instance's role will not yet have access to S3 study
# data since the associated resource policies aren't updated until after the
# CFN stack has been completed created.
S3_MOUNTS="$1"

# Exit if no S3 mounts were specified
[ -z "$S3_MOUNTS" -o "$S3_MOUNTS" = "[]" ] && exit 0

# Get directory in which this script is stored and define URL from which to download goofys
FILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GOOFYS_URL="https://github.com/kahing/goofys/releases/download/v0.21.0/goofys"

# Define a function to determine what type of environment this is (RStudio, or EC2 Linux)
env_type() {
    if [ -d "/var/log/rstudio-server" ]
    then
        printf "rstudio"
    elif [ -f "/usr/bin/nextflow" ]
    then
        printf "nextflow"
    else
        printf "ec2-linux"
    fi
}

# Install dependencies
yum install -y jq-1.5
curl -LSs -o "/usr/local/bin/goofys" "$GOOFYS_URL"
chmod +x "/usr/local/bin/goofys"

# Install ec2 instance connect agent
sudo yum install ec2-instance-connect-1.1

# Create S3 mount script and config file
chmod +x "${FILES_DIR}/bin/mount_s3.sh"
ln -s "${FILES_DIR}/bin/mount_s3.sh" "/usr/local/bin/mount_s3.sh"
printf "%s" "$S3_MOUNTS" > "/usr/local/etc/s3-mounts.json"

# Apply updates to environments based on environment type
case "$(env_type)" in
    "ec2-linux") # Add mount script to bash profile
        yum install -y fuse-2.9.2
        printf "\n# Mount S3 study data\nmount_s3.sh\n\n" >> "/home/ec2-user/.bash_profile"
        ;;
    "rstudio") # Add mount script to bash profile
        yum install -y fuse-2.9.2
        printf "\n# Mount S3 study data\nmount_s3.sh\n\n" >> "/home/ec2-user/.bash_profile"
        ;;
    "nextflow") # Add mount script to bash profile
        yum install -y fuse-2.9.2
        printf "\n# Mount S3 study data\nmount_s3.sh\n\n" >> "/home/ec2-user/.bash_profile"
        ;;
esac

exit 0
