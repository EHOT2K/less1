resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

#resource "azurerm_resource_group" "example" {
#  name     = "example-resources"
#  location = var.resource_group_location
# }

resource "azurerm_sql_server" "ms_sql_sever" {
  name                         = "ehotsqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = var.sql_admin_name
  administrator_login_password = random_password.password.result

  tags = {
    environment = "production"
  }
}

# resource "azurerm_storage_account" "rg" {
#   name                     = "ehotdbsa"
#   resource_group_name      = azurerm_resource_group.rg.name
#   location                 = var.resource_group_location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
# }


resource "azurerm_sql_database" "sql_database" {
  name                = "ehotdatabase"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  server_name         = azurerm_sql_server.ms_sql_sever.name

  tags = {
    environment = "production"
  }
}
#-------------------------------------------------------------------------------------------
#  APP section
#-------------------------------------------------------------------------------------------

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "ehot-appserviceplan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "app_service" {
  name                = "ehot-app-service"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id

  # site_config {
  #   dotnet_framework_version = "v4.0"
  #   scm_type                 = "LocalGit"
  # }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

  connection_string {
    name  = "ehotsqlserver"
    type  = "SQLServer"
    value = "Server=tcp:${azurerm_sql_server.ms_sql_sever.fully_qualified_domain_name},1433;Database=${azurerm_sql_database.sql_database.name};User ID=var.sql_admin_name;Password=random_password.password.result;Trusted_Connection=False;Encrypt=True;"
  }
}