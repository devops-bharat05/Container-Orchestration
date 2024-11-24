# EKS Cluster with NGINX Ingress Controller, Horizontal Pod Autoscaling, and Jenkins CI/CD  

This project sets up an **Amazon EKS Cluster** on AWS with **NGINX Ingress Controller** and implements horizontal pod autoscaling. Jenkins is configured for CI/CD to automate deployments. The setup integrates **AWS ALB** and **Cloudflare** for DNS and routing traffic through a custom domain.  

---

## **Project Overview**  

1. **EKS Cluster**: Creates an Amazon EKS Cluster with worker nodes.  
2. **NGINX Ingress Controller**: Deploys NGINX for load balancing and routing traffic.  
3. **Horizontal Pod Autoscaling (HPA)**: Ensures scalability based on traffic and resource usage.  
4. **Jenkins CI/CD**: Automates the build, test, and deployment workflows for Kubernetes resources.  
5. **AWS ALB and Cloudflare Integration**: Routes requests to the app through ALB and custom domain (`devopshunter.com`).  

---

## **Prerequisites**  

Ensure you have the following installed and configured:  
- **AWS CLI**  
- **kubectl**  
- **eksctl**  
- **helm**  
- **Jenkins** (installed on a server or locally, with necessary plugins like **Kubernetes**, **Git**, **Pipeline**).  
- A registered domain (`devopshunter.com`) configured on Cloudflare.  

---

## **Setup Instructions**  

### 1. **Provision EKS Cluster**  
Run the following bash script to create the EKS cluster:  
```bash
#!/bin/bash

# Variables
CLUSTER_NAME="mern-cluster02"
REGION="us-west-2"
NODE_GROUP_NAME="standard-workers"
NODE_TYPE="t2.medium"
NODES=3

echo "Creating EKS Cluster..."
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name $NODE_GROUP_NAME \
  --node-type $NODE_TYPE \
  --nodes $NODES \
  --version 1.31

echo "EKS Cluster setup completed."
```  

---

### 2. **Deploy NGINX Ingress Controller**  
Once the EKS cluster is ready, deploy the **NGINX Ingress Controller**:  
```bash
#!/bin/bash

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
echo "NGINX Ingress Controller installed successfully."
```  

---

### 3. **Jenkins Setup**  

#### 3.1 Install Jenkins Plugins  
Ensure the following plugins are installed on Jenkins:  
- **Kubernetes**  
- **Git**  
- **Pipeline**  
- **Blue Ocean** (optional for modern UI)  

#### 3.2 Configure Jenkins Kubernetes Plugin  
1. Navigate to **Manage Jenkins** → **Manage Plugins** and install the **Kubernetes** plugin.  
2. Go to **Manage Jenkins** → **Configure Clouds** and add a new Kubernetes cloud configuration:  
   - Kubernetes URL: `https://<eks-cluster-endpoint>`  
   - Kubernetes Namespace: `default`  
   - Add Jenkins credentials for accessing the Kubernetes cluster.  

#### 3.3 Jenkinsfile (Pipeline Configuration)  
Create a `Jenkinsfile` in your GitHub repository to automate deployment and scaling:  

```groovy
pipeline {
    agent any
    environment {
        KUBE_CONFIG = credentials('kubeconfig') // Jenkins credential ID for kubeconfig
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/devopshunter/eks-nginx-hpa.git'
            }
        }
        stage('Build Image') {
            steps {
                sh 'docker build -t devopshunter/example-app:latest .'
            }
        }
        stage('Push Image to ECR') {
            steps {
                withAWS(region: 'us-west-2', credentials: 'aws-credentials') { // Replace with your AWS credentials ID
                    sh 'aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <ecr-repo-uri>'
                    sh 'docker tag devopshunter/example-app:latest <ecr-repo-uri>/example-app:latest'
                    sh 'docker push <ecr-repo-uri>/example-app:latest'
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                kubectl apply -f k8s/deployment.yaml
                kubectl apply -f k8s/service.yaml
                kubectl apply -f k8s/ingress.yaml
                '''
            }
        }
        stage('Verify Deployment') {
            steps {
                sh 'kubectl get pods -n default'
                sh 'kubectl get hpa'
            }
        }
    }
}
```  

---

### 4. **Integrate ALB and Cloudflare**  
- Install and configure the AWS Load Balancer Controller on EKS.  
- Update Cloudflare DNS settings to point your domain to the ALB DNS name.  

---

## **Steps to Deploy**  

1. Clone this repository:
    ```bash
    git clone https://github.com/devopshunter/eks-nginx-hpa.git
    cd eks-nginx-hpa
    ```  

2. Run the setup script:
    ```bash
    bash setup.sh
    ```  

3. Trigger the Jenkins pipeline by pushing code to GitHub or running the pipeline manually.  

---

## **Testing Scenarios and Expected Results**  

1. **Jenkins Pipeline Execution**  
   - The pipeline builds and deploys the app to Kubernetes.  
   - Jenkins provides a detailed log for each stage.  

2. **Horizontal Pod Autoscaling Test**  
   - Generate traffic to test HPA functionality:
     ```bash
     kubectl run -i --tty load-generator --image=busybox /bin/sh
     while true; do wget -q -O- http://<service-name> ; done
     ```  
   - Check pods scaling:
     ```bash
     kubectl get hpa
     kubectl get pods
     ```  

3. **Application Accessibility**  
   - Access the app via `http://devopshunter.com`.  
   - Ensure traffic is routed correctly through ALB and Cloudflare.  

---

## **Screenshots**  

1. **Jenkins Pipeline Execution**:  
   ![Jenkins Pipeline](./screenshots/jenkins-pipeline.png)  

2. **HPA Scaling Metrics**:  
   ![HPA Metrics](./screenshots/hpa-metrics.png)  

3. **Cloudflare DNS Setup**:  
   ![Cloudflare DNS](./screenshots/cloudflare-dns.png)  

---

## **Clean-Up Instructions**  

Run the cleanup script to delete all resources:  
```bash
bash cleanup.sh
```  

Cleanup Script:  
```bash
#!/bin/bash

# Variables
CLUSTER_NAME="mern-cluster02"
REGION="us-west-2"

# Delete NGINX Ingress Controller
echo "Deleting NGINX Ingress Controller..."
helm uninstall nginx-ingress --namespace ingress-nginx

# Delete the EKS Cluster
echo "Deleting EKS Cluster..."
eksctl delete cluster --name $CLUSTER_NAME --region $REGION

echo "Cleanup completed."
```  

---

Let me know if you need further customization! 🚀
