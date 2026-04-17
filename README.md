# Coffee Shop Fullstack — Docker Compose + Azure Container Apps

A fullstack web application for a coffee shop featuring a static frontend, a Flask REST API for managing reservations, and a MySQL database — all containerized with Docker and deployed to Azure Container Apps using Terraform and GitHub Actions.

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │     Azure Container Apps Environment    │
                    │                                         │
  Users ──────────► │  ┌───────────┐    ┌───────────────┐     │
                    │  │  Frontend │    │   Flask API   │     │
                    │  │  (Nginx)  │───►│  (Python)     │     │
                    │  │  Port 80  │    │  Port 5000    │     │
                    │  └───────────┘    └───────┬───────┘     │
                    │                           │             │
                    │              ┌────────────▼───────────┐ │
                    │              │  Azure MySQL Flexible  │ │
                    │              │  Server (Managed)      │ │
                    │              │  Port 3306             │ │
                    │              └────────────────────────┘ │
                    └─────────────────────────────────────────┘
```

## Tech Stack

| Component        | Technology                  | Purpose                               |
|------------------|-----------------------------|---------------------------------------|
| Frontend         | Nginx                       | Serves the static coffee shop website |
| API              | Flask (Python)              | REST API for reservation management   |
| Database (Local) | MySQL 8 (Container)         | Local development via Docker Compose  |
| Database (Cloud) | Azure MySQL Flexible Server | Managed database in production        |
| IaC              | Terraform                   | Infrastructure provisioning on Azure  |
| CI/CD            | GitHub Actions              | Automated build and deployment        |
| Registry         | Docker Hub                  | Container image storage               |
| Cloud            | Azure Container Apps        | Production hosting                    |

## Project Structure

```
coffeeshop-fullstack/
├── .github/
│   └── workflows/
│       ├── infra.yml            # Terraform plan + apply with manual approval
│       └── deploy-apps.yml      # Docker build + push to Docker Hub
├── Infrastructure/
│   ├── main.tf                  # Azure resources (ACA, MySQL Flexible Server)
│   ├── variables.tf             # Variable declarations
│   └── terraform.tfvars         # Variable values
├── api/
│   ├── Dockerfile               # Python 3.12-slim based image
│   ├── app.py                   # Flask API with reservation endpoints
│   └── requirements.txt         # Python dependencies
├── db/
│   └── init.sql                 # Database schema and seed data (local only)
├── frontend/
│   ├── Dockerfile               # Nginx based image
│   └── site/                    # Static HTML/CSS/JS files
├── docker-compose.yml           # Local development environment
├── .gitignore
└── README.md
```

## API Endpoints

| Method | Route                    | Description                |
|--------|-------------------------------------------------------|
| GET    | `/api/health`            | Health check               |
| GET    | `/api/reservations`      | List all reservations      |
| POST   | `/api/reservations`      | Create a new reservation   |
| DELETE | `/api/reservations/<id>` | Delete a reservation by ID |

### POST Request Body

```json
{
  "name": "John Doe",
  "email": "john@email.com",
  "phone": "514-555-0001",
  "date": "2026-04-25",
  "time": "18:00",
  "guests": 4,
  "message": "Table near the window"
}
```

## Local Development

### Prerequisites

- Docker Desktop installed and running

### Run Locally

```bash
docker compose up -d --build
```

This starts three containers: Nginx (frontend), Flask (API), and MySQL 8 (database). The `db/init.sql` file automatically creates the schema and inserts sample data.

### Available Services

| Service | URL |
|---------|-----|
| Frontend | http://localhost:8090 |
| API | http://localhost:5000/api/reservations |
| MySQL | localhost:3306 |

### Stop Services

```bash
# Stop containers (keep data)
docker compose down

# Stop containers and remove data
docker compose down -v
```

## Cloud Deployment

### Prerequisites

1. Azure CLI installed and logged in
2. Register required Azure providers:
   ```bash
   az provider register --namespace Microsoft.App
   az provider register --namespace Microsoft.OperationalInsights
   ```
3. Create Terraform backend storage (one-time setup):
   ```bash
   az group create --name rg-terraform-state --location eastus2
   az storage account create --name tfstateyancy --resource-group rg-terraform-state --sku Standard_LRS
   az storage container create --name tfstate --account-name tfstateyancy
   ```

### Azure Resources

The Terraform configuration provisions the following:

| Resource | Purpose |
|----------|---------|
| Resource Group | Logical container for all resources |
| Log Analytics Workspace | Centralized logging for Container Apps |
| Container Apps Environment | Internal network where containers communicate |
| Container App (web) | Nginx frontend with external ingress on port 80 |
| Container App (api) | Flask API with external ingress on port 5000 |
| MySQL Flexible Server | Managed database (Burstable B1ms, 20GB storage) |
| MySQL Firewall Rule | Allows access from Azure services |
| MySQL Database | The `coffeeshop` database |

### Database: Local vs Cloud

| Feature | Local (Docker Compose) | Cloud (Azure) |
|---------|----------------------|---------------|
| Type | MySQL 8 container | Azure MySQL Flexible Server |
| Schema setup | `db/init.sql` mounted as volume | `init_db()` function in `app.py` |
| Persistence | Docker volume (lost with `down -v`) | Managed by Azure (automatic backups) |
| Connection | `db` hostname (Docker network) | FQDN via Terraform output |

The API includes an `init_db()` function that automatically creates the `reservations` table on startup using `CREATE TABLE IF NOT EXISTS`, replacing the need for `init.sql` in the cloud environment.

## CI/CD Pipelines

### Infrastructure Pipeline (`infra.yml`)

Triggered by changes in `Infrastructure/**`. Uses a two-stage approach with manual approval.

1. **Terraform Plan** — runs automatically, shows what will be created or changed
2. **Terraform Apply** — requires manual approval in the `production` environment

### Application Pipeline (`deploy-apps.yml`)

Triggered by changes in `api/**`, `frontend/**`, or `db/**`.

1. Checks out the code
2. Logs into Docker Hub
3. Builds and pushes `coffeeshop-api` image
4. Builds and pushes `coffeeshop-web` image

Both pipelines support `workflow_dispatch` for manual triggering from the GitHub Actions tab.

## Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_AD_CLIENT_ID` | Azure Service Principal client ID |
| `AZURE_AD_CLIENT_SECRET` | Azure Service Principal secret |
| `AZURE_AD_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (Read & Write) |

### GitHub Environment

A `production` environment with required reviewers must be configured under **Settings → Environments** for the manual approval gate on infrastructure deployments.

## Remote State

Terraform state is stored in Azure Blob Storage to prevent state conflicts across pipeline runs.

| Setting | Value |
|---------|-------|
| Resource Group | `rg-terraform-state` |
| Storage Account | `tfstateyancy` |
| Container | `tfstate` |
| State File | `coffeeshop.tfstate` |

## Author

**Yency Rafael**
