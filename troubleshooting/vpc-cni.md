#### 2024-11-24 15:36:12 [!]  recommended policies were found for "vpc-cni" addon, but since OIDC is disabled on the cluster, eksctl cannot configure the requested permissions; the recommended way to provide IAM permissions for "vpc-cni" addon is via pod identity associations; after addon creation is completed, add all recommended policies to the config file, under `addon.PodIdentityAssociations`, and run `eksctl update addon`

This warning indicates that the EKS cluster you are creating has not been configured with an **OIDC provider**, which is required for assigning fine-grained IAM roles to Kubernetes pods or EKS add-ons like `vpc-cni`. Without this, you cannot use **IAM roles for service accounts (IRSA)** to provide recommended permissions to the `vpc-cni` add-on.

Here’s how you can resolve this issue step-by-step:

---

### 1. Enable OIDC Provider for the EKS Cluster
You need to associate an OIDC provider with your EKS cluster. Run the following command:

```bash
eksctl utils associate-iam-oidc-provider \
  --region us-west-2 \
  --cluster mern-cluster02 \
  --approve
```

This command sets up the OIDC provider and allows your cluster to use IAM roles for service accounts.

---

### 2. Attach Recommended Policies to the `vpc-cni` Add-on

#### a) Identify the Recommended Policies
AWS recommends specific IAM policies for the `vpc-cni` add-on. These are usually included in the Amazon-managed policy `AmazonEKS_CNI_Policy`. To attach this policy:
1. Attach it directly to the node role, or
2. Use **Pod Identity Associations** via IRSA.

For now, let's use the recommended **IRSA approach**.

---

#### b) Create an IAM Role for the `vpc-cni` Add-on

Run the following commands to create an IAM role and attach the `AmazonEKS_CNI_Policy` to it:

```bash
eksctl create iamserviceaccount \
  --name aws-node \
  --namespace kube-system \
  --cluster mern-cluster02 \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
  --approve \
  --region us-west-2
```

This command will:
1. Create an IAM role with the required `AmazonEKS_CNI_Policy`.
2. Associate it with the `aws-node` Kubernetes service account in the `kube-system` namespace.

---

### 3. Update the Add-on Configuration
Once the IAM role is set up, update the `vpc-cni` add-on configuration to use the IAM role for permissions.

```bash
eksctl update addon \
  --name vpc-cni \
  --cluster mern-cluster02 \
  --region us-west-2 \
  --force
```

---

### 4. Validate the Configuration
Verify that the `vpc-cni` add-on is correctly configured:

```bash
kubectl describe daemonset aws-node -n kube-system
```

Check that the `aws-node` pod is using the service account with the attached IAM role.

---

### Optional: Edit the `eksctl` Configuration File
You can also include the `PodIdentityAssociations` in your `eksctl` configuration file for future clusters. An example configuration file might look like this:

```yaml
addons:
  - name: vpc-cni
    version: latest
    configurationValues: {}
    PodIdentityAssociations:
      - namespace: kube-system
        serviceAccounts:
          - name: aws-node
```

Save this as `cluster-config.yaml` and use it to update the add-on:
```bash
eksctl update addon -f cluster-config.yaml --region us-west-2
```

---

### Summary
- Enable OIDC for your cluster.
- Create an IAM role with the `AmazonEKS_CNI_Policy` and associate it with the `aws-node` service account.
- Update the `vpc-cni` add-on to use the IAM role.
- Validate the setup to ensure everything is working correctly.

This approach ensures that the `vpc-cni` add-on has the necessary permissions without relying on the node role, enhancing security and manageability. Let me know if you need further clarification!
