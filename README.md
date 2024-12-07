# Secure-Java-App-Deployment

# **Project Overview**

In modern DevOps, automation is crucial for efficient, reliable, and consistent software deployment. GitLab CI/CD is a powerful tool that helps streamline the entire software delivery process. In this project, we’ll explore how to use GitLab CI/CD to deploy a Java application (Board Game App) on an AWS Cloud-hosted Kubernetes cluster.

Using Gitlab CI/CD sometimes requires running lengthy jobs, we will use Terraform to spin up an EC2 gitlab runner and automatically register it on our [gitlab instance](https://gitlab.com)

This K8s configuration will be made by using eksctl. We'll cover the process from creating the Kubernetes cluster to deploying a containerized Java application, integrating essential DevOps tools like Terraform, Trivy and SonarQube along the way.

The fun part of this project will be the integration of our gitlab instance with the k8s cluster hosted on AWS, automate the deployment of the application, test its functionality and finally monitor the application to ensure high availability & scalability

# **Step-by-Step Workflow:**

* 1- Outsourcing the App code from the Software team (Code local Test & Review)
* 2- Creating & Registering a GitLab Runner on an AWS EC2 instance using Terraform
* 3-Creating a GitLab CI/CD Pipeline
* 4-Unit Testing with Maven
* 5-Scanning application dependencies files with Trivy
* 6-Analyzing Code Quality with SonarQube
* 7-Building and Containerizing the Application
* 8-Scanning the Container Image with Trivy.
* 9-Pushing the Container Image to GitLab Container Registry.
* 10-Setting up AWS EKS Cluster using eksctl.
* 11-Connecting EKS Cluster with GitLab
* 12-Deploying the application on Kubernetes cluster(EKS)
* 13-Verify & Test the Successful application Deployment
* 14-Monitoring the application

# **INFRASTRUCTURE SETUP**

![pic1](https://github.com/user-attachments/assets/6c34e790-0aa7-4989-a1c9-d4e9f09b4f4e)

## PREREQUESITES:

* **TOOLS:** An AWS account, A gitlab account (or access to a your self-hosted gitlab instance)
* **Softwares to be installed on your local machine:** git, aws cli, docker desktop (for docker & docker-compose), terraform, kubectl , eksctl, helm, …
* **Verify your local computer has all the tools needed**. Run the following commands as shown below:

![pic2](https://github.com/user-attachments/assets/8ec7c21c-d746-423c-8b24-71634d5be8e7)

# **Step 1:** Outsourcing the application code

* The application code is usually obtained from the internal software team or from a customer, The code is reviewed, test locally on the DevOps Engineer's computer. A new gitlab repository is then created, and this is where the magic will happen.
* After the code review, the changes (if necessary) will be committed and push to the gitlab repo

![pic3](https://github.com/user-attachments/assets/9c743f8d-ae79-43b0-ad17-c6148dff73f1)

# **Step 2:** Creating & Registering a GitLab Runner on an AWS EC2 instance using Terraform

* From the gitlab.com server GUI, navigate to Settings/CI-CD/Runners/New-project-runner/create-runner, in order to obtain the runner registration script. This script will be included in the user data code section of your EC2 instance.
* In a separate directory in your local machine, write a terraform code that will automatically launch an EC2 instance in AWS.
* To save time, and build less EC2 instances, we decided to use an EC2 instance with at least 2 CPU (t2.medium), in order to use the same instance for job runs and SonarQube server.
* As a DevSecOps engineer, code scans and vulnerability remediation are Top priorities. There are few tools out there, but for the purpose of this project, we went with SonarQube for code analysis before using it in our pipeline. It is opened source, can be easily installed using docker and exposed on port 9000 of our gitlab runner EC2 instance. This is also why a script to install docker was added into the terraform code of our runner user data.
 

![pic4](https://github.com/user-attachments/assets/e9430bc1-10df-45fd-862a-7cfb6a3f787f)

* Save your TF code and run the 3 TF magical commands to provision your gitlab runner: terraform init, terraform plan, terraform apply --auto-approve

![pic5](https://github.com/user-attachments/assets/5fcf56c9-ea93-4e08-ad85-fbf4a1601a64)

* Lets Now verify that our runner was successfully created in the AWS EC2 Console. Also from the Terraform output result, you can get the ssh link to remotely connect to the ec2 instance and check all the services you had in the user data script: gitlab-runner & docker

![pic6](https://github.com/user-attachments/assets/2f50fa4a-a345-4551-87ec-d9ff0bbe905c)

* Now let's verify that the runner was automatically registered to our gitlab instance, by navigating back to Settings/CI-CD/Runners, you should see your newly created runner under the section: "Other available runners" with the tag list you specify in the Terraform code listed underneath.

![pic7](https://github.com/user-attachments/assets/42cd329c-d3cb-47c2-ab2e-644214be453d)

* NOTE: At this point, it will be important to update the rules for the user gitlab-runner

  ```
   *  `ssh to the gitlab server`
   *  `become root`
   *  `cd /etc/sudoers.d/`
   *  `vi 90-cloud-init-users`
   *  `Enter gitlab-runner ALL=(ALL) NOPASSWD:ALL`
  ```
* Remember this same instance is used for multi-purpose, so let's check if we can use this same server as our SonarQube server to scan for vulnerabilities. By default, SonarQube runs on port 9000.
* Open you browser and enter the SonarQube URL that was given in your terminal after the terraform apply --auto-approve was ran earlier.

![pic8](https://github.com/user-attachments/assets/64f850b2-2dce-4416-9ee3-e0bd761d116b)

# **Step 3:** Creating a GitLab CI/CD Pipeline

* With the code outsourced in step1 pushed to your new gitlab repository, all you need to do is create a gitlab CI/CD configuration file ".gitlab-ci.yml". Without this file, there is no pipeline.
* This file contains all the stages/jobs of your pipeline from start to finish. Knowing that we are building a Java application (from the software team code review), we can pick and choose all the tools that will be needed in this CI-CD pipeline.
  * Open JDK is our Java development kit
  * Maven to build and compile the Java codes
  * Docker to build and pull base images and change permissions to the docker daemon
  * Trivy for dependency Files scan and docker image scan
  * Kubectl to interact and manage our EKS cluster

![pic9](https://github.com/user-attachments/assets/c5dc04fe-370c-45ee-a4f4-ccc907b38c7d)

* commit your changes and push your code to your gitlab repo. If your commit was to the main branch, with this .gitlab-ci.yml now in your repo, you have automatically kicked off your first build in the pipeline.

![pic10](https://github.com/user-attachments/assets/903721d9-208a-4491-aec0-a40ecd3bf926)

# Pipeline View

![pic11](https://github.com/user-attachments/assets/e4ba3dfb-62ef-4b7a-8534-ecd7291a439e)

# Stage1 view

![pic12](https://github.com/user-attachments/assets/975604d2-6d4a-428b-9fdc-983f6e7bf0c3)

# **Step 4:** Unit Testing with Maven

This step was already done in the in step3, You can check the stage view to check how the unit test was done. `mvn test`

# Stage2 view
 
![pic13](https://github.com/user-attachments/assets/c9f0c78d-9fe4-4165-bbf0-2449c60d22d4)

# **Step 5:** Scanning application dependencies files with Trivy

* Just like in step 4, this step is job that was already done in step3, here is the stage view.
* A tf-fscan stage here will scan dependency files for vulnerabilities prior use in the pipeline.

# Stage3 view

![pic14](https://github.com/user-attachments/assets/9323a367-1137-4a2d-b4cd-9645fd0a7582)

* From the pipeline configuration, we decided to save all the artifacts in a file (fs.html) that can be accessed on the browser. For a production ready environment, it is recommended to send it to a separate artifact repository like Nexus or JFrog
* `trivy fs --format table -o fs.html`

![pic15](https://github.com/user-attachments/assets/a88e0e18-cdda-4177-939e-4ea2e081d79c) ![pic16](https://github.com/user-attachments/assets/e117c30a-fc45-4346-9cf2-050a31f5355f)

# **Step 6:** Analyzing Code Quality with SonarQube

* SonarQube is a tool that analyzes source code to detect bugs, vulnerabilities, and code smells.
* Integrating SonarQube into your CI pipeline helps maintain high code quality.
* SonarQube consists of two parts, one is scanner part and other is server part. We did setup the server automatically in the terraform script when launching the EC2 runner.
* Integrate your gitlab project with the SonarQube server using a project access token
* Navigate to Project/Settings/Access tokens/ and click on Add token
* Click on `create project access token`, this will launch a quick tutorial for you to follow the steps.

![pic17](https://github.com/user-attachments/assets/f16ea3de-3207-425a-b1cc-79845c296f6b)

* Copy the generated token below in a notepad and be ready to use it later in your SonarQube server

![pic18](https://github.com/user-attachments/assets/bb545984-0330-4c18-9120-419c00ec1ba2)

* Access the SonarQube portal http://ec2-runner-public-ip:9000, reset your admin password (default admin user= admin , default admin password=admin), Click on New Project and select the `Gitlab` 
![pic19](https://github.com/user-attachments/assets/2cb8aa99-4b95-4a8e-bd1a-abe433c3d473)

* Enter the following data to enable the gitlab integration with your SonarQube server as shown below"

![pic20](https://github.com/user-attachments/assets/aceffbfa-b0de-46a4-a0c3-4a15fc8bb5f3)

* Enter the project access token for a second time here for gitlab project onboarding
![pic21](https://github.com/user-attachments/assets/eb0fa749-5102-4965-a773-d8297bd9913b)

* Now let's setup the project key, so our project code can be analyzed with Gitlab CI. After clicking on `save` from the last picture, another window will pop up with `Gitlab project Onboarding`. You should click on `set up`. Then another window will display: `How do you want to analyze your repository?` Make sure you select: `With Gitlab CI`
* The next window will ask you how you want to set project key, select `Other(...) and copy the code generated in your local gitlab project directory.
![pic22](https://github.com/user-attachments/assets/07e621e9-1ab1-435e-b3dd-5185cda95efd)

* In your local gitlab repository, create a file named `sonar-project.properties` as shown below:
![pic23](https://github.com/user-attachments/assets/e332a83f-ab12-4fb0-8782-c09c290502a9)

* At this point, you can create the environment variables ($SONAR_TOKEN & $SONAR_HOST_URL) that will be used by any gitlab runner (shared/or dedicated) to pick up the SonarQube scan job
![pic24](https://github.com/user-attachments/assets/3d7551a5-dc86-4753-8885-0c33fbf85c64)

 * From this window as shown above, click on `Generate a token`
 * Return to your gitlab project and create the 2 variables

![pic25](https://github.com/user-attachments/assets/eed5a990-aeb4-4a10-aa36-2e0ae00d1507)
![pic26](https://github.com/user-attachments/assets/ffb0b13e-a818-4245-8954-cd852c1359d7)

 * Remember to come back to your local gitlab project directory, to add the sonarqube-check stage in your gitlab CI/CD configuration file.
The code for this stage should look like this: 
```
 sonarqube-check:
  stage: sonar_test
  image:
    name: sonarsource/sonar-scanner-cli:latest
  variables:
    SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar" # Defines the location of the analysis task cache
    GIT_DEPTH: "0" # Tells git to fetch all the branches of the project, required by the analysis task
  cache:
    key: "${CI_JOB_NAME}"
    paths:
    - .sonar/cache
  script:
  - sonar-scanner
  allow_failure: true
  only:
  - main
```
    
 * to commit and push all the last changes/updates you just made. 
 * This will trigger another pipeline run.

# Pipeline View
![pic27](https://github.com/user-attachments/assets/704dbe70-4360-4c7e-9122-32eaa7c0ac3f)

# Stage 4 View
![pic28](https://github.com/user-attachments/assets/b40fd213-ea3f-4b8e-a9e8-fd967fe4339f)

The Stage 4 view shows a `Check Quality Gate status` as `PASSED` and gives us a link to access the analysis report on our [SonarQube server](http://18.286.175.247:9000/dashboard?id=Gaetanneo_java-app_AZOT-AUzSnmSuW41jsxU)

![pic29](https://github.com/user-attachments/assets/6be4a436-3dc5-4ed8-af3d-abe10267f3b0)
 `RESULTS: 15 Bugs, 0 Vulnerabilies, 47 Code Smells, QUALITY GATE STATUS= PASSED`

# **Step 7 & 8 & 9:** Containerizing the application(image build) & Image scan & Image push.
   * Once testing and scanning are completed, the next step is to build the application package and create a Docker image.
   * Before pushing the image, we scan it with Trivy to ensure it doesn’t contain any vulnerabilities.
   * This step is vital for security, as it identifies any issues within the built Docker image.
   * When the built image is scanned and vulnerability free, it can be pushed to the gitlab container registry.
   * Add the following code to your .gitlab-ci.yml file
```
image_build_&_scan:
  stage: build_and_scan
  variables:
    Image_tag: $CI_REGISTRY/gaetanneo/java-app/java-app:$CI_PIPELINE_ID
  script:
  - mvn clean package
  - docker build -t $Image_tag .
  - trivy image $Image_tag --format table -o image.html
  tags:
  - dedicated-runner
  artifacts:
    paths:
    - image.html
  only:
  - main

image_push:
  stage: image_push
  variables:
    Image_tag: $CI_REGISTRY/gaetanneo/java-app/java-app:$CI_PIPELINE_ID
  before_script:
  - docker login $CI_REGISTRY -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD
  script:
  - docker push $Image_tag
  tags:
  - dedicated-runner
  only:
  - main
```
 * As you see on the code, this will cover stage 7,8 and 9. Those will be run by our dedicated runner created earlier in step 1. The application will be containerized and the built image will be pushed to the gitlab instance's container registry.
 * Commit & push your code changes to your main branch of the gitlab repository and observe your new pipeline run.

# Pipeline view
![pic30](https://github.com/user-attachments/assets/193aab1a-65aa-4e24-889d-a07e8155cbf3)

# Pipeline Better view (To Identify the runner of each stage/job)
![pic31](https://github.com/user-attachments/assets/7134f77a-64b2-427b-bf54-368c45cb2b3b)

# Stage 5 view
![pic30](https://github.com/user-attachments/assets/e4e6c065-c269-4bbb-bb19-cead85865853)

# Stage 6 view
![pic31](https://github.com/user-attachments/assets/f92e8619-a40f-42d4-bbc3-d917b16fb47f)

 * If you ran those 3 stages successfully, you can see on the stage6 view above, where to find the docker image that was recently built and pushed. i.e: your gitlab container registry.
 * From your project page, Navigate to Deploy/Container Registry. If you click on the tagID, you will be able to view the `Manifest digest` that was visible from the stage6 view.
![pic32](https://github.com/user-attachments/assets/8db27e23-78dc-410e-a080-40f6be3ec367)

#  **Step 10:** Setting up AWS EKS Cluster using eksctl
   * In your local gitlab project directory, create a new file called cluster-setup.yaml that will be use to customize your cluster the way you want it.
   * We have decided to build an EKS cluster that will have 2 node groups and each node group will have 2 node that can auto-scale on demand, based on traffic. 
   * `cluster-setup.yaml contents`
```
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: boadgameapp  #Don't be like me who misspelled this word and had to troubleshoot a lot to find Out
  region: us-east-1  #My integration from gitlab to my k8s cluster was fun on this project!!!

nodeGroups:
  - name: small-nodegroup
    instanceType: t2.micro
    desiredCapacity: 2

  - name: medium-nodegroup
    instanceType: t2.small
    desiredCapacity: 2
```

 * Using eksctl is the easiest and quickest way to launch a k8s cluster for a DEV environment, run eh following command: `ekstcl` create cluster -f cluster-setup.yml. For a Production ready environment, the EKS cluster should be created with Terraform.
![pic33](https://github.com/user-attachments/assets/482ba6d7-b1c1-4db4-9949-a3644d576da8)

![pic34](https://github.com/user-attachments/assets/80bdb80c-0de4-471a-9613-886e674a048c)

 * Using eksctl is an automated way to use the cool AWS service called `CloudFormation` to build the `stacks` that are necessary to build the resources you need for your cluster and respecting the customization you enforced in your cluster-setup.yml, All this while avoiding to write a CloudFormation Template (CFT) from scratch.
 * Just out of curiosity, let's take a look at the CFT auto-generated by eksctl.
![pic35](https://github.com/user-attachments/assets/4b3eedc9-7948-4e30-b9ae-96c4927568c8)

 * With AWS constant search of innovation, we now have the ability to build a CloudFormation console mode, that will ease the problem of making mistake when writing a CFT code from scratch
![pic36](https://github.com/user-attachments/assets/ba0e2a2e-cc99-4d08-ab1d-819fedac22c6)

 * Having a look at the stacks ready(CREATION_COMPLETE!!!), it means that our customized EKS cluster is ready for use. On average, it takes about 15 minutes to spin up a k8s cluster.
 * There are 2 ways of verifying that our EKS cluster is ready: 
         * Through the local Terminal (CLI), because eskctl will also update your local kubeconfig file. In most windows computers, you can find the file `config` by running the command:
`
 cat ~/.kube/config
,
          On your local machine, run `kubectl get nodes` to list all your nodes in your k8s cluster
![pic37](https://github.com/user-attachments/assets/36d72a7c-21b9-44ea-b26c-b326df606874)
    
         * Through the AWS Console, navigate to the EKS services and check under `Clusters`
![pic38](https://github.com/user-attachments/assets/d7488c4e-e0d6-44fe-a806-65899308a338)

Also, Knowing that an EKS is made out of nodes that are actually EC2 instances, you can navigate to the EC2 dashboard and see the newly created 4 EC2 instances.
![pic39](https://github.com/user-attachments/assets/81d1ce0b-74fd-4690-9ca9-85e68eefe126)

#  **Step 11:** Connecting EKS Cluster with GitLab

    * After creating the EKS cluster, the next step is to connect it to GitLab to manage deployments directly from your CI/CD pipeline.
    * Integrating gitlab and EKS can be done by:
          * a-Creating an agent
              * From your gitlab project, Navigate to `Operate/Kubernetes Cluster/Connect a Cluster`
              * Enter the name of the agent (it should be exactly named as the name of your eks cluster)
          * b-Register the agent
              * A window will pop up, showing you the k8s agent installation commands, using helm.
```
(1) helm repo add gitlab https://charts.gitlab.io
(2) helm repo update
(3) helm upgrade --install eks-k8s gitlab/gitlab-agent \
      --namespace gitlab-agent-eks-k8s \
      --create-namespace \
      --set image.tag=v17.3.0-rc7 \
      --set config.token= <your-token> \
      --set config.kasAddress= <your-kasAddress>
```
              * After running those commands one at a time, the k8s agent will be deployed. Confirm it by refreshing the page on gitlab and checking if the connection status of the agent is showing `Connected` with a `green` check mark.
![pic40](https://github.com/user-attachments/assets/b2e67ac4-59dd-455a-98ba-6af77c3f240f)
          * c- Create the secret config file for CI-Registry authentication with the EKS cluster
              * Now we need to add the registry credentials in Kubernetes manifest so that it can pull the image while creating deployment.
              * create secret named `registry-credentials
              * create the 2 Deloy Tokens(They will be used as our container registry’s username and password) 

![pic41](https://github.com/user-attachments/assets/a345644b-53c3-4056-81fa-dba7ef533afd)
![pic42](https://github.com/user-attachments/assets/5f8a51bf-ffbb-4d93-a27b-169b2b3dbf81)
              * copy the deploy token 1 & 2 and save them on a notepad for further use in the next command
```
   kubectl create secret docker-registry registry-credentials --docker-server=registry.gitlab.com --docker-username=<1st-token> --docker-password=<2nd-token> --dry-run=client -o yaml > registry-credentials.yml
```
![pic43](https://github.com/user-attachments/assets/8cf76e34-424c-4d16-90ba-f98a59731ef2)
              * You can see that it saved a secret config file (registry-credentials.yml) for the gitlab instance CI registry, using the deploy tokens we just obtained.
              * The last part of this authentication process will be applying/installing that gitlab instance secret to the EKS cluster, using kubectl. This will establish the full handshake connection between your gitlab instance CI registry and your EKS cluster in AWS. Run the command: ` kubectl apply -f registry-credentials.yml  
   
 * Create an agent configuration file named config.yaml in your local machine gitlab repository: 
```
   cd ~/path/to/project/root/directory
   mkdir -p .gitlab/agents/eks-k8s/
   vi .gitlab/agents/eks-k8s/config.yaml
```
  * Contents of `config.yaml`
```
   gitops:
       manifest_projects:
       - id: 65096462  #Change this number to your project ID from the gitlab GUI
       ref:
          branch: production

       default_namespace: default

       reconcile_timeout: 3600s
       dry_run_strategy: none
       prune: true
       prune_timeout: 3600s
       prune_propagation_policy: foreground
       inventory_policy: must_match
```

#  **Step 12:** Deploying the application on Kubernetes cluster(EKS)

    * AWS EKS was our best option to choose for cloud deployment purposes, simply because we want this Boardgame application to be highly available, regardless if we receive a high volume of traffic.
    * Application deployed on EKS are containerized applications that are running in pods, those pods can communicate with one another through the core DNS and VPC CNI (container Network interface).
    * Since our k8s cluster is hosted on AWS, the control plane is managed by the cloud provider.
    * A very important step not to forget would be adding all the environment variables for cloud access(AWS creds).
![pic44](https://github.com/user-attachments/assets/b1525b33-0753-4fc9-859f-22f351a4f29b)
    
    * Add the last stage(7th) to your .gitlab-ci.yml file, commit & push and observe a new pipeline run.

# Pipeline View
![pic45](https://github.com/user-attachments/assets/76f9c9de-6b31-4548-8263-9ae6cb3adbd2)

# Stage 7 view
![pic46](https://github.com/user-attachments/assets/db594c6f-728f-497a-8ef2-f1a21bec72a9)

#  **Step 13:** Verify & Test the Successful application Deployment
    * Since we have the kube config file on our local computer, we can check the k8s deployment from the CLI by running few commands: `kubectl get pods` ; `kubectl get svc` or `kubectl get all`, and check if all the pods are showing a status: `Ready`
![pic46](https://github.com/user-attachments/assets/7831ee3e-a761-43e0-8a21-cb7052afc7e2)    

    *  Another way of checking the deployment would be adding some few check commands to the .gitlab-ci.yml, precisely within the script portion of the last stage.
![pic47](https://github.com/user-attachments/assets/fec73712-b1b2-4c41-acde-04e258ff3709)

    * Commit & push your changes. After a successful deployment, you should be able to view the pods, the services, the deployments and replicasets created from the Stage view. 
![pic47](https://github.com/user-attachments/assets/f6f970ea-7871-44d1-9fc3-762c5aedaf37)
![pic48](https://github.com/user-attachments/assets/a6a5b613-b27f-4cef-843f-8caa08139352)

    * A proper way of verifying the application deployment would be running the command `kubectl get services`, this command will show you the service `external IP URL= a6b7c549b6e124d028e2c0884b6e6ac0-1507032152.us-east-1.elb.amazonaws.com`, which is also showing the `TYPE = Loadbalancer.`
    *  You can Navigate to your EC2 service on the AWS console, click on the load balancer details to see the exact same DNS name of your Kubernetes service.

```**NOTES:**
An Elastic Load Balancer (ELB) in an EKS cluster serves several important purposes: [1]

Traffic Distribution:

Distributes incoming traffic across multiple pods

Ensures even load distribution across worker nodes

Prevents any single pod from being overwhelmed

High Availability:

Performs health checks on pods

Routes traffic only to healthy pods

Automatically handles pod failures
```

Spans multiple Availability Zones for redundancy
![pic49](https://github.com/user-attachments/assets/3ddfc4bd-18f7-4bfe-a119-b223c305730a)

    * Finally, Let's use the Load balancer DNS name, copy it and paste on your browser. 
![pic50](https://github.com/user-attachments/assets/df094fba-7601-4c9e-940b-5581e4fb1f99) 
![pic51](https://github.com/user-attachments/assets/cc72bd83-2ef0-4b11-9cba-0c0f9919061c)
![pic52](https://github.com/user-attachments/assets/a6bebbd2-ba5a-4c91-ac54-6894e32dbdc9)
![pic53](https://github.com/user-attachments/assets/3615611d-ea3d-4abe-9aba-778109ee35b1)
![pic54](https://github.com/user-attachments/assets/d89ff8b3-3bdc-4d44-b9d3-56f2f041ddbe)
![pic55](https://github.com/user-attachments/assets/35f9a75a-52f9-4b96-a969-0b6580c46bee)
![pic56](https://github.com/user-attachments/assets/c8776221-5127-408d-a380-f6819f86735b)
![pic57](https://github.com/user-attachments/assets/46ec82de-79d5-4aa8-83fc-4d36046e1fdb)
![pic58](https://github.com/user-attachments/assets/054408f8-e3e2-4cb4-9a73-04bf08d5cc42)

# **Step 14:** Monitoring the application
   * Depending on your company environment, you can monitor the application for reliability and high availability using different tools. Follow the official documentations of each tools to properly integrate the tools and the applications deployed on your k8s cluster. There are so many open source tools out there, but I will name a few.  
       *  Using Amazon CloudWatch
       *  Using Prometheus and Grafana
       *  LENS / KARPENTER
```
   NOTES: Benefits of application monitoring provide:
   * Real-time monitoring of application health

   * Resource usage tracking

   * Log aggregation

   * Alert configuration

   * Performance metrics

   * Custom dashboard creation

   * Integration with AWS services

   * Automated health checks
```

![pic59](https://github.com/user-attachments/assets/5908b1de-cf5b-40f5-bf51-e2ef18593829)

For Documentation not to be too long, I omitted to upload all the 103 screenshots that I took when doing this project. Troubleshooting is what we happily do for a living and it is always part of the Software delivery lice Cycle.

if you want to see how I troubleshoot to fix my yaml files indentations errors, how I use Amazon Q to help me fix code smells after SonarQube code analysis, troubleshoot to find out why the gitlab runner went out of memory and steps to add more space to it, Troubleshoot when SonarQube went down and brought it back up and running, then Check out the README of this [GitHub repo](https://github.com/Gaetanneo/Boardgame-app-Pictures/blob/main/README.md)


###Trust the Process !!!....

