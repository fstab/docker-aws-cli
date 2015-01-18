docker-aws-cli
==============

[Docker](https://docker.io) image for running the [Amazon Web Services Command Line Interface](http://aws.amazon.com/cli/).

Background
----------

The `aws` command is a command line interface for [Amazon's Web Services](http://aws.amazon.com),
like [EC2](http://aws.amazon.com/ec2), [S3](http://aws.amazon.com/s3/), etc.

The _docker-aws-cli_ creates a [Docker](https://docker.io) image containing all dependencies needed to run `aws`. That way, you can run `aws` in a [Docker](https://docker.io) container without setting the `aws` dependencies on the host system.

Build and Run
-------------

1. Make sure [Docker](https://www.docker.com) is installed.
3. Clone _docker-aws-cli_ from [GitHub](https://github.com/fstab/docker-aws-cli)

   ```bash
   git clone https://github.com/fstab/docker-aws-cli.git
   ```
4. Build the docker image

   ```bash
   cd docker-aws-cli
   docker build -t="fstab/aws-cli:v1" .
   ```

5. Run a docker container with that image

   ```bash
   docker run -t -i fstab/aws-cli:v1
   ```

The container will start a `bash` shell with the [aws](http://docs.aws.amazon.com/cli/latest/reference/) command ready to use.

Getting started with the AWS CLI
--------------------------------

In the `examples` directory in the Docker container,
you find a `start.sh` script that can be used to start your first [EC2](http://aws.amazon.com/ec2) instance.
See [examples](examples) for more info.

For documentation on the AWS CLI, see the [AWS command line interface documentation](http://aws.amazon.com/documentation/cli/) and the [aws-cli GitHub page](https://github.com/aws/aws-cli).
