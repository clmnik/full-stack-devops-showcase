This project demonstrates a **complete DevOps pipeline** by deploying a containerized **React + Flask application** to **AWS EKS** using **Terraform, Kubernetes, Helm, ArgoCD, and GitHub Actions**.

### Key Features:

- **Infrastructure as Code (IaC)**: Automated provisioning of AWS infrastructure (VPC, EKS, RDS) using Terraform.
- **Containerization & Orchestration**: Dockerized frontend and backend, deployed with Helm in Kubernetes.
- **Continuous Integration & Deployment (CI/CD)**: GitHub Actions pipeline automating build, test, push, and deployment.
- **Secrets Management**: Planned integration with **HashiCorp Vault** for securely managing database credentials.
- **Scalability & Automation**: Automated updates with ArgoCD, LoadBalancer setup, and rolling deployments.

🔹 **Current Status:** The application is successfully deployed in AWS EKS with CI/CD automation. The database connection (MySQL via RDS) is the next step.
