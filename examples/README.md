AWS CLI Example Script
======================

The example script uses the [aws cli](http://aws.amazon.com/cli) to set up an
[EC2](http://aws.amazon.com/ec2) instance that is accessible via HTTP(S) and SSH.

It is installed in the `examples` directory in the [fstab/aws-cli](https://github.com/fstab/docker-aws-cli) Docker image.

How To
------

The following commands should be run inside the [fstab/aws-cli](https://github.com/fstab/docker-aws-cli) Docker container.
When you run the script for the first time, you need to configure the [aws cli](http://aws.amazon.com/cli) with your AWS credentials:

    > aws configure 
    AWS Access Key ID [****************VSSQ]: 
    AWS Secret Access Key [****************UkAC]: 
    Default region name [eu-central-1]: 
    Default output format [None]: 

Then, start up the [EC2](http://aws.amazon.com/ec2) instance as follows:

    cd examples
    ./start.sh

When everything is up, the script will print the IP address for accessing the EC2 instance.

In order to clean everything up, run

    ./terminate.sh

What does it do?
----------------

Running an [EC2](http://aws.amazon.com/ec2) instance that is available on the Internet is a complex process requiring some preliminary steps:

  1. Create a [Virtual Private Cloud (VPC)](http://aws.amazon.com/vpc) where the instance should run in.
  2. Create a subnet within the VPC where the instance should be located.
  3. Create an Internet gateway that connects the VPC to the Internet.
  4. Update the routing tables to use the Internet gateway.
  5. Create an SSH key pair for remote login.

The `start.sh` script performs all these steps and starts an [EC2](http://aws.amazon.com/ec2) instance. The `terminate.sh` script deletes all resources that have been created with `start.sh`.
