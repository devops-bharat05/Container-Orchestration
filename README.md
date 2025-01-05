# MERN Application Deployment on AWS EKS

## Project Overview
This project aims to streamline the deployment process of a MERN (MongoDB, Express.js, React, Node.js) application by leveraging the power of AWS Elastic Kubernetes Service (EKS), Jenkins, and Helm. The core objective is to ensure the application is scalable, secure, and highly available while minimizing manual intervention. Kubernetes provides robust orchestration for managing containerized applications, and Helm simplifies the deployment process by managing Kubernetes manifests. 

The integration of Jenkins introduces automation into the entire infrastructure provisioning and deployment lifecycle, ensuring that continuous integration and continuous deployment (CI/CD) best practices are adhered to. By automating infrastructure provisioning, deployment, and scaling, this project reduces the likelihood of human error, enhances operational efficiency, and ensures the infrastructure is resilient and adaptable to changes in application load.

## Project Structure
The project is divided into several components, each fulfilling a critical role in deploying the MERN stack application on EKS:
1. **Jenkins Pipeline** - Automates the provisioning of IAM roles, EKS cluster creation, and application deployment. This ensures reproducibility and eliminates inconsistencies across environments.
2. **Helm Chart** - Facilitates the deployment and management of Kubernetes resources (Deployments, Services, Ingress) through templating and version control. Helm charts standardize application deployment, providing an abstraction that simplifies Kubernetes configuration.
3. **Kubernetes Manifests** - Define the desired state of application components, such as Deployments, Services, and Ingress controllers, allowing for fine-grained control over application behavior and resource allocation.

---

## Prerequisites
To ensure seamless deployment, the following tools and configurations must be installed and properly configured:
- **AWS CLI** - Enables interaction with AWS services.
- **eksctl** - Simplifies the creation and management of EKS clusters.
- **kubectl** - Command-line interface for managing Kubernetes clusters and resources.
- **Jenkins** - Orchestrates the deployment pipeline, ensuring automation and repeatability.
- **Helm** - Facilitates Kubernetes package management.
- **Docker** - Builds and pushes container images to a container registry.

Additionally, ensure that the AWS Identity and Access Management (IAM) roles are correctly configured to grant Jenkins access to AWS services, including EKS and EC2.

---

## Jenkins Pipeline Setup
### Jenkinsfile
The Jenkins pipeline is structured to automate the following tasks:
1. **Provision IAM Roles** - Creates the IAM roles required for EKS cluster creation and worker node provisioning. These roles grant Kubernetes and EC2 instances the necessary permissions to interact with AWS services.
2. **Create EKS Cluster** - Provisions the EKS cluster using eksctl, streamlining the process of defining node groups, security groups, and scaling policies.
3. **Deploy Ingress Controller** - Deploys the NGINX Ingress controller to manage external access to the services running inside the Kubernetes cluster.
4. **Deploy Application** - Leverages Kubernetes manifests and Helm charts to deploy frontend and backend services, as well as manage the lifecycle of pods and services.

```groovy
pipeline {
    agent any
    environment {
        AWS_REGION = 'us-west-2'
        CLUSTER_NAME = 'my-cluster01'
    }

    stages {
        stage('Provision IAM Roles') {
            steps {
                script {
                    sh '''
                    aws iam create-role --role-name eks-cluster-role01 --assume-role-policy-document file://eks-cluster-trust-policy.json
                    aws iam attach-role-policy --role-name eks-cluster-role01 --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
                    '''
                }
            }
        }
        
        stage('Create EKS Cluster') {
            steps {
                script {
                    sh 'eksctl create cluster -f cluster-config.yaml'
                }
            }
        }
        
        stage('Deploy Ingress Controller') {
            steps {
                script {
                    sh 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml'
                }
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    sh 'kubectl apply -f mongo-secret.yaml && kubectl apply -f backend-deployment.yaml && kubectl apply -f frontend-deployment.yaml'
                }
            }
        }
    }
}
```

---

## Helm Chart
Helm charts are used to manage Kubernetes resources by providing a reusable and configurable deployment template. This project uses a Helm chart to deploy the frontend and backend services, ensuring that Kubernetes objects are consistently applied across environments.

### Chart Structure
```
helm-chart/
|-- Chart.yaml
|-- values.yaml
|-- templates/
    |-- deployment.yaml
    |-- service.yaml
    |-- ingress.yaml
```

### Deployment YAML (Backend & Frontend)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: your-dockerhub-repo/mern-app:latest
          ports:
            - containerPort: 5000
```

---

## Application Deployment
The application deployment follows a step-by-step approach:

1. **Namespace Creation**
Namespaces segregate and isolate resources within a Kubernetes cluster, ensuring better resource management and avoiding conflicts.
```bash
kubectl create namespace mern
```
2. **Deploy Secrets**
Kubernetes secrets store sensitive information, such as database credentials, ensuring secure configuration.
```bash
kubectl apply -f mongo-secret.yaml
```
3. **Deploy Backend and Frontend**
Deploy the core application services, ensuring they are distributed across the cluster for resilience.
```bash
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
```
4. **Verify Deployments**
Confirm the successful deployment by querying running pods.
```bash
kubectl get pods -n mern
```

---

## Conclusion
This project represents a comprehensive approach to automating the deployment of a scalable MERN stack on AWS EKS. By leveraging Jenkins for CI/CD, Kubernetes for orchestration, and Helm for resource management, the project establishes a production-ready infrastructure capable of scaling dynamically with application demand.

