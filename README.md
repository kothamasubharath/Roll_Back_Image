Roll_Back_Image
----------------
   In our real time scenerio, we faced a lot of issues in server during deployments and we got downtime of server.To rectify that issue, we used roll-back image and to achieve zero downtime while deployment of server.
 
PRE-REQUISITES:
-----------------
 - Two EC2 servers with t2.micro
 - ECR for storing images in aws.
 - IAM role for aws service to service communication.
-----------------------------------------------------------------------------------------------
 EC2:
 ----
    Elastic Compute Cloud in aws for creating and managing virtual servers according to our specifications to acquire our needs.
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------
 Step1: JENKINS
 ----------------
    Jenkins is a open-source automation tool written in java and have mulitple number of plugins for integrating with many number of tools to achieve 
    CI/CD pipeline.
    
   There are two types of pipeline:
   ----------------------------------
          1.Scripted Pipeline
          2.Declarative Pipeline
         
    In our case,we use Declarative Pipeline(DSL) for implementing CI/CD pipeline.
Create a ec2 ubuntu instance for Jenkins Installation:
------------------------------------------------------            
          First we update the repository by using the below command:
                     sudo apt-get update -y
          Install maven for build the packages in pom.xml file and neglect the dependency error.
                     sudo apt-get install maven -y
          Before installing jenkins we must install java jdk-11 because jenkins written in java language.
                     sudo apt-get install openjdk-11-jdk -y
          Now we install jenkins using wget command with port 8080
                     wget https://get.jenkins.io/war-stable/2.361.3/jenkins.war
 ----------------------------------------------------------------------------------------------------------------------------------------------------------  

  2.And install docker package for the purpose docker image want to run image jenkins server.

           curl -fsSL https://get.docker.com -o get-docker.sh
           sh get-docker.sh

 3.Create user for adding to docker group

          sudo passwd ubuntu
          type and re-type passwd
          sudo vi /etc/ssh/sshd_config
          sudo service ssh restart
          sudo usermod -aG docker ubuntu
          sudo chmod 777 /var/run/docker.sock
          
   PIPELINE SYNTAX:
   ------------------
          stages{
          stage('git fetch'){
            steps{
                git branch: 'main', url: CredentailsI'd:1234 'https://github.com/kbharathkumar654/helloworld.git'
           
               }
            }

Step-2: DOCKER
----------------

 To create a environment for Docker using ec2 instance

   1.Create a ec2 ubuntu instance and install the docker packages

                curl -fsSL https://get.docker.com -o get-docker.sh
                sh get-docker.sh

  2.Create user for adding to docker group

          sudo passwd ubuntu
          type and re-type passwd
          sudo vi /etc/ssh/sshd_config
          sudo service ssh restart
          sudo usermod -aG docker ubuntu
          sudo chmod 777 /var/run/docker.sock   
          
 PIPELINE SYNTAX:
 -----------------
          stage('build image'){
            steps{
                script{
                    sh 'docker system prune -a'
                    dockerImage = docker.build "${IMAGE_REPO_NAME}:${IMAGE_TAG}"
                  }
              }  
           }
Step-3: ECR
---------------
        Elastic Container Registry for storing images and if you wish to push that image to any other remote servers if needs.
        
  1.Goto aws account and create a container registry for storing docker images

             select the start and click on private container
             Give the name for that container registry
             apply and saveit

  2.Goto the container name and click there you seen view push command icon clickon it

       cpy this command "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 838342381657.dkr.ecr.us-east-1.amazonaws.com

Step-4: IAM
-------------
           Identity and Access Management for security management purpose.
    
IAM has four types of modules
------------------------------
      1. User
      2. User group
      3. Roles
      4. Policy
      
     In our case, we used Roles for service to service communications inside a aws console.
-------------------------------------------------------------------------------------------------------
   1.Create role and apply to jenkins server in role give ecr full access

   2.Goto aws and search iam goto iam and here u find role click 

      select ec2 --->next --->search registry click on it  -->next  -->give name for role -->save it

  3.This role is attached to jenkins server

     Goto server click on action here u find security click on that u find modify iam role

           give the iam role and save it 

  4.finally the role is attached to jenkins server
  
 PIPELINE SYNTAX:
 -----------------
        stage('Logging to AWS ECR'){
            steps{
                script{
                       sh "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 838342381657.dkr.ecr.us-east-                                         1.amazonaws.com/${IMAGE_REPO_NAME}"
                     }
                  }     
             }

Step-5: AWSCLI - PUSH IMAGE TO ECR USING JENKINS
--------------------------------------------------

  1.Goto jenkins server and install the awscli for registry connection

                sudo apt install awscli -y
 
       here paste the container registry

                aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 838342381657.dkr.ecr.us-east-1.amazonaws.com

       it show the succeed message.
       
 PIPELINE SYNTAX:
 ----------------
       stage ('pushing to ECR'){
            steps{
                script{
                    sh "docker tag ${IMAGE_REPO_NAME}:${IMAGE_TAG} ${REPOSITORY_URL}:${IMAGE_TAG}"
                    sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"
                  }
               }
            }

Step-6: AWSCLI - PULL IMAGE FROM ECR TO REMOTE(DOCKER) SERVER
---------------------------------------------------------------

   1.Go to remote server same container registry connected with servers because we want push the img to container registry to remote server

   2.And attach the IAM role to remote server also

            sudo apt install awscli -y
        here paste the container registry
            aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 838342381657.dkr.ecr.us-east-1.amazonaws.com
        it shows the succeed output.
        
  PIPELINE SYNTAX:
  -----------------
        stage('pull the latest img to server'){
            steps{
                sh 'ssh ubuntu@172.31.18.18 "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 838342381657.dkr.ecr.us-                       east-1.amazonaws.com/${IMAGE_REPO_NAME} && docker pull ${REPOSITORY_URL}:${IMAGE_TAG}"'
                }
              }
Step-7: ENVIRONMENT VARIABLES
-------------------------------
      Environment variables helps programs know what directory to install files and to store temporary files and to find where the user profile settings is there.
      It preceded with '$' symbol
  PIPELINE SYNTAX:
 -----------------
       environment{
            AWS_ACCOUNT_ID="838342381657"
            AWS_DEFAULT_REGION="us-east-1"
            IMAGE_REPO_NAME="devops-jenkins"
            IMAGE_TAG="latest"
            REPOSITORY_URL = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}"
         }
Step-8: TRY AND CATCH METHOD
-------------------------------
      Try statement allows you to define a block of code to be tested for errors while it is being executed.
      Catch statement allows you to define a block of code to be executed,if an error occurs in the try block.
 
 PIPELINE SYNTAX:
 -----------------
      
       script{
                     try
                    {
                        sh "ssh ubuntu@172.31.18.18 docker run -d -p 8888:80 --name rollback --network=bridge ${REPOSITORY_URL}:${IMAGE_TAG}"
                    }
                    catch (error)
                    {
                        echo error.getmessage()
                        sh "ssh ubuntu@172.31.18.18 docker run -d -p 8888:80 --name rollback1 --network=bridge ${env.running_image}"
                    }
                }

Step-9: DECLARATIVE PIPELINE
------------------------------

   1.goto jenkins server and run the jenkins 
              
              java -jar jenkins.war

   2.in jenkins --->manage jenkins  -->manage plugins -->search for docker and docker pipeline plugin

   3.create a new job with pipeline and deploy into the server.
   
  Step-10: CONCLUSION
  ---------------------
        Finally the docker container runs on the remote server if there is any issues in that running container it will automatically rollback into the older version
        of the container without manual interruption.
