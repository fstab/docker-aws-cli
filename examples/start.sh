#!/bin/bash

set -e

export TAG_NAME="Created-By-Example-Script"

function json_get {
    python -c "import json, sys; data=json.load(sys.stdin); print data$1;"
}

function tag {
    aws ec2 create-tags --tags "Key=Name,Value=$TAG_NAME" --resources "$1"
}

function get_ids {
    ALL_TAGS=$(aws ec2 describe-tags --filters "Name=value,Values=$TAG_NAME" "Name=resource-type,Values=$1")
    echo "$ALL_TAGS" | python -c "import json, sys; data=json.load(sys.stdin); print ' '.join([tag['ResourceId'] for tag in data['Tags']])"
}

function create_or_get {
    IDs=$(get_ids $1)
    NUMBER_OF_IDs=$(echo "$IDs" | wc -w)
    if [[ $NUMBER_OF_IDs -eq 0 ]]
    then
        result=$($3 | json_get "$2")
        tag "$result"
        echo "$result"
    elif [[ $NUMBER_OF_IDs -eq 1 ]]
    then
        echo $IDs
    else
        echo "Error: More than one $1 with tag $TAG_NAME found." 2>&1
        exit -1
    fi
}

if [ ! -e ~/.aws/credentials ]
then
    echo "AWS is not configured." >&2
    echo "Run 'aws configure' to set the aws credentials." >&2
    exit -1
fi

#########################################################################
echo -n "Creating VPC... "
#########################################################################

VPC_ID=$(create_or_get "vpc" "['Vpc']['VpcId']" \
    "aws ec2 create-vpc --cidr-block 10.0.0.0/24")

echo "$VPC_ID"

#########################################################################
echo -n "Creating subnet... "
#########################################################################

SUBNET_ID=$(create_or_get "subnet" "['Subnet']['SubnetId']" \
    "aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.0.0/24")

echo "$SUBNET_ID"

#########################################################################
echo -n "Configuring security group: Allowing SSH and HTTPS... "
#########################################################################

SECURITY_GROUP_JSON=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID")
SECURITY_GROUP_ID=$(echo "$SECURITY_GROUP_JSON" | json_get "['SecurityGroups'][0]['GroupId']")

tag "$SECURITY_GROUP_ID"

if [[ "$SECURITY_GROUP_JSON" != *"\"ToPort\": 22,"* ]]
then
    aws ec2 authorize-security-group-ingress \
        --group-id "$SECURITY_GROUP_ID" \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0
fi

if [[ "$SECURITY_GROUP_JSON" != *"\"ToPort\": 443,"* ]]
then
    aws ec2 authorize-security-group-ingress \
        --group-id "$SECURITY_GROUP_ID" \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0
fi

echo "$SECURITY_GROUP_ID"

#########################################################################
echo -n "Creating Internet gateway... "
#########################################################################

INTERNET_GATEWAY_ID=$(create_or_get "internet-gateway" "['InternetGateway']['InternetGatewayId']" \
    "aws ec2 create-internet-gateway")

echo "$INTERNET_GATEWAY_ID"

#########################################################################
echo -n "Attaching Internet gateway to VPC... "
#########################################################################

CURRENT_INTERNET_GATEWAY=$(aws ec2 describe-internet-gateways --internet-gateway-ids "$INTERNET_GATEWAY_ID")

if [[ "$CURRENT_INTERNET_GATEWAY" != *"\"VpcId\": \"$VPC_ID\""* ]]
then
    aws ec2 attach-internet-gateway \
        --internet-gateway-id "$INTERNET_GATEWAY_ID" \
        --vpc-id "$VPC_ID"
fi

echo done

#########################################################################
echo -n "Retreiving route table id... "
#########################################################################

ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
    --filter "Name=vpc-id,Values=$VPC_ID" \
    | json_get "['RouteTables'][0]['RouteTableId']")

tag "$ROUTE_TABLE_ID"
echo "$ROUTE_TABLE_ID"

#########################################################################
echo -n "Creating default route... "
#########################################################################

aws ec2 create-route \
    --route-table-id "$ROUTE_TABLE_ID" \
    --destination-cidr-block "0.0.0.0/0" \
    --gateway-id "$INTERNET_GATEWAY_ID"

echo done

#########################################################################
echo -n "Creating SSH key pair... "
#########################################################################

set +e

aws ec2 describe-key-pairs --key-name "$TAG_NAME" > /dev/null 2>&1
if [ $? -ne 0 ]
then
    aws ec2 create-key-pair --key-name "$TAG_NAME" | json_get "['KeyMaterial']" > "${TAG_NAME}.pem"
    chmod 400 "${TAG_NAME}.pem"
fi

set -e

echo done

#########################################################################
echo -n "Creating EC2 instance... "
#########################################################################

ALL_IDs=$(get_ids instance)
NON_TERMINATED=()

for INSTANCE_ID in $ALL_IDs
do
    DESCRIBE_RESULT=$(aws ec2 describe-instances --filter "Name=instance-id,Values=$INSTANCE_ID")
    if [[ $DESCRIBE_RESULT == *"\"InstanceId\": \"$INSTANCE_ID\""* ]]
    then
        INSTANCE_STATE=$(echo "$DESCRIBE_RESULT" | json_get "['Reservations'][0]['Instances'][0]['State']['Name']")
        if [ $INSTANCE_STATE != "terminated" ] && [ $INSTANCE_STATE != "shutting-down" ]
        then
            NON_TERMINATED+=($INSTANCE_ID)
        fi
    fi
done

NUMBER_OF_NON_TERMINATED=${#NON_TERMINATED[@]}

if [[ $NUMBER_OF_NON_TERMINATED -eq 0 ]]
then
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-b43503a9 \
        --count 1 \
        --instance-type t2.micro \
        --instance-initiated-shutdown-behavior terminate \
        --subnet-id $SUBNET_ID \
        --security-group-ids $SECURITY_GROUP_ID \
        --associate-public-ip-address \
        --key-name "$TAG_NAME" \
        | json_get "['Instances'][0]['InstanceId']")
    tag "$INSTANCE_ID"
elif [[ $NUMBER_OF_NON_TERMINATED -eq 1 ]]
then
    INSTANCE_ID=${NON_TERMINATED[0]}
else
    echo "Error: More than one instance with tag $TAG_NAME found." 2>&1
    exit -1
fi

echo "$INSTANCE_ID"

#########################################################################
echo "Waiting for instance. This may take a few minutes... "
#########################################################################

INSTANCE_STATE="pending"

while [ "$INSTANCE_STATE" == "pending" ]
do
    DESCRIBE_RESULT=$(aws ec2 describe-instances --filter "Name=instance-id,Values=$INSTANCE_ID")
    INSTANCE_STATE=$(echo "$DESCRIBE_RESULT" | json_get "['Reservations'][0]['Instances'][0]['State']['Name']")
    echo "... state is $INSTANCE_STATE."
    if [[ "$INSTANCE_STATE" == "pending" ]]
    then
        sleep 5
    fi
done

PUBLIC_IP=$(echo "$DESCRIBE_RESULT" | json_get "['Reservations'][0]['Instances'][0]['PublicIpAddress']")

echo Started EC2 instance with IP address "$PUBLIC_IP"
if [ -e "${TAG_NAME}.pem" ]
then
    echo "As soon as the SSH daemon is started, you can log in with 'ssh -i ${TAG_NAME}.pem ec2-user@${PUBLIC_IP}'."
    echo "It will take a few minutes until the SSH daemon is started."
fi
