#!/bin/bash
version="0.1.5"
echo "Fixing configs...(fixconfig.sh v$version)"
# Ensure right number of params
if [ $# -lt 5 ]; then
    echo 'At least 5 parameters are required!'
    echo '  Param 1: AWS Cognito User Pool id'
    echo '  Param 2: AWS Cognito client id'
    echo '  Param 3: RG Bucket Name (The bucket where CFT templates are stored)'
    echo '  Param 4: App username'
    echo '  Param 5: App user password'
    echo '  Param 6: (Optional) URL to reach RG '
    echo '           e.g https://rg.example.com'
    echo '           Note that the protocol will be picked from this param!'
    exit 1
fi

myuserpoolid=$1
myclientid=$2
mys3bucket=$3
myappuser=$4
myapppwd=$5
myurl=$6

[ -z $RG_HOME ] && RG_HOME='/opt/deploy/sp2'
echo "RG_HOME=$RG_HOME"
[ -z $RG_SRC ] && RG_SRC='/home/ubuntu'
echo "RG_SRC=$RG_SRC"
[ -z $RG_ENV ] && RG_SRC='PROD'
echo "RG_ENV=$RG_ENV"

mypubip=$(wget -q -O - http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Public IP : $mypubip"
myip=$(wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4)
echo "Local IP : $myip"
region="$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/region)"
echo "Region : $region"
role_name="$(wget -q -O - http://169.254.169.254/latest/meta-data/iam/security-credentials/)"
echo "Role name : $role_name"
ac_name=$(wget -q -O - http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .accountId)
echo "Account number : $ac_name"
instanceid=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
echo "Instance-id : $instanceid"
if [ -z $myurl ]; then
    public_host_name="$(wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname)"
        [ -z $public_host_name ] && echo "No RG URL passed. Instance does not have public hostname. One of the two is required. Not modifying configs. Exiting!" && exit 1
    baseurl="http://$public_host_name/"
    snsprotocol="http"
else
    baseurl="$myurl/"
    snsprotocol=`echo $myurl | sed -e 's/\(http.*:\/\/\).*/\1/' | sed -e 's/://' -e 's/\///g'`
fi

if ! [ -d "$RG_HOME/tmp" ]; then
    echo "$RG_HOME/tmp does not exist. Creating"
    mkdir "$RG_HOME/tmp"
fi

if ! [ -d "$RG_HOME/config" ]; then
    echo "$RG_HOME/config does not exist. Creating"
    mkdir "$RG_HOME/config"
fi
mkdir -p "$RG_HOME/config"
if [ -z "$(ls -A $RG_HOME/config)"  ]; then
    echo "$RG_HOME/config is empty. Extracting templates"
    tar -xvf "$RG_SRC/config.tar.gz" -C "$RG_HOME"
    if [ -z "$(ls -A $RG_HOME/config)"  ]; then
        echo "FATAL: $RG_HOME/config is still empty. Exiting" 
        exit 1
    fi
fi
mytemp=`mktemp -d -p "${RG_HOME}/tmp" -t "config.old.XXX"`
echo "$mytemp"
cp "${RG_HOME}/config/bucket-policy.json" "$mytemp"
cp "${RG_HOME}/config/config.json" "$mytemp"
cp "${RG_HOME}/config/dashboard-settings.json" "$mytemp"
cp "${RG_HOME}/config/snsConfig.json" "$mytemp"
cp "${RG_HOME}/config/mongo-config.json" "$mytemp"
cp "${RG_HOME}/config/global-config.json" "$mytemp"
cp "${RG_HOME}/config/email-config.json" "$mytemp"
cp "${RG_HOME}/config/notification-config.json" "$mytemp"
cp "${RG_HOME}/config/trustPolicy.json" "$mytemp"

echo "Modifying bucket-policy.json"
cat "$mytemp/bucket-policy.json" |\
        jq -r ".Resource=\"arn:aws:s3:::$mys3bucket/*\""  > "${RG_HOME}/config/bucket-policy.json"
s3url="https://${mys3bucket}.s3.${region}.amazonaws.com"
echo "Modifying config.json"
cat "$mytemp/config.json" | jq -r ".baseURL=\"$baseurl\"" |\
        jq -r ".googleOAuthCredentials.callbackURL=\"$baseurl\"" |\
        jq -r ".baseAccountInstanceRoleName=\"$role_name\"" |\
        jq -r ".baseAccountPolicyName=\"RG-Portal-CrossAccount-Policy\"" |\
        jq -r ".baseAccountNumber=\"$ac_name\"" |\
        jq -r ".researchGatewayAPIToken=\"$instanceid\"" |\
        jq -r ".BucketName=\"$mys3bucket\"" |\
        jq -r ".cftTemplateURL=\"$s3url\"" |\
        jq -r ".AWSCognito.userPoolId=\"$myuserpoolid\"" |\
        jq -r ".AWSCognito.clientId=\"$myclientid\"" |\
        jq -r ".AWSCognito.region=\"$region\"" |\
        jq -r ".enableB2CMode=false" > "${RG_HOME}/config/config.json"
echo "Modifying dashboard-settings.json"
cat "$mytemp/dashboard-settings.json" |\
        jq -r ".redis.host=\"$myip\"" |\
        jq -r ".AWSCognito.userPoolId=\"$myuserpoolid\"" |\
        jq -r ".AWSCognito.clientId=\"$myclientid\"" |\
        jq -r ".AWSCognito.region=\"$region\"" > "${RG_HOME}/config/dashboard-settings.json"
echo "Modifying snsConfig.json"
cat "$mytemp/snsConfig.json" |\
        jq -r ".snsProtocol=\"$snsprotocol\"" > "${RG_HOME}/config/snsConfig.json"
echo "Modifying mongo-config.json"
cat "$mytemp/mongo-config.json" |\
        jq -r ".db_ssl_enable=true" |\
        jq -r ".db_ssl_config.CAFile=\"RL-CA.pem\"" |\
        jq -r ".db_ssl_config.PEMFile=\"mongodb.pem\"" |\
        jq -r ".db_auth_enable=true" |\
        jq -r ".db_documentdb_enable=false" |\
        jq -r ".db_auth_config.username=\"$myappuser\"" |\
        jq -r ".db_auth_config.password=\"$myapppwd\"" |\
        jq -r ".db_auth_config.authenticateDb=\"admin\"" > "${RG_HOME}/config/mongo-config.json"
echo "Modifying global-config.json"
cat "$mytemp/global-config.json" |\
        jq -r ".secureURL.PROD=\"$baseurl\"" |\
        jq -r ".linksForRg.termsAndConditions=\"$baseurl\"" > "${RG_HOME}/config/global-config.json"
echo "Modifying email-config.json"
cat "$mytemp/email-config.json" |\
        jq -r ".email.url=\"$baseurl:2687/bot/sns_notify_bot/exec\"" |\
        jq -r ".email.options.body.data.from=\"rlc.support@relevancelab.com\"" |\
        jq -r ".email.options.body.data.url=\"https://serviceone.rlcatalyst.com\"" > "${RG_HOME}/config/email-config.json"
echo "Modifying notification-config.json"
cat "$mytemp/notification-config.json" |\
        jq -r ".tokenID=[\"$instanceid\"]" > "${RG_HOME}/config/notification-config.json"
echo "Modifying trustPolicy.json"
cat "$mytemp/trustPolicy.json" |\
        jq -r ".trustPolicy.Statement[0].Principal.AWS=\"arn:aws:iam::$ac_name:role/$role_name\""  |\
        jq -r ".roleName=\"RG-Portal-ProjectRole-$RG_ENV\""  |\ 
        jq -r ".policyName=\"RG-Portal-ProjectPolicy-$RG_ENV\"" > "${RG_HOME}/config/trustPolicy.json"

# Fix the Mongo and Redis host addresses in the docker compose file.
repcmd='s#\${PWD}#'$RG_HOME'#'
cat "$RG_SRC/docker-compose.yml" | sed -e $repcmd > "$RG_HOME/docker-compose.yml"
cd $RG_HOME
if [ -f docker-compose.yml ]; then
	echo "docker-compose.yml exists"
	sed -i -e "s/DB_HOST.*/DB_HOST=$myip/" docker-compose.yml
	sed -i -e "s/REDIS_HOST.*/REDIS_HOST=$myip/" docker-compose.yml
	sed -i -e "s/APP_ENV.*/APP_ENV=$RG_ENV/" docker-compose.yml
	echo "Modified docker-compose.yml with private IP of the machine"
fi        
echo 'Configuration changed successfully'
