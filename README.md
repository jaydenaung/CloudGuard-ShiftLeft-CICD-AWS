# CloudGuard integration with CICD pipeline on AWS using CodePipeline

Docker images 

In this tutorial, I'll do a step-by-step walk-through of integrating CloudGuard SHIFTLEFT into your CICD PipeLine on AWS. The integration will happen at the build stage. C

This Github repo contains source code (zip) of a sample docker image.

# Pre-requisites
 You need the following tools on your computer:

* AWS CLI [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html).
* Docker


Note: This is an **ALL-AWS** tutorial which means we'll be using CICD services provided by **AWS ONLY**. However, CloudGuard can be integrated with any other automation tools that can create CICD pipeline.

### AWS and CloudGuard 

* AWS Account
* Access to Check Point Infinity portal (For now, the scan result can be viewed only on Infinity portal. Hopefully, we'll make it available on CloudGuard console soon.)


* CodeCommit
* CodeBuild
* CodeDeploy
* [CodePipeline](#CodePipeline)

The roles will be created as part of creating a codepipeline. Please take note that the role used by codebulid requires permission to access to a number of AWS resources such as S3. 

# What exactly we will be doing

In this tutorial, we'll be doing the followings;

1. Create AWS ECR repo \
(Yes if you'd like to follow along my ALL-AWS tutorial, you'll need to create a ECR repo which will store the docker image.)
2. Create a CodeCommit Repo
3. Create a Codebuild Project
4. Test the Codebuild with SHIFTLEFT
5. Create CodePipeline
6. Test Your CodePipeline - Observe that any change in the codecommit repo will trigger the pipeline, and in the build stage, CloudGuard will be enabled and integrated to the serverless application


## 1. Create a ECR Repository
First you'll need to create a ECR on AWS. Your docker image (after build stage) will be stored in the ECR repo.

You can create the ECR repo on AWS web console or you can just execute the following command.

```bash
aws ecr create-repository --repository-name project-a/Your-App
```

## 2. Createa CodeCommit Repository

Then you'll need to create a CodeCommit on AWS. We need the CodeCommit repo to store the "source" files that we will build into a docker image. 

 You can do it on AWS web console or you can just execute the following command.

```bash
aws codecommit create-repository --repository-name my-docker-repo --repository-description "My Docker Repo"
```

Then you'll need to do 'git clone your codepipline reop' via either SSH or HTTP.  It'll be an empty repository first. Then you will need to download the source files (zip) into your local repo [here](https://github.com/jaydenaung/CloudGuard-ShiftLeft-CICD-AWS/blob/main/src.zip) 

- Unzip the source files. You'll need to **make sure that "src" folder and Dockerfile are in the same root directory**.
- Remove the zip file 
- Download the buildspec.yml 

**So in your CodeCommit local dirctory, you should have the following folder and files**.

1. src (directory where source codes are)
2. Dockerfile
3. buildspec.yml (This file isn't need for Docker image however, it is required to CodeBuild)

- Then you'll need to do `git init`, `git add -A`, `git commit -m "Your message"` and `git push`
- All the above files should now be uploaded to your CodeCommit repo.


``` 
### CLOUDGUARD API KEY AND SECRET

SHIFTLEFT requires CloudGuard's API key and API secrets. In build stage, we'll need to export it in buildspec.yml. You can generate CloudGuard API key and API secrets on CloudGuard console. 

### S3 Bucket
You'll also need to create an S3 bucket to store a vulnerability scan result.

```bash
aws s3 mb s3://Your-Bucket-Name
```


## [buildspec.yml](https://github.com/jaydenaung/CloudGuard-ShiftLeft-CICD-AWS/blob/main/buildspec.yml)

Buildspec.yml instructs CodeBuild in build stage in terms of what to do - things like adding Proact and FSP to the function. So this an important configuration file. In the buildspec.yml, replace the following values with your own values (without []):

1. AWS_REGION=[Your REGION]
2. S3_BUCKET=[YOUR BUCKET NAME]
3. cloudguard fsp -c [The ARN of Your Cloudformation stack you just took note of]

```
version: 0.2

phases:
  install:
    commands:
      # Install all dependencies (including dependencies for running tests)
      - npm install
      - pip install --upgrade awscli
  pre_build:
    commands:
      ## Not required 
  build:
    commands:
      - echo Build started on `date`
      - npm install -g https://artifactory.app.protego.io/cloudguard-serverless-plugin.tgz
      # Set your AWS region variable
      - export AWS_REGION=ap-southeast-1
      # Configure the CloudGuard Workload Proact security on the SAM template
      - echo Enabling Proact
      - cloudguard proact -m template.yml
      # Set the S3 bucket name variable
      - export S3_BUCKET=YOUR-BUCKET-NAME
      # Use AWS SAM to package the application by using AWS CloudFormation
      - echo Enabling FSP
      - aws cloudformation package --template template.yml --s3-bucket $S3_BUCKET --output-template template-export.yml
      # Add the Function Runtime Protection (Or Function Self Protection) to your function. You need to replace cloudformation stack arn with the one you've deployed!
      - cloudguard fsp -c arn:aws:cloudformation:YOUR-CFT-STACK-ARN
artifacts:
  type: zip
  files:
    - template-export.yml
```

## 3. Create a CodePipeline

It is time to create your CICD pipeline on AWS. Now if you're like me who likes to do things using CLI, you can create a CodePipeline and a CodeBuild project in just two command lines. You will need to just edit "codebuild-create-project.json" and "my-pipeline.json" which you can find in this repo, replace the values with your own values, and execute the following CLI.

* Create a CodeBuild Project

```bash
aws codebuild create-project --cli-input-json file://codebuild-create-project.json
```

* Create CodePipeline 

```bash
aws codepipeline create-pipeline --cli-input-json file://my-pipeline.json
```

Otherwise, please follow the step-by-step guide to create a CodePipeline.

### CodePipeline

Let's create your CICD Pipeline on AWS console!

1. Go to "CodePipeline" on AWS console
2. Create Pipeline
3. Enter your pipeline's name
4. If you already have an existing role, choose it. Otherwise, create a new role.

![header image](img/1-codepipeline-initial.png) 

### CodePipeline - Source Stage
Then we can add source - which is CodeCommit in this tutorial. You can add any source (e.g. Github)

1. Choose "CodeCommit" (You can use Github or any code repo. If you're following along my tutorial, choose CodeCommit.)
2. Choose Repository name - the CodeCommit repo that you've created earlier.
3. Choose Master Branch
4. For change detection, Choose "CloudWatch Events".

![header image](img/2-codepipeline-source.png) 

### CodePipeline - Build Stage
This is the build stage and it's important. We need to first configure the build environment.

1. Choose "CodeBuild" & choose your region.
2. If you don't already have a codebuild project, choose "Create Project".


![header image](img/3-codepipeline-build.png) 

In CodeBuild windows, do the following;

1. Enter your project name
2. Choose "Managed Image" and "Ubuntu" as Operating system

![header image](img/4-codepipeline-build-1.png) 

3. Choose "Standard" & "Standard:3.0" (It's totally up to you to choose actually. But this setting works for Nodejs 12.x apps)
4. Check "Privileged ...." checkbox
5. Choose an existing role or create a new service role.


> Now, please take note that codebuild role requires permissions to access a number of AWS services including Lambda, Cloudformation template and IAM. You will encounter issues while CodeBuild is building the app.


![header image](img/5-codepipeline-build-2.png) 

### CodePipeline - Deploy Stage 

In Deploy stage, we'll have to do the following;

1. Choose "Cloudformation" as Deploy Provider 
2. Choose your region
3. Action mode: "Create or update a stack" (You can also use ChangeSet)
4. Stack Name: **Choose the CFT Stack that you've created for your Lambda function**
5. As for Artifacts, Enter "result.txt".

![header image](img/6-codepipeline-deploy.png) 

![header image](img/7-codepipeline-deploy-2.png) 

Now, your CodePipeline has been created! Once a pipeline is created, any change in your source code in AWS CodeCommit will trigger the pipeline process. In build stage, CloudGuard will protect the serverless application by enabling Proact, and FSP which will be added to the Lambda function as a layer. The code will be scanned for vulnerabilities and embedded credentials by Proact first, and then FSP will be enabled on the function for runtime protection. This process will happen every time a codepipline update is triggered. 

## 5. Test your CodePipeline - Release Change

Now that you've successfully created your CICD pipeline, any change to the Lambda code will trigger the pipeline at this point. So let's make some changes and monitor what happens. You can observe the "Build" stage and see that Proact and FSP have been enabled on the function.


In your local CodeCommit repo, make **any change.** 

- Then, commit and push it again. This will trigger the pipeline change. Then observe the activities on Pipeline on the AWS Console.

![header image](img/codepipeline-status.png)

### CodeBuild Output

Below is the logs from Codebuild not everything just an excerpt from it - towards the end of the build.

```bash
See any operating system documentation about shared libraries for
more information, such as the ld(1) and ld.so(8) manual pages.
----------------------------------------------------------------------

Build complete.
Don't forget to run 'make test'.

Installing shared extensions:     /usr/local/lib/php/extensions/no-debug-non-zts-20160303/
Installing header files:          /usr/local/include/php/

warning: mbstring (mbstring.so) is already loaded!

find . -name \*.gcno -o -name \*.gcda | xargs rm -f
find . -name \*.lo -o -name \*.o | xargs rm -f
find . -name \*.la -o -name \*.a | xargs rm -f
find . -name \*.so | xargs rm -f
find . -name .libs -a -type d|xargs rm -rf
rm -f libphp.la       modules/* libs/*
Removing intermediate container c9800506bba3
 ---> ecb661b8e7c5
Step 12/14 : RUN a2enmod rewrite
 ---> Running in aace68afc4f0
Enabling module rewrite.
To activate the new configuration, you need to run:
  service apache2 restart
Removing intermediate container aace68afc4f0
 ---> e04362b2faaf
Step 13/14 : RUN a2enmod ssl
 ---> Running in dabd18966a41
Considering dependency setenvif for ssl:
Module setenvif already enabled
Considering dependency mime for ssl:
Module mime already enabled
Considering dependency socache_shmcb for ssl:
Enabling module socache_shmcb.
Enabling module ssl.
See /usr/share/doc/apache2/README.Debian.gz on how to configure SSL and create self-signed certificates.
To activate the new configuration, you need to run:
  service apache2 restart
Removing intermediate container dabd18966a41
 ---> 35cad561b896
Step 14/14 : RUN service apache2 restart
 ---> Running in 867053eb27be
Restarting Apache httpd web server: apache2AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.18.0.2. Set the 'ServerName' directive globally to suppress this message

Removing intermediate container 867053eb27be
 ---> 7fdfbf48c822
Successfully built 7fdfbf48c822
Successfully tagged cyberave-docker:latest

[Container] 2020/10/09 08:12:08 Running command docker tag cyberave-docker:latest 116489363094.dkr.ecr.ap-southeast-1.amazonaws.com/cyberave-docker:latest

[Container] 2020/10/09 08:12:08 Running command echo Saving Docker image
Saving Docker image

[Container] 2020/10/09 08:12:08 Running command docker save cyberave-docker -o cyberave-docker.tar

[Container] 2020/10/09 08:12:14 Running command echo Starting scan at `date`
Starting scan at Fri Oct 9 08:12:14 UTC 2020

[Container] 2020/10/09 08:12:14 Running command ./shiftleft image-scan -i cyberave-docker.tar > result.txt || if [ "$?" = "6" ]; then exit 0; fi
INFO   [09-10-2020 08:12:17.476] blade image-scan updated (0.0.130)           
INFO   [09-10-2020 08:12:17.594] SourceGuard Scan Started!                    
INFO   [09-10-2020 08:12:19.471] Project name: cyberave-docker path: /tmp/SourceGuard247824249 
INFO   [09-10-2020 08:12:19.471] Scan ID: 35cad561b8968f02ac5a2e0cb05b1b2fb417b756376dc04164ec5958908d23d8-SvBL8P 
INFO   [09-10-2020 08:12:31.647] Scanning ...                                 
INFO   [09-10-2020 08:12:48.892] Analyzing ...                                

[Container] 2020/10/09 08:14:25 Phase complete: BUILD State: SUCCEEDED
[Container] 2020/10/09 08:14:25 Phase context status code:  Message: 
[Container] 2020/10/09 08:14:25 Entering phase POST_BUILD
[Container] 2020/10/09 08:14:25 Running command echo Build completed on `date`
Build completed on Fri Oct 9 08:14:25 UTC 2020

[Container] 2020/10/09 08:14:25 Running command echo Pushing image to repo
Pushing image to repo

[Container] 2020/10/09 08:14:25 Running command docker push 116489363094.dkr.ecr.ap-southeast-1.amazonaws.com/cyberave-docker:latest
The push refers to repository [116489363094.dkr.ecr.ap-southeast-1.amazonaws.com/cyberave-docker]
98d3c49f13ab: Preparing
96fd7149e6a8: Preparing
5c008103b520: Preparing
897144f6e2ff: Preparing
eac34fee20ac: Preparing
c34869bde755: Preparing
bd51b78ec5a5: Preparing
ae9ead4be184: Preparing
36a33866c585: Preparing
4c4801c52898: Preparing
9a078a1d1b01: Preparing
a42cb226a41b: Preparing
0d678d51888b: Preparing
0817436a8f49: Preparing
3385a426f542: Preparing
35c986c7de74: Preparing
53bab0663330: Preparing
606c36b65880: Preparing
ab99fcc1a184: Preparing
9691e5d7a4c7: Preparing
6a4d393f0795: Preparing
e38834ac7561: Preparing
ec64f555d498: Preparing
840f3f414cf6: Preparing
17fce12edef0: Preparing
831c5620387f: Preparing
c34869bde755: Waiting
bd51b78ec5a5: Waiting
ae9ead4be184: Waiting
36a33866c585: Waiting
4c4801c52898: Waiting
9a078a1d1b01: Waiting
a42cb226a41b: Waiting
0d678d51888b: Waiting
0817436a8f49: Waiting
3385a426f542: Waiting
35c986c7de74: Waiting
53bab0663330: Waiting
606c36b65880: Waiting
ab99fcc1a184: Waiting
9691e5d7a4c7: Waiting
6a4d393f0795: Waiting
e38834ac7561: Waiting
ec64f555d498: Waiting
840f3f414cf6: Waiting
17fce12edef0: Waiting
831c5620387f: Waiting
5c008103b520: Pushed
96fd7149e6a8: Pushed
eac34fee20ac: Pushed
c34869bde755: Pushed
98d3c49f13ab: Pushed
bd51b78ec5a5: Pushed
897144f6e2ff: Pushed
4c4801c52898: Pushed
36a33866c585: Pushed
ae9ead4be184: Pushed
0817436a8f49: Layer already exists
3385a426f542: Layer already exists
35c986c7de74: Layer already exists
53bab0663330: Layer already exists
ab99fcc1a184: Layer already exists
606c36b65880: Layer already exists
9a078a1d1b01: Pushed
a42cb226a41b: Pushed
6a4d393f0795: Layer already exists
9691e5d7a4c7: Layer already exists
e38834ac7561: Layer already exists
ec64f555d498: Layer already exists
17fce12edef0: Layer already exists
840f3f414cf6: Layer already exists
831c5620387f: Layer already exists
0d678d51888b: Pushed
latest: digest: sha256:a46642efce16bbed3015725bfd40cbabb2115529ceb0e0a0430ca44b74f8453f size: 5740

[Container] 2020/10/09 08:14:29 Phase complete: POST_BUILD State: SUCCEEDED
[Container] 2020/10/09 08:14:29 Phase context status code:  Message: 
[Container] 2020/10/09 08:14:29 Expanding base directory path: .
[Container] 2020/10/09 08:14:29 Assembling file list
[Container] 2020/10/09 08:14:29 Expanding .
[Container] 2020/10/09 08:14:29 Expanding file paths for base directory .
[Container] 2020/10/09 08:14:29 Assembling file list
[Container] 2020/10/09 08:14:29 Expanding result.txt
[Container] 2020/10/09 08:14:29 Found 1 file(s)

```

Finally, you can check and verify that each stage of your CodePipline has been successfully completed!


![header image](img/8-codepipeline-succeded.png) 

## 6. Verification of CloudGuard protection

On AWS Console, go to "Lambda", and the function that we've enabled the protection on. Verify that a layer has been added to the function.

![header image](img/aws-lambda-function-layer.png) 


You can log on to your CloudGuard console, and go to the Serverless module or Protected Assets. Check your Lambda function.

**Congratulations!** You've successfully integrated CloudGuard SHIFTLEFT protection into CICD pipeline on AWS!

![header image](img/cloudguard-1.png) 


## Issues

1. One of the issues you might probably encounter in CodePipeline is the build stage might fail due to IAM insufficient permissions. Double check that sufficient IAM permissions are given to the role.

2. Make sure that all required software & dependencies are installed. (e.g. AWS CLI, SAM, Nodejs) Otherwise, scipts like sam_deploy.sh won't run.


![header image](img/cloudguard.png) 

## Resources

1. [Check Point CloudGuard Workload Protection](https://www.checkpoint.com/products/workload-protection/#:~:text=CloudGuard%20Workload%20Protection%2C%20part%20of,automating%20security%20with%20minimal%20overhead.)

2. [CloudGuard Workload (Protego) Examples](https://github.com/dome9/protego-examples)

3. Here is another good tutorial you might want to check out - [CloudGuard integration with AWS Pipeline by Dean Houari](https://github.com/chkp-dhouari/AWSCICD-CLOUDGUARD)


