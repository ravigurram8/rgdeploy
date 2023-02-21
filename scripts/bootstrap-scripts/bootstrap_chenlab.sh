#!/usr/bin/env bash

# This script bootstraps a workspace instance by preparing S3 study data to be
# mounted via the mount_s3.sh environment script.
# Note that mounting cannot be performed during initial bootstrapping
# because the instance's role will not yet have access to S3 study
# data since the associated resource policies aren't updated until after the
# CFN stack has been completed created.
S3_MOUNTS="$1"

# Exit if no S3 mounts were specified
[ -z "$S3_MOUNTS" ] || [ "$S3_MOUNTS" = "[]" ] && exit 0

# Get directory in which this script is stored and define URL from which to download goofys
FILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
GOOFYS_URL="https://github.com/kahing/goofys/releases/download/v0.21.0/goofys"

# Install dependencies
apt-get install jq=1.6-1ubuntu0.20.04.1
curl -LSs -o "/usr/local/bin/goofys" "$GOOFYS_URL"
chmod +x "/usr/local/bin/goofys"

# Install ec2 instance connect agent
apt-get install ec2-instance-connect=1.1.12+dfsg1-0ubuntu3.20.04.1

# Create S3 mount script and config file
chmod +x "${FILES_DIR}/bin/mount_s3.sh"
ln -s "${FILES_DIR}/bin/mount_s3.sh" "/usr/local/bin/mount_s3.sh"
printf "%s" "$S3_MOUNTS" >"/usr/local/etc/s3-mounts.json"
apt-get install fuse=2.9.9-3
printf "\n# Mount S3 study data\nmount_s3.sh\n\n" >>"/home/ubuntu/.bash_profile"
printf "\nif [ -f /home/ubuntu/.bashrc ]; then\n\t.  /home/ubuntu/.bashrc\nfi " >>"/home/ubuntu/.bash_profile" 
printf 'export PATH=/usr/local/src/bowtie2-2.2.9:$PATH' >>"/home/ubuntu/.bashrc"
chown ubuntu:ubuntu /home/ubuntu/.bashrc
chown ubuntu:ubuntu /home/ubuntu/.bash_profile
exit 0
