# Highly Available & Resilient Multi-AZ Web Infrastructure on AWS

![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws&logoColor=white)
![Region](https://img.shields.io/badge/Region-ap--south--1%20(Mumbai)-blue)
![Nginx](https://img.shields.io/badge/Server-Nginx-009639?logo=nginx&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Multi--AZ-007ACC)
![License](https://img.shields.io/badge/License-MIT-green)

A production-grade, highly available, and horizontally scalable multi-tier web infrastructure designed and deployed on Amazon Web Services (AWS) in the Mumbai Region (`ap-south-1`). Built following AWS Well-Architected Framework principles, focusing on high availability, network isolation, defense-in-depth security, and fault tolerance.

---

## 📌 Table of Contents
- [Project Overview](#-project-overview)
- [Architecture & Network Topology](#-architecture--network-topology)
- [Key Features](#-key-features)
- [AWS Services Used](#-aws-services-used)
- [Network Addressing Plan](#-network-addressing-plan)
- [Traffic & Communication Flows](#-traffic--communication-flows)
- [Implementation Steps](#-implementation-steps)
  - [1. VPC & Networking](#1-vpc--networking)
  - [2. Storage & Private S3 Endpoint](#2-storage--private-s3-endpoint)
  - [3. Compute & Launch Template](#3-compute--launch-template)
  - [4. Target Group & Application Load Balancer](#4-target-group--application-load-balancer)
  - [5. Auto Scaling Group](#5-auto-scaling-group)
- [Security Architecture & Firewall Rules](#-security-architecture--firewall-rules)
- [Validation & Verification](#-validation--verification)
- [Cost Management & Cleanup Order](#-cost-management--cleanup-order)
- [Repository Structure](#-repository-structure)
- [Future Improvements](#-future-improvements)
- [Author & Acknowledgments](#-author--acknowledgments)

---

## 📖 Project Overview

This project implements a resilient multi-AZ cloud architecture on AWS:
- **Network Isolation:** Public subnets host internet-facing components (ALB, NAT Gateways), while core EC2 application servers reside securely inside isolated private subnets with **no direct internet exposure**.
- **High Availability & Fault Tolerance:** Deployed across two Availability Zones (`ap-south-1a` and `ap-south-1b`) to survive single-datacenter outages.
- **Automated Fleet Management:** An Auto Scaling Group (ASG) maintains desired server capacity and facilitates self-healing.
- **Optimized Data Routing:** An Amazon S3 VPC Gateway Endpoint routes internal S3 traffic directly over the AWS private backbone, avoiding NAT Gateway data processing costs.

---

## 🏗 Architecture & Network Topology

```
                                [ Internet Users ]
                                        │
                                        ▼ (HTTP :80)
                            [ Internet Gateway (IGW) ]
                           (devops-project-igw)
                                        │
        ┌───────────────────────────────┴───────────────────────────────┐
        │                                                               │
┌───────▼───────────────────────────────────┐   ┌───────────────────────▼───────────────────┐
│ Availability Zone 1 (ap-south-1a)         │   │ Availability Zone 2 (ap-south-1b)         │
│                                           │   │                                           │
│  [ Public Subnet: 10.0.1.0/24 ]           │   │  [ Public Subnet: 10.0.2.0/24 ]           │
│  ┌─────────────────────────────────────┐  │   │  ┌─────────────────────────────────────┐  │
│  │  Application Load Balancer (:80)    │◄─┼───┼─►│  Application Load Balancer (:80)    │  │
│  │  NAT Gateway AZ1 (Elastic IP)       │  │   │  │  NAT Gateway AZ2 (Elastic IP)       │  │
│  └──────────────────┬──────────────────┘  │   │  └──────────────────┬──────────────────┘  │
│                     │                     │   │                     │                     │
│  [ Private Subnet: 10.0.11.0/24 ]         │   │  [ Private Subnet: 10.0.12.0/24 ]         │
│  ┌─────────────────────────────────────┐  │   │  ┌─────────────────────────────────────┐  │
│  │  EC2 Instance (t3.micro - Ubuntu)   │  │   │  │  EC2 Instance (t3.micro - Ubuntu)   │  │
│  │  Nginx Web Server (:80)             │  │   │  │  Nginx Web Server (:80)             │  │
│  │  Auto Scaling Group Target          │  │   │  │  Auto Scaling Group Target          │  │
│  └──────────────────┬──────────────────┘  │   │  └──────────────────┬──────────────────┘  │
└─────────────────────┼─────────────────────┘   └─────────────────────┼─────────────────────┘
                      │                                               │
                      └───────────────────────┬───────────────────────┘
                                              │
                                [ S3 VPC Gateway Endpoint ]
                                (com.amazonaws.ap-south-1.s3)
                                              │
                                              ▼
                                 [ Amazon S3 Bucket ]
                              (devops-project-file-nik)
```

---

## 🌟 Key Features

- **Multi-AZ Redundancy:** Automatic workload distribution across multiple failure domains.
- **Zero Ingress to Private Compute:** EC2 instances hold no public IP addresses; ingress is strictly limited to the ALB.
- **Decoupled Security Groups:** Micro-segmented firewall boundaries where the backend security group only accepts traffic sourced from the load balancer security group ID.
- **Elastic Compute Pool:** ASG maintains continuous baseline availability (Desired: 2, Min: 2, Max: 4).
- **Outbound Patching Connectivity:** Private instances retrieve system updates and package installations securely via zonal NAT Gateways.
- **Cost-Optimized Storage Access:** S3 VPC Gateway Endpoint bypasses NAT Gateway bandwidth charges for object storage requests.

---

## 🛠 AWS Services Used

| Service | Role in Architecture |
| :--- | :--- |
| **Amazon VPC** | Isolated software-defined cloud network container (`10.0.0.0/16`) in `ap-south-1`. |
| **Subnets** | Strict separation of public ingress components from private application compute. |
| **Internet Gateway (IGW)** | Facilitates bi-directional communication between public subnets and the internet. |
| **NAT Gateways** | Highly available managed outbound NAT instances providing egress for private instances. |
| **Route Tables** | Independent routing logic for public internet, zonal NAT gateways, and S3 endpoints. |
| **Security Groups** | Stateful instance-level and load balancer-level virtual firewalls. |
| **Amazon EC2** | Scalable compute running Ubuntu Server and Nginx. |
| **EC2 Launch Template** | Versioned specification template defining instance AMI, hardware type, network, and User Data. |
| **Application Load Balancer** | Layer 7 load balancer distributing incoming HTTP web traffic across targets. |
| **Target Group** | Target abstraction performing regular HTTP health checks on registered instances. |
| **Auto Scaling Group (ASG)** | Automated health monitoring, dynamic provisioning, and replacement of compute fleet. |
| **Amazon S3** | Scalable object storage bucket (`devops-project-file-nik`) with public access blocked. |
| **VPC Gateway Endpoint** | Private network routing directly to Amazon S3 without internet egress. |

---

## 🌐 Network Addressing Plan

| Resource Name | Subnet Name | CIDR Block | Availability Zone | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **VPC** | `devops-project-vpc` | `10.0.0.0/16` | Multi-AZ | Primary project network boundary |
| **Public Subnet 1** | `public-subnet-az1` | `10.0.1.0/24` | `ap-south-1a` | ALB ingress & NAT Gateway AZ1 |
| **Public Subnet 2** | `public-subnet-az2` | `10.0.2.0/24` | `ap-south-1b` | ALB ingress & NAT Gateway AZ2 |
| **Private Subnet 1**| `private-subnet-az1`| `10.0.11.0/24`| `ap-south-1a` | Private backend EC2 instances |
| **Private Subnet 2**| `private-subnet-az2`| `10.0.12.0/24`| `ap-south-1b` | Private backend EC2 instances |

---

## 🔄 Traffic & Communication Flows

### 1. Inbound Client Traffic
```text
Client Browser (HTTP/80) 
  ──► Internet Gateway (`devops-project-igw`)
  ──► Application Load Balancer (`devops-project-alb` on Port 80)
  ──► Target Group (`devops-webserver-tg`)
  ──► Private EC2 Instance (Nginx Web Server on Port 80)
```

### 2. Outbound Egress Traffic (Updates / OS Patches)
```text
Private EC2 (Subnet AZ1/AZ2) 
  ──► Respective Zonal NAT Gateway (`nat-gateway-az1` / `nat-gateway-az2`)
  ──► Internet Gateway (`devops-project-igw`)
  ──► Public Repositories / Internet
```

### 3. Private Internal Storage Traffic
```text
Private EC2 
  ──► S3 VPC Gateway Endpoint (`com.amazonaws.ap-south-1.s3`)
  ──► Amazon S3 Bucket (`devops-project-file-nik`)
```

---

## 🚀 Implementation Steps

### 1. VPC & Networking
1. Created custom VPC `devops-project-vpc` with IPv4 CIDR `10.0.0.0/16`.
2. Created 4 subnets across 2 Availability Zones (`ap-south-1a`, `ap-south-1b`).
3. Created Internet Gateway `devops-project-igw` and attached it to `devops-project-vpc`.
4. Configured `public-route-table`:
   - Route `0.0.0.0/0` ➔ `devops-project-igw`
   - Associated with `public-subnet-az1` and `public-subnet-az2`.
5. Created two Elastic IPs and deployed two Zonal NAT Gateways:
   - `nat-gateway-az1` in `public-subnet-az1`
   - `nat-gateway-az2` in `public-subnet-az2`
6. Configured independent private route tables:
   - `private-route-table`: `0.0.0.0/0` ➔ `nat-gateway-az1` (Associated with `private-subnet-az1`)
   - `private-route-table-az2`: `0.0.0.0/0` ➔ `nat-gateway-az2` (Associated with `private-subnet-az2`)

### 2. Storage & Private S3 Endpoint
1. Created S3 General Purpose Bucket: `devops-project-file-nik`.
   - Enabled **Block all public access**.
   - Disabled ACLs (AWS recommended).
   - Enabled default server-side encryption.
2. Created Gateway VPC Endpoint `s3-gateway-endpoint` for service `com.amazonaws.ap-south-1.s3`.
3. Associated the endpoint directly with `private-route-table` and `private-route-table-az2`.

### 3. Compute & Launch Template
Configured an EC2 Launch Template (`devops-webserver-template`):
- **AMI:** Ubuntu Server LTS
- **Instance Type:** `t3.micro`
- **Security Group:** `ec2-security-group`
- **Storage:** 8 GiB gp3
- **User Data Script:**
  ```bash
  #!/bin/bash
  apt-get update -y
  apt-get install -y nginx
  systemctl enable nginx
  systemctl start nginx
  cat > /var/www/html/index.html <<'EOF'
  <!DOCTYPE html>
  <html>
  <head>
    <title>AWS DevOps Project</title>
  </head>
  <body>
    <h1>Welcome to My AWS DevOps Project!</h1>
    <p>High Availability Web Application</p>
  </body>
  </html>
  EOF
  ```

### 4. Target Group & Application Load Balancer
1. Created Target Group `devops-webserver-tg`:
   - Target type: `Instances`
   - Protocol/Port: `HTTP / 80`
   - Health check path: `/`
2. Deployed Application Load Balancer `devops-project-alb`:
   - Scheme: `Internet-facing`
   - VPC: `devops-project-vpc`
   - Subnets: `public-subnet-az1` and `public-subnet-az2`
   - Security Group: `alb-security-group`
   - Listener: Port 80 forwarding to `devops-webserver-tg`

### 5. Auto Scaling Group
1. Configured Auto Scaling Group `devops-project-asg` referencing `devops-webserver-template`.
2. Placed instances strictly inside `private-subnet-az1` and `private-subnet-az2`.
3. Attached to target group `devops-webserver-tg`.
4. Group Sizing:
   - **Desired Capacity:** 2
   - **Minimum Capacity:** 2
   - **Maximum Capacity:** 4

---

## 🔐 Security Architecture & Firewall Rules

Security was configured following the principle of least privilege:

```
[ Internet ] ──(Port 80)──► [ alb-security-group ] ──(Port 80)──► [ ec2-security-group ]
```

| Security Group | Direction | Protocol | Port | Source / Destination | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`alb-security-group`** | Inbound | TCP | 80 | `0.0.0.0/0` | Allows public web traffic to the ALB. |
| **`alb-security-group`** | Outbound | ALL | ALL | `0.0.0.0/0` | Default egress rule. |
| **`ec2-security-group`** | Inbound | TCP | 80 | `sg-0bc6b4ddafb93b3fc` (`alb-security-group`) | **Strictly restricts ingress to ALB only.** Direct public ingress is denied. |
| **`ec2-security-group`** | Outbound | ALL | ALL | `0.0.0.0/0` | Outbound connectivity routed through NAT Gateways. |

---

## 🧪 Validation & Verification

| Test Scenario | Verification Point | Observed Result | Status |
| :--- | :--- | :--- | :---: |
| **Subnet & Routing Isolation** | VPC Route Tables | Route tables correctly isolate public IGW routes and private NAT routes | ✅ PASSED |
| **NAT Gateway Status** | VPC Console | Both `nat-gateway-az1` and `nat-gateway-az2` reached `Available` state | ✅ PASSED |
| **Target Group Health Check** | EC2 Target Groups | 2 out of 2 instances reported **Healthy** on Port 80 | ✅ PASSED |
| **Fleet Redundancy** | Auto Scaling Groups | ASG maintained 2 instances balanced across both private subnets | ✅ PASSED |
| **End-to-End Application Delivery** | Browser HTTP Request | Successfully served page via ALB DNS: `http://devops-project-alb-52866828.ap-south-1.elb.amazonaws.com` | ✅ PASSED |

```text
Response Output:
"Welcome to My AWS DevOps Project!
 High Availability Web Application"
```

---

## 🧹 Cost Management & Cleanup Order

To avoid unnecessary AWS usage costs (especially for NAT Gateways, Elastic IPs, and ALB), tear down resources in the following reverse-dependency order:

1. **Auto Scaling Group (`devops-project-asg`):** Delete ASG and wait for all EC2 instances to terminate.
2. **Application Load Balancer & Target Group:** Delete `devops-project-alb`, then delete `devops-webserver-tg`.
3. **Launch Template:** Delete `devops-webserver-template`.
4. **S3 Gateway Endpoint & Bucket:** Delete `s3-gateway-endpoint`, empty and delete S3 bucket `devops-project-file-nik`.
5. **NAT Gateways & Elastic IPs:** Delete `nat-gateway-az1` and `nat-gateway-az2`, then release their associated Elastic IPs.
6. **Security Groups & Route Tables:** Delete custom route tables (`private-route-table`, `private-route-table-az2`, `public-route-table`) and custom security groups.
7. **Internet Gateway & VPC:** Detach and delete `devops-project-igw`, delete all 4 custom subnets, and finally delete `devops-project-vpc`.

---
---

## 🔮 Future Improvements

- [ ] **HTTPS / TLS Encryption:** Terminate TLS on ALB using AWS Certificate Manager (ACM).
- [ ] **Custom Domain Management:** Connect Amazon Route 53 with alias records for branded domain routing.
- [ ] **Dynamic Scaling Policies:** Implement Target Tracking Scaling policies based on average CPU utilization or request count per target.
- [ ] **Infrastructure as Code (IaC):** Modularize and provision the entire architecture using **Terraform** or **AWS CloudFormation**.
- [ ] **CI/CD Automation:** Set up automated testing and zero-downtime deployment pipelines using GitHub Actions or AWS CodePipeline.
- [ ] **Observability & Logs:** Integrate Amazon CloudWatch Alarms, ALB Access Logs, and VPC Flow Logs.

---

## 👨‍💻 Author & Acknowledgments

**Niketan Sarode**  
*AWS & DevOps*

---
*Built with best practices for scalability, security, and high availability on AWS.*
