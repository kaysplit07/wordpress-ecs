# How I approached the test?

First of all, I have created terraform modules to provision the needed AWS infrastructure, such as VPC, ECS cluster, RDS, ECR, ECS Wordpress service and task. I then called the modules from the root module to provision the infrastructure.

When the infrastructure was finished, the Ecs service would continue to deploy a task that was set up to use the Docker image with latest tag from our ecr repository. However, because the Docker image had not yet been produced, the task would fail to launch and the service would continue to deploy a new task. This would continue until the docker image was created and uploaded to the ecr repository.

Now we have the infrastructure in place, we can build the docker image and push it to the ecr repository. I have used packer to build the docker image and push it to the ecr repository and also I have used ansible as the provisioner for packer to build the docker image Lastly I used the ansible role to install and configure Wordpress in the Docker image. This process is automated using a Makefile.

Once the docker image is built and pushed to the ecr repository, the ecs service would deploy a new task with the latest docker image and the wordpress site would be up and running.

# How did you run the project ?

1. Create or use existing IAM user with API access. If you don't have an AWS account yet, signup to AWS account and
   create a user with API access.

2. Install all dependencies packer,ansible , terraform, awscli and docker.

I have created a bash script t automate this process

```
chmod +x setup.sh
./setup.sh
```

3. Setup access and secrete key as env variable

```
export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
```

4. Check everything is ready :

```
packer version
terraform -v
ansible --version
aws --version
docker -v
```

5. Configure AWS environment variables with aws configure command:

```
aws configure
```

6. Deploy infrastructure with terraform :

```
$ cd terraform/
$ terraform init
$ terraform apply
```

7. setup ecr repository(command can be gotten from aws ecr console of the newly created repository)

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com
```

8. Setup up docker repository environment variable

```
export DOCKER_REPOSITORY=<repository_url>
```

9. Build Wordpress docker image in local :

```
$ cd ..
$ make build-local
```

# What are the component interacting with each other ?

-   Terraform is used to provision the infrastructure in AWS.
-   ECR is used to store images in AWS account and use it in ECS.
-   ECS is used to run containers in AWS as a service.
-   RDS is used to store data in AWS as a service.
-   VPC is used to isolate the infrastructure in AWS.
-   RDS has a security group to allow access to port 3306 from the ECS security group.
-   ECS has a security group to allow access to port 80 from the Internet.
-   Makefile is used to automate the build process of the image.
-   Packer is used to build the docker image and push it to the ECR registry.
-   In the packer template within the provisioners block, two scripts "install-ansible.sh" and "cleanup.sh" are used to install ansible and cleanup after the build specified in the same provisioner block.
-   Ansible with ansible role is used to install and configure Wordpress in the docker image.
-   Awscli is used to interact with AWS.

# What problems did you encounter ?

-   I had issues installing required tools for the whole test in my local machine. I had to use an Ec2 instance to run the test.
-   I encountered a problem when packer tries to deploy image to aws ecr repository. I had to use the aws ecr get-login-password command to get the password to login to the ecr repository.
-   I ran into a difficulty on how to dynamically get packer to know the ecr repository url. I had to use environment variable to pass the ecr repository url to packer.
-   I was unable to access the wordpress site from the internet after successfully pushing the image. I had to add a security group rule to the ecs task created to allow access to port 80 from the internet.

# How would you have done things to have the best HA/automated architecture ?

-   I could have used a pipeline to autommate the whole process.
-   I could have also used a Makefile to automate the whole process.
-   I would have rather created the docker image with a custom Dockerfile rather than using packer and ansible to build the image. This would save time and reduce the complexity of the project.

# Share with us any ideas you have in mind to improve this kind of infrastructure

-   Secrets and sensitive information can be managed using ansible vault or external secret management tools like hashicorp vault
