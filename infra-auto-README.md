# Multi-Service E-Commerce Application Deployment Using Terraform and Docker

## 1. Project Overview and Architecture

This project provisions the complete cloud infrastructure on AWS using Terraform and deploys a containerized multi-service Node.js e-commerce application using Docker and Docker Compose on an EC2 instance.

The application architecture consists of five containerized services and a MongoDB database:
- Frontend Service: React single-page application served via Nginx on ports 80 and 3000, acting as a reverse proxy for all API calls.
- User Service: Authentication and user profile management microservice running on port 3001.
- Product Service: Product catalog and category management microservice running on port 3002.
- Cart Service: Shopping cart operations microservice running on port 3003.
- Order Service: Order placement and simulated payment processing microservice running on port 3004.
- Database: MongoDB 6.0 instance managing isolated collections for each microservice.

### Architectural Flow

```
Client Browser
      |
      | (HTTP Ports 80 / 3000)
      v
[ AWS EC2 Instance (Public Subnet: 10.0.1.0/24) ]
      |
      +---> Nginx Reverse Proxy (Frontend Container)
                 |
                 +---> /api/auth, /api/users     --> User Service (Port 3001)
                 +---> /api/products, /categories --> Product Service (Port 3002)
                 +---> /api/cart                 --> Cart Service (Port 3003)
                 +---> /api/orders, /payments    --> Order Service (Port 3004)
                 |
                 v
           [ MongoDB (Internal Port 27017) ]
```

---

## 2. Containerization and Docker Configuration

Each service was containerized using tailored, production-optimized Dockerfiles with non-root security execution, multi-stage builds, and resource optimizations.

### 2.1 Backend Microservices
All four backend services (`user-service`, `product-service`, `cart-service`, `order-service`) utilize lightweight `node:18-alpine` base images, clean production dependency installation, and run under the unprivileged `node` user:

```dockerfile
FROM node:18-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm install --production && npm cache clean --force
COPY --chown=node:node . .
USER node
EXPOSE <PORT>
CMD ["node", "server.js"]
```

### 2.2 Frontend Service with Nginx Reverse Proxy
The frontend uses a multi-stage Docker build. Stage 1 compiles the React bundle with source map generation disabled to prevent build-time memory exhaustion. Stage 2 serves the static assets through Nginx and reverse-proxies `/api/*` requests to the respective backend microservice containers:

```nginx
server {
    listen 80;
    listen 3000;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    location /health {
        default_type application/json;
        return 200 '{"service": "Frontend Service", "status": "Live", "message": "Frontend is Live"}';
    }

    location /api/auth       { proxy_pass http://user-service:3001; }
    location /api/users      { proxy_pass http://user-service:3001; }
    location /api/products   { proxy_pass http://product-service:3002; }
    location /api/categories { proxy_pass http://product-service:3002; }
    location /api/cart       { proxy_pass http://cart-service:3003; }
    location /api/orders     { proxy_pass http://order-service:3004; }
    location /api/payments   { proxy_pass http://order-service:3004; }
}
```

### 2.3 Docker Compose Multi-Container Orchestration
A root `docker-compose.yml` orchestrates the lifecycle, port bindings, environment configurations, service dependencies, and internal bridge network (`ecommerce-net`) across all six containers.

---

## 3. Version Control and Git Workflow

All application code, Docker configurations, and Terraform definitions were tracked, staged, committed, and synchronized to the GitHub repository: `https://github.com/tb-repo/E-CommerceStore`.

### 3.1 Git Status and Staging
![Git Status](images/git_status.png)

### 3.2 Git Commit
![Git Commit](images/git_commit.png)

### 3.3 Git Push to Remote Repository
![Git Push](images/git_push.png)

---

## 4. Terraform Infrastructure Provisioning

The infrastructure is written in HashiCorp Configuration Language (HCL) within the `terraform/` directory:

- `provider.tf`: Configures the AWS provider (`ap-south-1` region), TLS provider, and local provider.
- `variables.tf`: Parameterizes region, instance type (`t3.medium`), and project naming convention (`tb-ecommerce-app`).
- `vpc.tf`: Builds a dedicated Virtual Private Cloud (VPC), Public Subnet, Internet Gateway (IGW), and Route Table.
- `security_groups.tf`: Defines granular firewall ingress rules for ports 22 (SSH), 80/3000 (Frontend HTTP), and 3001-3004 (Microservice APIs).
- `key_pair.tf`: Automatically generates a 4096-bit RSA TLS private key, registers the public key with AWS, and saves the private key locally as `tb-ecommerce-key.pem`.
- `userdata.sh`: Bootstraps the EC2 instance on first boot by provisioning swap space, installing Docker and Docker Compose plugin, cloning the repository, and building/starting all containers.
- `ec2.tf`: Provisions an Ubuntu 22.04 LTS instance with 20GB gp3 root volume.
- `outputs.tf`: Exports the EC2 Public IP, frontend access URLs, and direct health check endpoints.

### 4.1 Terraform Initialization
`terraform init` initialized the required provider plugins:
![Terraform Init](images/terraform_init.png)

### 4.2 Terraform Validation
`terraform validate` verified the syntactic validity and internal consistency of all configuration files:
![Terraform Validate](images/terraform_validate.png)

### 4.3 Terraform Execution Plan
`terraform plan -out=tfplan` calculated the resource changes (10 resources to create):
![Terraform Plan Part 1](images/terraform_plan1.png)
![Terraform Plan Part 2](images/terraform_plan2.png)

### 4.4 Terraform Apply and Outputs
`terraform apply` successfully provisioned all AWS infrastructure components and displayed the exported outputs:
![Terraform Apply](images/terraform_apply.png)
![Terraform Outputs](images/terraform_outputs.png)

---

## 5. AWS Management Console Verification

All provisioned resources were verified in the AWS Management Console to confirm proper creation, tagging, and state.

### 5.1 Virtual Private Cloud (VPC)
The dedicated VPC `tb-ecommerce-app-vpc` created with CIDR `10.0.0.0/16`:
![AWS Console VPC Detail 1](images/awsconsole_vpc1.png)
![AWS Console VPC Detail 2](images/awsconsole_vpc2.png)

### 5.2 Public Subnet
Public subnet `tb-ecommerce-app-public-subnet` configured with CIDR `10.0.1.0/24` and auto-assign public IPv4 enabled:
![AWS Console Subnet](images/awsconsole_subnet.png)

### 5.3 Internet Gateway
Internet Gateway `tb-ecommerce-app-igw` attached to the VPC:
![AWS Console Internet Gateway](images/awsconsole_igw.png)

### 5.4 Route Table and Routing
Route table `tb-ecommerce-app-public-rt` routing `0.0.0.0/0` outbound traffic through the Internet Gateway:
![AWS Console Route Table Overview](images/awsconsole_routetable1.png)
![AWS Console Route Table Routes](images/awsconsole_routetable2.png)

### 5.5 Security Group Rules
Security Group `tb-ecommerce-app-sg` with specific ingress rules for ports 22, 80, 3000, and 3001-3004:
![AWS Console Security Group Rules](images/awsconsole_ec2-sg-rules.png)

### 5.6 Key Pair
The auto-generated SSH key pair `tb-ecommerce-app-key` registered in AWS:
![AWS Console Key Pair](images/awsconsole_keypair.png)
![AWS Console Key File Verification](images/awsconsole_keypair_keyfile.png)

### 5.7 EC2 Instance State
The running EC2 instance `tb-ecommerce-app-ec2` with assigned public IP, public DNS, and attached security group:
![AWS Console EC2 Overview](images/awsconsole_ec2-1.png)
![AWS Console EC2 Details](images/awsconsole_ec2-2.png)

---

## 6. Remote Host and Container Verification

Connecting to the EC2 host via SSH confirmed the automated installation of Docker, Docker Compose, and active container runtimes.

### 6.1 SSH Connection
Connecting to the instance using the generated key `tb-ecommerce-key.pem`:
![EC2 SSH Connection 1](images/ec2_ssh1.png)
![EC2 SSH Connection 2](images/ec2_ssh2.png)

### 6.2 Docker and Docker Compose Automated Installation
Verification of Docker engine status and compose plugin:
![Docker Compose Installation](images/ec2_ssh_dockercompose_install.png)

### 6.3 Docker Container Status
Verification showing all six containers in healthy running status (`user-service`, `product-service`, `cart-service`, `order-service`, `ecommerce-frontend`, `ecommerce-mongodb`):
![Docker Services Status](images/ec2_ssh3-docker_node_service_status.png)

### 6.4 Nginx Web Server Processes
Verification of the Nginx master and worker processes active inside the frontend container:
![Nginx Processes](images/ec2_ssh4-nginx-processes.png)

---

## 7. Application Functionality Verification

The application was accessed publicly through the browser to verify full frontend rendering and successful integration with the backend microservices.

### 7.1 Homepage
The responsive landing page displaying the hero banner, category cards, and featured product listings:
![Application Homepage](images/app_homepage.png)

### 7.2 Product Catalog
Product catalog displaying categorized inventory retrieved dynamically from the Product Service:
![Product Catalog Page](images/app_productpage.png)

### 7.3 User Registration
User registration interface submitting new account data to the User Service:
![User Registration Page](images/app_registerpage.png)

### 7.4 User Authentication / Login
JWT-based authentication page communicating with the User Service auth endpoints:
![User Login Page](images/app_loginpage.png)

### 7.5 Authenticated User Session
Navigation bar and session state updated after successful login:
![Authenticated User Session](images/app_userloggedinpage.png)

### 7.6 User Profile Management
Authenticated user profile view and address management:
![User Profile Page](images/app_profilepage.png)

### 7.7 Shopping Cart
Active cart view displaying added items, quantity adjustments, and subtotal calculation via the Cart Service:
![Shopping Cart Page](images/app_cartpage.png)

### 7.8 Order Management
Order placement and order history view managed by the Order Service:
![Orders Page](images/app_orderspage.png)

---

## 8. Service Endpoints and Health Check Verification

The evaluator can test each individual service endpoint using standard HTTP requests:

| Service | Port | Endpoint URL | Expected Status |
| :--- | :---: | :--- | :---: |
| **Frontend (Standard)** | 80 | `http://<EC2_PUBLIC_IP>/` | HTTP 200 (Live Web UI) |
| **Frontend (Custom)** | 3000 | `http://<EC2_PUBLIC_IP>:3000/` | HTTP 200 (Live Web UI) |
| **Frontend Health** | 80 / 3000 | `http://<EC2_PUBLIC_IP>/health` | `{"service":"Frontend Service","status":"Live"}` |
| **User Service** | 3001 | `http://<EC2_PUBLIC_IP>:3001/health` | `{"service":"User Service","status":"OK","port":3001}` |
| **Product Service** | 3002 | `http://<EC2_PUBLIC_IP>:3002/health` | `{"service":"Product Service","status":"OK","port":3002}` |
| **Cart Service** | 3003 | `http://<EC2_PUBLIC_IP>:3003/health` | `{"service":"Cart Service","status":"OK","port":3003}` |
| **Order Service** | 3004 | `http://<EC2_PUBLIC_IP>:3004/health` | `{"service":"Order Service","status":"OK","port":3004}` |

### Terminal Verification Commands

```bash
# Frontend Web App
curl -I http://<EC2_PUBLIC_IP>
curl -I http://<EC2_PUBLIC_IP>:3000

# Frontend Health
curl http://<EC2_PUBLIC_IP>/health

# Microservices Health Checks
curl http://<EC2_PUBLIC_IP>:3001/health
curl http://<EC2_PUBLIC_IP>:3002/health
curl http://<EC2_PUBLIC_IP>:3003/health
curl http://<EC2_PUBLIC_IP>:3004/health
```

---

## 9. Infrastructure Teardown Instructions

To avoid unnecessary AWS cloud charges after assessment evaluation, destroy all provisioned infrastructure using Terraform:

```bash
cd terraform
terraform destroy -auto-approve
```

This single command safely removes the EC2 instance, security group, key pair, subnet, route table, internet gateway, and VPC in reverse dependency order.
