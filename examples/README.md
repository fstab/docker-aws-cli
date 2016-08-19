AWS CLI Example Scripts
======================

The `examples/` directory contains some scripts illustrating the AWS CLI.

When you run the script for the first time, you need to configure the [aws cli](http://aws.amazon.com/cli) with your AWS credentials:

    > aws configure 
    AWS Access Key ID [****************VSSQ]: 
    AWS Secret Access Key [****************UkAC]: 
    Default region name [eu-central-1]: 
    Default output format [None]: 

start.sh / terminate.sh
-------------------------

The `start.sh` script uses the [aws cli](http://aws.amazon.com/cli) to set up an [EC2](http://aws.amazon.com/ec2) instance that is accessible via HTTP(S) and SSH:

  1. Create a [Virtual Private Cloud (VPC)](http://aws.amazon.com/vpc) where the instance should run in.
  2. Create a subnet within the VPC where the instance should be located.
  3. Create an Internet gateway that connects the VPC to the Internet.
  4. Update the routing tables to use the Internet gateway.
  5. Create an SSH key pair for remote login.

The `terminate.sh` script terminates the EC2 instance and deletes all resources that have been created with `start.sh`.

s3diff.sh / etag.sh
-------------------

`etag.sh` calculates ETags, which is something like MD5 sums for [AWS S3](http://aws.amazon.com/s3) files. When `etag.sh` is called with a local path as parameter, it calculates the expected ETag locally. When `etag.sh` is called with an S3 URL as parameter, it queries the ETag from S3.

`s3diff.sh` uses `etag.sh` to recursively compare ETags from an S3 directory with a local directory.

