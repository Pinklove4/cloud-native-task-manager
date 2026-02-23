# Architecture Documentation

## Overview

The Task Manager API is a cloud-native application designed for production deployment with a focus on security, scalability, and observability.

## System Architecture

```
                                    ┌─────────────────────────────────────────┐
                                    │           External Traffic              │
                                    └──────────────────┬──────────────────────┘
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    CLOUD PROVIDER                                    │
│                                  (AWS / Azure / GCP)                                │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                              KUBERNETES CLUSTER                                │  │
│  │                                                                               │  │
│  │   ┌─────────────┐    ┌──────────────────────────────────────────────────┐    │  │
│  │   │   Ingress   │    │                  Namespace: task-manager         │    │  │
│  │   │  Controller │◀──▶│  ┌────────────────────────────────────────────┐  │    │  │
│  │   │  (NGINX/ALB)│    │  │              Deployment                    │  │    │  │
│  │   └─────────────┘    │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐      │  │    │  │
│  │                      │  │  │ Pod     │ │ Pod     │ │ Pod     │      │  │    │  │
│  │                      │  │  │ FastAPI │ │ FastAPI │ │ FastAPI │      │  │    │  │
│  │                      │  │  │ :8000   │ │ :8000   │ │ :8000   │      │  │    │  │
│  │                      │  │  └────┬────┘ └────┬────┘ └────┬────┘      │  │    │  │
│  │                      │  │       │           │           │           │  │    │  │
│  │                      │  │       └───────────┴───────────┘           │  │    │  │
│  │                      │  │                   │                       │  │    │  │
│  │                      │  │  ┌────────────────▼────────────────────┐  │  │    │  │
│  │                      │  │  │          Service (ClusterIP)        │  │  │    │  │
│  │                      │  │  └─────────────────────────────────────┘  │  │    │  │
│  │                      │  └────────────────────────────────────────────┘  │    │  │
│  │                      │                                                   │    │  │
│  │                      │  ┌────────────────────────────────────────────┐  │    │  │
│  │                      │  │           HorizontalPodAutoscaler          │  │    │  │
│  │                      │  │      (Scale based on CPU utilization)      │  │    │  │
│  │                      │  └────────────────────────────────────────────┘  │    │  │
│  │                      └──────────────────────────────────────────────────┘    │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                           MANAGED SERVICES                                     │  │
│  │  ┌─────────────────────┐  ┌─────────────────────┐  ┌──────────────────────┐   │  │
│  │  │     PostgreSQL      │  │  Container Registry │  │   Secret Manager     │   │  │
│  │  │   (RDS / Azure DB)  │  │   (ECR / ACR)       │  │ (Secrets Manager/KV) │   │  │
│  │  │                     │  │                     │  │                      │   │  │
│  │  │  - Primary DB       │  │  - Docker images    │  │  - JWT secrets       │   │  │
│  │  │  - Automated backup │  │  - Vulnerability    │  │  - DB credentials    │   │  │
│  │  │  - Multi-AZ option  │  │    scanning         │  │  - API keys          │   │  │
│  │  └─────────────────────┘  └─────────────────────┘  └──────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                           OBSERVABILITY STACK                                  │  │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │  │
│  │  │   Prometheus    │───▶│     Grafana     │◀───│      Loki       │            │  │
│  │  │   (Metrics)     │    │   (Dashboards)  │    │     (Logs)      │            │  │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘            │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### Application Layer

| Component | Technology | Purpose |
|-----------|------------|---------|
| Web Framework | FastAPI | Async REST API with automatic OpenAPI docs |
| ORM | SQLAlchemy 2.0 | Database abstraction and query building |
| Migrations | Alembic | Database schema versioning |
| Authentication | python-jose | JWT token handling |
| Validation | Pydantic | Request/response validation |
| ASGI Server | Uvicorn | Production-grade async server |

### Data Layer

| Component | Technology | Purpose |
|-----------|------------|---------|
| Primary Database | PostgreSQL 15+ | ACID-compliant relational storage |
| Connection Pool | SQLAlchemy Pool | Efficient connection management |
| Migrations | Alembic | Schema version control |

### Infrastructure Layer

| Component | Options | Purpose |
|-----------|---------|---------|
| Container Runtime | Docker | Application containerization |
| Orchestration | Kubernetes | Container orchestration and scaling |
| IaC | Terraform | Infrastructure provisioning |
| Service Mesh | (Optional) Istio | Advanced traffic management |

## Cloud Provider Selection

### AWS Configuration

```hcl
# Use these Terraform modules for AWS:
module "vpc"        { source = "./modules/network" }
module "eks"        { source = "./modules/kubernetes" }
module "rds"        { source = "./modules/database" }
module "ecr"        { source = "./modules/registry" }
```

**Recommended AWS Services:**
- **EKS** - Managed Kubernetes
- **RDS PostgreSQL** - Managed database with Multi-AZ
- **ECR** - Container registry with vulnerability scanning
- **Secrets Manager** - Secure secret storage
- **CloudWatch** - Logging and monitoring (alternative to Loki)
- **ALB** - Application Load Balancer for Ingress

### Azure Configuration

```hcl
# Use these Terraform modules for Azure:
module "vnet"       { source = "./modules/network" }
module "aks"        { source = "./modules/kubernetes" }
module "postgresql" { source = "./modules/database" }
module "acr"        { source = "./modules/registry" }
```

**Recommended Azure Services:**
- **AKS** - Managed Kubernetes
- **Azure Database for PostgreSQL** - Managed database
- **ACR** - Azure Container Registry
- **Key Vault** - Secret management
- **Azure Monitor** - Logging and metrics
- **Application Gateway** - Ingress controller

### Switching Providers

1. Update `infra/terraform/envs/<env>/main.tf` with provider block
2. Set appropriate provider variables in `terraform.tfvars`
3. Run `terraform init` to download provider plugins
4. Modules are designed to be provider-agnostic where possible

## Security Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        SECURITY LAYERS                               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  NETWORK SECURITY                                              │  │
│  │  • VPC with private subnets                                    │  │
│  │  • Network Policies in K8s                                     │  │
│  │  • Security Groups / NSGs                                      │  │
│  │  • TLS termination at Ingress                                  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  APPLICATION SECURITY                                          │  │
│  │  • JWT authentication with expiry                              │  │
│  │  • Password hashing (bcrypt)                                   │  │
│  │  • Input validation (Pydantic)                                 │  │
│  │  • SQL injection prevention (SQLAlchemy ORM)                   │  │
│  │  • Non-root container execution                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  CI/CD SECURITY                                                │  │
│  │  • Dependency scanning (pip-audit)                             │  │
│  │  • Container scanning (Trivy)                                  │  │
│  │  • Secret scanning in repos                                    │  │
│  │  • Signed container images (optional)                          │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  DATA SECURITY                                                 │  │
│  │  • Encryption at rest (database)                               │  │
│  │  • Encryption in transit (TLS)                                 │  │
│  │  • Secrets management (K8s Secrets / External)                 │  │
│  │  • Principle of least privilege                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Scalability Design

### Horizontal Scaling

- **Application**: HPA scales pods based on CPU (target: 70%)
- **Database**: Read replicas for read-heavy workloads
- **Minimum**: 2 pods in production for high availability

### Vertical Scaling

| Environment | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-------------|-------------|-----------|----------------|--------------|
| Dev | 100m | 200m | 128Mi | 256Mi |
| Prod | 250m | 500m | 256Mi | 512Mi |

## Data Flow

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│ Client  │────▶│ Ingress │────▶│ Service │────▶│   Pod   │
│         │     │         │     │         │     │ FastAPI │
└─────────┘     └─────────┘     └─────────┘     └────┬────┘
                                                      │
                                                      ▼
                                               ┌─────────────┐
                                               │ PostgreSQL  │
                                               └─────────────┘

Request Flow:
1. Client sends HTTPS request
2. Ingress terminates TLS, routes to Service
3. Service load-balances to healthy Pod
4. FastAPI validates request, checks JWT
5. SQLAlchemy executes query against PostgreSQL
6. Response returns through the same path
```

## Observability

### Metrics (Prometheus)

Key application metrics exposed:
- `http_requests_total` - Request count by method, path, status
- `http_request_duration_seconds` - Request latency histogram
- `db_connections_active` - Active database connections
- `tasks_created_total` - Business metric: tasks created
- `users_registered_total` - Business metric: user registrations

### Logging (Structured JSON)

Log format:
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "message": "Request processed",
  "request_id": "abc-123",
  "method": "POST",
  "path": "/tasks",
  "status_code": 201,
  "duration_ms": 45
}
```

### Alerting Rules (Example)

| Alert | Condition | Severity |
|-------|-----------|----------|
| HighErrorRate | 5xx rate > 5% for 5min | Critical |
| HighLatency | p95 latency > 500ms for 5min | Warning |
| PodCrashLooping | Pod restarts > 5 in 10min | Critical |
| DatabaseConnectionsHigh | Connections > 80% pool | Warning |

## Disaster Recovery

### Backup Strategy

| Component | Backup Method | Retention | RPO |
|-----------|---------------|-----------|-----|
| Database | Automated snapshots | 7 days | 1 hour |
| Secrets | Version controlled | Indefinite | 0 |
| Container Images | Registry retention | 30 days | 0 |

### Recovery Procedures

See [runbooks/incident-response.md](runbooks/incident-response.md) for detailed procedures.

## Future Architecture Considerations

1. **Service Mesh**: Add Istio for mTLS, traffic management
2. **Caching**: Redis for session and query caching
3. **CDN**: CloudFront/Azure CDN for static assets
4. **Multi-Region**: Active-passive failover
5. **Event-Driven**: Add Kafka/SQS for async processing
