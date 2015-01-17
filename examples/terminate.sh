#!/bin/bash

set -e

export TAG_NAME="Created-By-Example-Script"

function get_ids {
    aws ec2 describe-tags --filters "Name=value,Values=$TAG_NAME" "Name=resource-type,Values=$1" \
    | python -c "import json, sys; data=json.load(sys.stdin); print ' '.join([tag['ResourceId'] for tag in data['Tags']])"
}

function json_get {
    python -c "import json, sys; data=json.load(sys.stdin); print data$1;"
}

function if_exists {
    IDs=$(get_ids $1)
    NUMBER_OF_IDs=$(echo "$IDs" | wc -w)
    if [[ $NUMBER_OF_IDs -ge 1 ]]
    then
        echo $2 $IDs
        $2 $IDs > /dev/null
    fi
}

if [ ! -e ~/.aws/credentials ]
then
    echo "AWS is not configured." >&2
    echo "Run 'aws configure' to set the aws credentials." >&2
    exit -1
fi

####################
# Terminate instance
####################

for INSTANCE_ID in $(get_ids instance)
do
    INSTANCE_STATE=shutting-down
    while [ "$INSTANCE_STATE" == "shutting-down" ]
    do
        DESCRIBE_RESULT=$(aws ec2 describe-instances --filter "Name=instance-id,Values=$INSTANCE_ID")
        INSTANCE_STATE=$(echo "$DESCRIBE_RESULT" | json_get "['Reservations'][0]['Instances'][0]['State']['Name']")
        echo "Instance $INSTANCE_ID is $INSTANCE_STATE"
        if [ "$INSTANCE_STATE" == "shutting-down" ]
        then
            sleep 5
        elif [ "$INSTANCE_STATE" != "terminated" ]
        then
            echo aws ec2 terminate-instances --instance-ids $INSTANCE_ID
            aws ec2 terminate-instances --instance-ids $INSTANCE_ID > /dev/null
            INSTANCE_STATE=shutting-down
        fi
    done
done

####################
# Delete SSH Key
####################

echo aws ec2 delete-key-pair --key-name "$TAG_NAME"
aws ec2 delete-key-pair --key-name "$TAG_NAME" > /dev/null 2>&1
rm -f "${TAG_NAME}.pem"

####################
# Delete VPC
####################

VPC_ID=$(get_ids vpc)
NUMBER_OF_VPCs=$(echo "$VPC_ID" | wc -w)
if [ $NUMBER_OF_VPCs -gt 1 ]
then
    echo "Error: More than one VPC with tag $TAG_NAME found." >&2
    exit -1
elif [ $NUMBER_OF_VPCs -eq 1 ]
then
    if_exists internet-gateway \
        "aws ec2 detach-internet-gateway --vpc-id $(get_ids vpc) --internet-gateway-id"

    if_exists internet-gateway \
        "aws ec2 delete-internet-gateway --internet-gateway-id"

    if_exists subnet \
        "aws ec2 delete-subnet --subnet-id"

    if_exists vpc \
        "aws ec2 delete-vpc --vpc-id"
fi
