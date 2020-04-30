provider "azurerm" {
    version = "~> 2.1.0"
    features {}
}

resource "azurerm_resource_group" "rg" {
    name     = "${var.conpany_cd}-${var.department_cd}-${var.workshop_cd}-${var.ResourceGroup_Suffix}"
    location = "${var.location}"
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.conpany_cd}${var.department_cd}${var.workshop_cd}${var.ADLS_Suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_replication_type = "RAGRS"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  access_tier             = "Hot" 
  enable_https_traffic_only = "true"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_container" "sc" {
  name                  = "streaming-raw"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "container"
}

resource "azurerm_iothub" "iot" {
  name                = "${var.conpany_cd}-${var.department_cd}-${var.workshop_cd}-${var.IoT_Suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "F1"
    capacity = "1"
  }

}

resource "azurerm_iothub_consumer_group" "iotcg" {
  name                   = "streamanalytics"
  iothub_name            = azurerm_iothub.iot.name
  eventhub_endpoint_name = "events"
  resource_group_name    = azurerm_resource_group.rg.name
}



resource "azurerm_stream_analytics_job" "asa" {
  name                                     = "${var.conpany_cd}-${var.department_cd}-${var.workshop_cd}-${var.ASA_Suffix}"
  resource_group_name                      = azurerm_resource_group.rg.name
  location                                 = azurerm_resource_group.rg.location
  compatibility_level                      = "1.0"
  data_locale                              = "en-US"
  events_late_arrival_max_delay_in_seconds = 5
  events_out_of_order_max_delay_in_seconds = 0
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Stop"
  streaming_units                          = 1

  transformation_query = <<QUERY
    SELECT *
    INTO [Blob]
    FROM [IoThub]
QUERY
}

resource "azurerm_stream_analytics_stream_input_iothub" "asainputs" {
  name                         = "IoThub"
  resource_group_name          = azurerm_resource_group.rg.name

  stream_analytics_job_name    = azurerm_stream_analytics_job.asa.name
  eventhub_consumer_group_name = azurerm_iothub_consumer_group.iotcg.name

  endpoint                     = "messages/events"
  iothub_namespace             = azurerm_iothub.iot.name

  shared_access_policy_name    = azurerm_iothub.iot.shared_access_policy[0].key_name
  shared_access_policy_key     = azurerm_iothub.iot.shared_access_policy[0].primary_key

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azurerm_stream_analytics_output_blob" "asaoutputs" {
  name                      = "Blob"
  resource_group_name       = azurerm_resource_group.rg.name

  stream_analytics_job_name = azurerm_stream_analytics_job.asa.name
  storage_account_name      = azurerm_storage_account.sa.name
  storage_account_key       = azurerm_storage_account.sa.primary_access_key
  storage_container_name    = azurerm_storage_container.sc.name
  path_pattern              = "telemetry"
  date_format               = "yyyy/MM/dd"
  time_format               = "HH"

  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format = "Array"
  }
}
