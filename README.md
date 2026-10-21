Highly Available \& Resilient Multi-AZ Web Infrastructure on AWSA production-grade, highly available, and horizontally scalable multi-tier web infrastructure designed and deployed on Amazon Web Services (AWS) in the Mumbai Region (ap-south-1). Built following AWS Well-Architected Framework principles, focusing on high availability, network isolation, defense-in-depth security, and fault tolerance.📌 Table of ContentsProject OverviewArchitecture \& Network TopologyKey FeaturesAWS Services UsedNetwork Addressing PlanTraffic \& Communication FlowsImplementation Steps1. VPC \& Networking2. Storage \& Private S3 Endpoint3. Compute \& Launch Template4. Target Group \& Application Load Balancer5. Auto Scaling GroupSecurity Architecture \& Firewall RulesValidation \& VerificationCost Management \& Cleanup OrderRepository StructureFuture ImprovementsAuthor \& Acknowledgments📖 Project OverviewThis project implements a resilient multi-AZ cloud architecture on AWS:Network Isolation: Public subnets host internet-facing components (ALB, NAT Gateways), while core EC2 application servers reside securely inside isolated private subnets with no direct internet exposure.High Availability \& Fault Tolerance: Deployed across two Availability Zones (ap-south-1a and ap-south-1b) to survive single-datacenter outages.Automated Fleet Management: An Auto Scaling Group (ASG) maintains desired server capacity and facilitates self-healing.Optimized Data Routing: An Amazon S3 VPC Gateway Endpoint routes internal S3 traffic directly over the AWS private backbone, avoiding NAT Gateway data processing costs.🏗 Architecture \& Network Topology                                \[ Internet Users ]

&#x20;                                       │

&#x20;                                       ▼ (HTTP :80)

&#x20;                           \[ Internet Gateway (IGW) ]

&#x20;                          (devops-project-igw)

&#x20;                                       │

&#x20;       ┌───────────────────────────────┴───────────────────────────────┐

&#x20;       │                                                               │

┌───────▼───────────────────────────────────┐   ┌───────────────────────▼───────────────────┐

│ Availability Zone 1 (ap-south-1a)         │   │ Availability Zone 2 (ap-south-1b)         │

│                                           │   │                                           │

│  \[ Public Subnet: 10.0.1.0/24 ]           │   │  \[ Public Subnet: 10.0.2.0/24 ]           │

│  ┌─────────────────────────────────────┐  │   │  ┌─────────────────────────────────────┐  │

│  │  Application Load Balancer (:80)    │◄─┼───┼─►│  Application Load Balancer (:80)    │  │

│  │  NAT Gateway AZ1 (Elastic IP)       │  │   │  │  NAT Gateway AZ2 (Elastic IP)       │  │

│  └──────────────────┬──────────────────┘  │   │  └──────────────────┬──────────────────┘  │

│                     │                     │   │                     │                     │

│  \[ Private Subnet: 10.0.11.0/24 ]         │   │  \[ Private Subnet: 10.0.12.0/24 ]         │

│  ┌─────────────────────────────────────┐  │   │  ┌─────────────────────────────────────┐  │

│  │  EC2 Instance (t3.micro - Ubuntu)   │  │   │  │  EC2 Instance (t3.micro - Ubuntu)   │  │

│  │  Nginx Web Server (:80)             │  │   │  │  Nginx Web Server (:80)             │  │

│  │  Auto Scaling Group Target          │  │   │  │  Auto Scaling Group Target          │  │

│  └──────────────────┬──────────────────┘  │   │  └──────────────────┬──────────────────┘  │

└─────────────────────┼─────────────────────┘   └─────────────────────┼─────────────────────┘

&#x20;                     │                                               │

&#x20;                     └───────────────────────┬───────────────────────┘

&#x20;                                             │

&#x20;                               \[ S3 VPC Gateway Endpoint ]

&#x20;                               (com.amazonaws.ap-south-1.s3)

&#x20;                                             │

&#x20;                                             ▼

&#x20;                                \[ Amazon S3 Bucket ]

&#x20;                             (devops-project-file-nik)

🌟 Key FeaturesMulti-AZ Redundancy: Automatic workload distribution across multiple failure domains.Zero Ingress to Private Compute: EC2 instances hold no public IP addresses; ingress is strictly limited to the ALB.Decoupled Security Groups: Micro-segmented firewall boundaries where the backend security group only accepts traffic sourced from the load balancer security group ID.Elastic Compute Pool: ASG maintains continuous baseline availability (Desired: 2, Min: 2, Max: 4).Outbound Patching Connectivity: Private instances retrieve system updates and package installations securely via zonal NAT Gateways.Cost-Optimized Storage Access: S3 VPC Gateway Endpoint bypasses NAT Gateway bandwidth charges for object storage requests.🛠 AWS Services UsedServiceRole in ArchitectureAmazon VPCIsolated software-defined cloud network container (10.0.0.0/16) in ap-south-1.SubnetsStrict separation of public ingress components from private application compute.Internet Gateway (IGW)Facilitates bi-directional communication between public subnets and the internet.NAT GatewaysHighly available managed outbound NAT instances providing egress for private instances.Route TablesIndependent routing logic for public internet, zonal NAT gateways, and S3 endpoints.Security GroupsStateful instance-level and load balancer-level virtual firewalls.Amazon EC2Scalable compute running Ubuntu Server and Nginx.EC2 Launch TemplateVersioned specification template defining instance AMI, hardware type, network, and User Data.Application Load BalancerLayer 7 load balancer distributing incoming HTTP web traffic across targets.Target GroupTarget abstraction performing regular HTTP health checks on registered instances.Auto Scaling Group (ASG)Automated health monitoring, dynamic provisioning, and replacement of compute fleet.Amazon S3Scalable object storage bucket (devops-project-file-nik) with public access blocked.VPC Gateway EndpointPrivate network routing directly to Amazon S3 without internet egress.🌐 Network Addressing PlanResource NameSubnet NameCIDR BlockAvailability ZonePurposeVPCdevops-project-vpc10.0.0.0/16Multi-AZPrimary project network boundaryPublic Subnet 1public-subnet-az110.0.1.0/24ap-south-1aALB ingress \& NAT Gateway AZ1Public Subnet 2public-subnet-az210.0.2.0/24ap-south-1bALB ingress \& NAT Gateway AZ2Private Subnet 1private-subnet-az110.0.11.0/24ap-south-1aPrivate backend EC2 instancesPrivate Subnet 2private-subnet-az210.0.12.0/24ap-south-1bPrivate backend EC2 instances🔄 Traffic \& Communication Flows1. Inbound Client TrafficClient Browser (HTTP/80) 

&#x20; ──► Internet Gateway (`devops-project-igw`)

&#x20; ──► Application Load Balancer (`devops-project-alb` on Port 80)

&#x20; ──► Target Group (`devops-webserver-tg`)

&#x20; ──► Private EC2 Instance (Nginx Web Server on Port 80)

2\. Outbound Egress Traffic (Updates / OS Patches)Private EC2 (Subnet AZ1/AZ2) 

&#x20; ──► Respective Zonal NAT Gateway (`nat-gateway-az1` / `nat-gateway-az2`)

&#x20; ──► Internet Gateway (`devops-project-igw`)

&#x20; ──► Public Repositories / Internet

3\. Private Internal Storage TrafficPrivate EC2 

&#x20; ──► S3 VPC Gateway Endpoint (`com.amazonaws.ap-south-1.s3`)

&#x20; ──► Amazon S3 Bucket (`devops-project-file-nik`)

🚀 Implementation Steps1. VPC \& NetworkingCreated custom VPC devops-project-vpc with IPv4 CIDR 10.0.0.0/16.Created 4 subnets across 2 Availability Zones (ap-south-1a, ap-south-1b).Created Internet Gateway devops-project-igw and attached it to devops-project-vpc.Configured public-route-table:Route 0.0.0.0/0 ➔ devops-project-igwAssociated with public-subnet-az1 and public-subnet-az2.Created two Elastic IPs and deployed two Zonal NAT Gateways:nat-gateway-az1 in public-subnet-az1nat-gateway-az2 in public-subnet-az2Configured independent private route tables:private-route-table: 0.0.0.0/0 ➔ nat-gateway-az1 (Associated with private-subnet-az1)private-route-table-az2: 0.0.0.0/0 ➔ nat-gateway-az2 (Associated with private-subnet-az2)2. Storage \& Private S3 EndpointCreated S3 General Purpose Bucket: devops-project-file-nik.Enabled Block all public access.Disabled ACLs (AWS recommended).Enabled default server-side encryption.Created Gateway VPC Endpoint s3-gateway-endpoint for service com.amazonaws.ap-south-1.s3.Associated the endpoint directly with private-route-table and private-route-table-az2.3. Compute \& Launch TemplateConfigured an EC2 Launch Template (devops-webserver-template):AMI: Ubuntu Server LTSInstance Type: t3.microSecurity Group: ec2-security-groupStorage: 8 GiB gp3User Data Script:#!/bin/bash

apt-get update -y

apt-get install -y nginx

systemctl enable nginx

systemctl start nginx

cat > /var/www/html/index.html <<'EOF'

<!DOCTYPE html>

<html>

<head>

&#x20; <title>AWS DevOps Project</title>

</head>

<body>

&#x20; <h1>Welcome to My AWS DevOps Project!</h1>

&#x20; <p>High Availability Web Application</p>

</body>

</html>

EOF

4\. Target Group \& Application Load BalancerCreated Target Group devops-webserver-tg:Target type: InstancesProtocol/Port: HTTP / 80Health check path: /Deployed Application Load Balancer devops-project-alb:Scheme: Internet-facingVPC: devops-project-vpcSubnets: public-subnet-az1 and public-subnet-az2Security Group: alb-security-groupListener: Port 80 forwarding to devops-webserver-tg5. Auto Scaling GroupConfigured Auto Scaling Group devops-project-asg referencing devops-webserver-template.Placed instances strictly inside private-subnet-az1 and private-subnet-az2.Attached to target group devops-webserver-tg.Group Sizing:Desired Capacity: 2Minimum Capacity: 2Maximum Capacity: 4🔐 Security Architecture \& Firewall RulesSecurity was configured following the principle of least privilege:\[ Internet ] ──(Port 80)──► \[ alb-security-group ] ──(Port 80)──► \[ ec2-security-group ]

Security GroupDirectionProtocolPortSource / DestinationDescriptionalb-security-groupInboundTCP800.0.0.0/0Allows public web traffic to the ALB.alb-security-groupOutboundALLALL0.0.0.0/0Default egress rule.ec2-security-groupInboundTCP80sg-0bc6b4ddafb93b3fc (alb-security-group)Strictly restricts ingress to ALB only. Direct public ingress is denied.ec2-security-groupOutboundALLALL0.0.0.0/0Outbound connectivity routed through NAT Gateways.🧪 Validation \& VerificationTest ScenarioVerification PointObserved ResultStatusSubnet \& Routing IsolationVPC Route TablesRoute tables correctly isolate public IGW routes and private NAT routes✅ PASSEDNAT Gateway StatusVPC ConsoleBoth nat-gateway-az1 and nat-gateway-az2 reached Available state✅ PASSEDTarget Group Health CheckEC2 Target Groups2 out of 2 instances reported Healthy on Port 80✅ PASSEDFleet RedundancyAuto Scaling GroupsASG maintained 2 instances balanced across both private subnets✅ PASSEDEnd-to-End Application DeliveryBrowser HTTP RequestSuccessfully served page via ALB DNS: http://devops-project-alb-52866828.ap-south-1.elb.amazonaws.com✅ PASSEDResponse Output:

"Welcome to My AWS DevOps Project!

&#x20;High Availability Web Application"

🧹 Cost Management \& Cleanup OrderTo avoid unnecessary AWS usage costs (especially for NAT Gateways, Elastic IPs, and ALB), tear down resources in the following reverse-dependency order:Auto Scaling Group (devops-project-asg): Delete ASG and wait for all EC2 instances to terminate.Application Load Balancer \& Target Group: Delete devops-project-alb, then delete devops-webserver-tg.Launch Template: Delete devops-webserver-template.S3 Gateway Endpoint \& Bucket: Delete s3-gateway-endpoint, empty and delete S3 bucket devops-project-file-nik.NAT Gateways \& Elastic IPs: Delete nat-gateway-az1 and nat-gateway-az2, then release their associated Elastic IPs.Security Groups \& Route Tables: Delete custom route tables (private-route-table, private-route-table-az2, public-route-table) and custom security groups.Internet Gateway \& VPC: Detach and delete devops-project-igw, delete all 4 custom subnets, and finally delete devops-project-vpc.📁 Repository Structure.

├── README.md                          # Main project documentation

├── architecture/

│   ├── architecture-diagram.png       # Complete AWS architecture schematic

│   └── request-flow.png               # Ingress/egress communication flow

├── scripts/

│   └── user-data.sh                   # EC2 bootstrap script for Nginx setup

└── screenshots/                       # AWS Console validation evidence

&#x20;   ├── 01-vpc-and-subnets.png

&#x20;   ├── 02-route-tables.png

&#x20;   ├── 03-nat-gateways.png

&#x20;   ├── 04-security-groups.png

&#x20;   ├── 05-s3-and-endpoint.png

&#x20;   ├── 06-launch-template.png

&#x20;   ├── 07-target-group-healthy.png

&#x20;   ├── 08-alb-active.png

&#x20;   ├── 09-asg-capacity.png

&#x20;   └── 10-browser-output-alb.png

🔮 Future Improvements\[ ] HTTPS / TLS Encryption: Terminate TLS on ALB using AWS Certificate Manager (ACM).\[ ] Custom Domain Management: Connect Amazon Route 53 with alias records for branded domain routing.\[ ] Dynamic Scaling Policies: Implement Target Tracking Scaling policies based on average CPU utilization or request count per target.\[ ] Infrastructure as Code (IaC): Modularize and provision the entire architecture using Terraform or AWS CloudFormation.\[ ] CI/CD Automation: Set up automated testing and zero-downtime deployment pipelines using GitHub Actions or AWS CodePipeline.\[ ] Observability \& Logs: Integrate Amazon CloudWatch Alarms, ALB Access Logs, and VPC Flow Logs.👨‍💻 Author \& AcknowledgmentsNiketan SarodeAWS \& DevOps EnthusiastBuilt with best practices for scalability, security, and high availability on AWS.

