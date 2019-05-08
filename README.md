
<!-- vim-markdown-toc GFM -->

* [Running locally](#running-locally)
    * [Testing](#testing)
    * [Cleaning](#cleaning)
* [Deploying on AWS](#deploying-on-aws)
    * [Architecture](#architecture)
    * [Deploying](#deploying)
    * [Finalizing](#finalizing)

<!-- vim-markdown-toc -->

# Running locally

- To run the application locally we can simply execute:

```bash
make up
```

(Use `make upd` if you don't want your terminal to be stuck on the container's output.)

- Wait a while for the services to start. After they are up and running check that we are accepting connections:

```bash
curl --head http://localhost:5000/
```

## Testing

- To run a simple validation that we can use the service and upload files as expected:

```bash
make local_test
```

This will output an URL that can be accessed locally with the file that was uploaded on the test.

(The tests are being executed by the `scripts/simple_validation.sh` script)

- To manually test the file upload process, execute

```bash
curl -F "file_to_upload=@path_to_a_file" http://localhost:5000/upload/
```

**NOTE:** All the steps mentioned above, from initialization to testing, can be automatically executed by simply running `make`

**NOTE2:** If you simply execute `make`, there is a chance that everything runs so fast that the required services will not be available yet. To fix it simply run `make` again. An example of this error is this:

```
An error occurred (502) when calling the CreateBucket operation (reached max retries: 4): Bad Gateway
Makefile:54: recipe for target 'local_test' failed
make: *** [local_test] Error 255
```

## Cleaning

To clean everything (including images and volumes), after you are done testing and developing, use:

```bash
make fresh
```

# Deploying on AWS

## Architecture

On AWS we have, on a high level point of view, the following architecture:

```
                             +-------------+
                        +--->| ECS Service |---+
                        |    +-------------+   |
         \    +-----+   |          .           |    -------------
Requests  --->| ALB |---+          .           +--> \ S3 Bucket /
         /    +-----+   |          .           |     -----------
                        |    +-------------+   |
                        +--->| ECS Service |---+
                             +-------------+
```

Requests come, from the internet, and hit the Application Load Balancer which
is responsible for distributing the connections to the ECS services that are
running, using AWS FARGATE.

## Deploying

**NOTE:** This process will create a new VPC and a new S3 Bucket. The VPC CIDRs are defined in `infrastructure/vpc.tf`, take a look to be sure that no collisions will happen with the current VPC you may have.

- To deploy the code into AWS the first step is to create all the required resources:

```bash
make infra-plan
make infra-create
# Answer the 'Are you sure?' question that terraform will ask
```

This whole process may take a while as some resources, take a reasonable amount of time to be created.

If you wait for the whole creation process to finish and try to test the application, it will fail. Basically because there is no published application (docker image) to run.

As we are running this application from a docker image, we need to publish this image into AWS ECR for it to be pulled into ECS.

- Take note of your AWS Account Number and use it on the command below:

```bash
# Change for your real AWS Account ID
AWS_ACCOUNT=123456789012 make publish
```

As noted on the `Makefile` this is not a process that humans should do. It should be done on the CI/CD service.

After the image publication it will take a while for the ECS service to pull it. Keep monitoring on the ECS Console.

**NOTE:** You can run the previous command as soon as the ECR Repository is created. There is no need to wait for the whole process.

- After the infrastructure is built and the image is published, we can test that everything is working on AWS:

```bash
export LOAD_BALANCER=$(cd infrastructure/ && ./all_outputs.sh 2>/dev/null | grep alb_dns_name | awk -F' = ' '{ print $2}')
scripts/remote_validation.sh
```

If you want to manually upload a file, use the `scripts/remote_validation.sh` as inspiration:

```bash
export LOAD_BALANCER=$(cd infrastructure/ && ./all_outputs.sh 2>/dev/null | grep alb_dns_name | awk -F' = ' '{ print $2}')
curl -F "file_to_upload=@full_path_of_the_file" "http://${LOAD_BALANCER}/upload/"
```

- If you want to live-follow log messages (they are stored on AWS CloudWatch), you can use [saw](https://github.com/TylerBrock/saw):

```bash
saw watch /ecs/s3_uploader/s3_uploader-task1
```

## Finalizing

After all the tests and validations one can destroy the spun up infrastructure:

```bash
make infra-destroy
# Answer the 'Are you sure?' question that terraform will ask
```

**NOTE:** Deleting the bucket may fail because it isnot empty. To fix it, delete all files from the bucket and execute `make infra-destroy` again.
