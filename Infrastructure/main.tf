terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateyancy"
    container_name       = "tfstate"
    key                  = "coffeeshop.tfstate"
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}


resource "azurerm_resource_group" "rg" {
  name      = var.rg_name
  location  = var.location
}

# Define the Log Analytics Workspace (Required for logging)
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "logs-coffeeshop"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = "cae-coffeeshop"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

resource "azurerm_container_app" "db" {
  name                         = "coffeeshop-db"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "mysql"
      image  = "mysql:8"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "MYSQL_ROOT_PASSWORD"
        value = var.db_password
      }
      env {
        name  = "MYSQL_DATABASE"
        value = "coffeeshop"
      }
    }
  }
}

resource "azurerm_container_app" "api" {
  name                         = "coffeeshop-api"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "api"
      image  = var.api_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "DB_HOST"
        value = "coffeeshop-db"
      }
      env {
        name  = "DB_USER"
        value = "root"
      }
      env {
        name  = "DB_PASSWORD"
        value = var.db_password
      }
      env {
        name  = "DB_NAME"
        value = "coffeeshop"
      }
    }
  }

    ingress {
    external_enabled = true
    target_port      = 5000
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

resource "azurerm_container_app" "web" {
  name                         = "coffeeshop-web"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "web"
      image  = var.web_image
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}



