provider "azurerm" {
    version = "~> 2.1.0"
    features {}
}

resource "azurerm_resource_group" "rg" {
    name     = "${var.conpany_cd}-${var.department_cd}-${var.workshop_cd}-${var.ResourceGroup_Suffix}"
    location = "${var.location}"
}

resource "azurerm_data_factory" "adf" {
  name                = "${var.conpany_cd}-${var.department_cd}-${var.workshop_cd}-${var.ADF_Suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_sql_server" "sql" {
  name                         = "${var.conpany_cd}-${var.department_cd}-${var.workshop_cd}-${var.SQL_Suffix}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "mradministrator"
  administrator_login_password = "thisIsDog11"
}

resource "azurerm_sql_database" "sqldw" {
  name                = "${var.conpany_cd}-${var.department_cd}-${var.workshop_cd}-${var.SQLDW_Suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sql.name

  requested_service_objective_name = "DW100c"
  edition = "DataWarehouse"
  collation = "Japanese_XJIS_100_CI_AS"
}

resource "azurerm_sql_firewall_rule" "firewall" {
  name                = "AllowAllWindowsAzureIps"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}