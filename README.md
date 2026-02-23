# Task Manager API

A production-ready cloud application demonstrating modern DevOps practices with FastAPI, PostgreSQL, Kubernetes, and Terraform.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PRODUCTION ENVIRONMENT                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    ┌──────────────────────────────────────────────────┐   │
│  │   Ingress    │───▶│              Kubernetes Cluster                  │   │
│  │  Controller  │    │  ┌─────────────────────────────────────────────┐ │   │
│  └──────────────┘    │  │           Task Manager Service              │ │   │
│                      │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐       │ │   │
│                      │  │  │ Pod 1   │ │ Pod 2   │ │ Pod N   │       │ │   │
│                      │  │  │ FastAPI │ │ FastAPI │ │ FastAPI │       │ │   │
│                      │  │  └────┬────┘ └────┬────┘ └────┬────┘       │ │   │
│                      │  │       │           │           │             │ │   │
│                      │  │       └───────────┼───────────┘             │ │   │
│                      │  │                   ▼                         │ │   │
│                      │  │          ┌────────────────┐                 │ │   │
│                      │  │          │  PostgreSQL    │                 │ │   │
│                      │  │          │  (Managed RDS) │                 │ │   │
│                      │  │          └────────────────┘                 │ │   │
│                      │  └─────────────────────────────────────────────┘ │   │
│                      └──────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        Observability Stack                            │   │
│  │   ┌───────────┐    ┌───────────┐    ┌───────────┐                   │   │
│  │   │Prometheus │───▶│  Grafana  │◀───│   Loki    │                   │   │
│  │   │ (Metrics) │    │(Dashboard)│    │  (Logs)   │                   │   │
│  │   └───────────┘    └───────────┘    └───────────┘                   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                               CI/CD PIPELINE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐        │
│  │  Push  │───▶│  Lint  │───▶│  Test  │───▶│  Build │───▶│  Scan  │        │
│  │  Code  │    │ + Fmt  │    │ pytest │    │ Docker │    │ Trivy  │        │
│  └────────┘    └────────┘    └────────┘    └────────┘    └────────┘        │
│                                                                │             │
│                                                                ▼             │
│                                              ┌────────┐    ┌────────┐       │
│                                              │ Deploy │◀───│  Push  │       │
│                                              │  K8s   │    │Registry│       │
│                                              └────────┘    └────────┘       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **REST API**: Full CRUD operations for Task management
- **JWT Authentication**: Secure user registration and login
- **PostgreSQL**: Persistent data storage with SQLAlchemy ORM
- **Docker**: Multi-stage build with non-root user
- **Kubernetes**: Production-ready manifests with HPA, NetworkPolicy
- **Terraform**: Infrastructure as Code for AWS/Azure
- **CI/CD**: GitHub Actions with security scanning
- **Observability**: Prometheus metrics, Grafana dashboards, Loki logs

## Quick Start (Local Development)

### Prerequisites

- Docker & Docker Compose
- Python 3.11+
- Make (optional)

### One-Command Local Run

```bash
# Clone and start
git clone <repository-url>
cd task-manager-api

# Start all services
docker-compose -f deploy/docker-compose.yml up --build

# API available at http://localhost:8000
# Swagger docs at http://localhost:8000/docs
```

### Manual Setup

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Run bootstrap script
./scripts/dev_bootstrap.sh

# 3. Start services
docker-compose -f deploy/docker-compose.yml up --build

# 4. Run migrations (in another terminal)
./scripts/migrate.sh
```

## API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/register` | Register new user | No |
| POST | `/auth/login` | Login, get JWT token | No |
| GET | `/tasks` | List user's tasks | Yes |
| POST | `/tasks` | Create new task | Yes |
| GET | `/tasks/{id}` | Get task details | Yes |
| PUT | `/tasks/{id}` | Update task | Yes |
| DELETE | `/tasks/{id}` | Delete task | Yes |
| GET | `/health` | Health check | No |
| GET | `/metrics` | Prometheus metrics | No |

## Project Structure

```
.
├── README.md
├── docs/
│   ├── architecture.md
│   ├── decision-records/
│   └── runbooks/
├── src/app/
│   ├── main.py
│   ├── api/              # API routes
│   ├── core/             # Config, security, deps
│   ├── db/               # Database connection
│   ├── models/           # SQLAlchemy models
│   ├── services/         # Business logic
│   └── tests/            # pytest tests
├── docker/
│   └── Dockerfile
├── deploy/
│   ├── docker-compose.yml
│   └── k8s/
│       ├── base/
│       └── overlays/
├── infra/terraform/
│   ├── modules/
│   └── envs/
├── .github/workflows/
│   ├── ci.yml
│   └── cd.yml
└── scripts/
```

## CI/CD Pipeline

### Continuous Integration (ci.yml)

Runs on every PR and push:
1. **Lint & Format**: ruff + black check
2. **Test**: pytest with coverage
3. **Build**: Docker image build
4. **Dependency Scan**: pip-audit
5. **Container Scan**: Trivy vulnerability scan
6. **Artifacts**: Test reports uploaded

### Continuous Deployment (cd.yml)

Runs on main branch merge:
1. Build and tag Docker image
2. Push to container registry
3. Deploy to Kubernetes via kubectl/kustomize

### Required GitHub Secrets

| Secret Name | Description |
|-------------|-------------|
| `REGISTRY_URL` | Container registry URL |
| `REGISTRY_USERNAME` | Registry username |
| `REGISTRY_PASSWORD` | Registry password/token |
| `KUBE_CONFIG` | Base64-encoded kubeconfig |
| `JWT_SECRET_KEY` | JWT signing key |
| `DATABASE_URL` | Production database URL |

## Deployment

### Kubernetes Deployment

```bash
# Dev environment
kubectl apply -k deploy/k8s/overlays/dev/

# Production environment
kubectl apply -k deploy/k8s/overlays/prod/

# Verify deployment
kubectl get pods -n task-manager
```

### Terraform Infrastructure

```bash
cd infra/terraform/envs/dev

# Initialize
terraform init

# Plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"
```

See [docs/architecture.md](docs/architecture.md) for AWS vs Azure guidance.

## Security Notes

### Implemented Security Measures

- **JWT Authentication**: Tokens expire after 30 minutes
- **Password Hashing**: bcrypt with salt
- **Non-root Container**: Application runs as unprivileged user
- **Dependency Scanning**: pip-audit in CI pipeline
- **Container Scanning**: Trivy scans for CVEs
- **Network Policies**: K8s NetworkPolicy restricts traffic
- **Secrets Management**: K8s Secrets with base64 encoding
- **Input Validation**: Pydantic models validate all inputs

### Security Best Practices

1. Rotate JWT secret keys regularly
2. Use external secret management (Vault, AWS Secrets Manager)
3. Enable TLS/SSL in production
4. Review and update dependencies frequently
5. Implement rate limiting for auth endpoints

## Observability

### Metrics (Prometheus)

- Application exposes `/metrics` endpoint
- Custom metrics: request latency, active users, task counts
- Prometheus scrapes metrics every 15s

### Dashboards (Grafana)

Import the starter dashboard from `deploy/k8s/base/observability/grafana-dashboard.json`

### Logging (Loki)

- Structured JSON logging
- Log aggregation via Loki
- Query logs in Grafana

## Testing

```bash
# Run all tests
pytest src/app/tests/ -v

# With coverage
pytest src/app/tests/ -v --cov=src/app --cov-report=html

# Run specific test
pytest src/app/tests/test_tasks.py -v
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | - |
| `JWT_SECRET_KEY` | Secret for JWT signing | - |
| `JWT_ALGORITHM` | JWT algorithm | HS256 |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token expiry | 30 |
| `DEBUG` | Enable debug mode | false |
| `LOG_LEVEL` | Logging level | INFO |

## Future Improvements

- [ ] Add Redis caching layer
- [ ] Implement rate limiting
- [ ] Add OpenTelemetry tracing
- [ ] Multi-tenant support
- [ ] GraphQL API option
- [ ] Helm chart for K8s deployment
- [ ] ArgoCD GitOps integration
- [ ] Database read replicas
- [ ] Blue-green deployments
- [ ] Chaos engineering tests
- [ ] API versioning (v1, v2)
- [ ] WebSocket support for real-time updates

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file.
