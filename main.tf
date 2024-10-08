resource "random_string" "db_pass" {
  length           = 16
  special          = true
  override_special = "=@$!"
}

resource "azurerm_resource_group" "rg" {
  location = try(local.values.location, null)
  name     = "${local.values.prefix}-${var.env}-rg"
}

resource "azurerm_network_security_group" "nsg" {
  location            = try(local.values.location, null)
  name                = "${local.values.prefix}-${var.env}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route_table" "rt" {
  location            = try(local.values.location, null)
  name                = "${local.values.prefix}-${var.env}-rt"
  resource_group_name = azurerm_resource_group.rg.name
}

module "demo-vnet" {
  source              = "Azure/vnet/azurerm"
  vnet_name           = "${local.values.prefix}-${var.env}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  use_for_each        = true
  address_space       = try(local.values.vnet.cidr, [])
  subnet_prefixes     = [for x in try(local.values.vnet.subnets, [{}]) : x.prefix]
  subnet_names        = [for x in try(local.values.vnet.subnets, [{}]) : x.name]
  vnet_location       = try(local.values.location, null)

  nsg_ids = { for x in try(local.values.vnet.subnets, [{}]) : x.name => azurerm_network_security_group.nsg.id }

  subnet_service_endpoints = {
    for x in try(local.values.vnet.subnets, [{}]) :
    x.name => x.service_endpoints if contains(keys(x), "service_endpoints")
  }

  subnet_delegation = {
    for x in try(local.values.vnet.subnets, [{}]) :
    x.name => x.delegations if contains(keys(x), "delegations")
  }

  route_tables_ids = { for x in try(local.values.vnet.subnets, [{}]) : x.name => azurerm_route_table.rt.id }

  tags = merge(
    try(local.values.tags, {}),
    try(local.values.vnet.tags, {})
  )
}

module "demo-postgresql" {
  source = "Azure/postgresql/azurerm"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  server_name                      = "${local.values.prefix}-${var.env}-psql"
  sku_name                         = try(local.values.psql_server.sku, "")
  storage_mb                       = try(local.values.psql_server.storage_mb, 1024)
  auto_grow_enabled                = try(local.values.psql_server.auto_grow_enabled, false)
  backup_retention_days            = try(local.values.psql_server.backup_retention_days, 7)
  geo_redundant_backup_enabled     = try(local.values.psql_server.geo_redundant_backup_enabled, false)
  administrator_login              = try(local.values.psql_server.admin_login, "")
  administrator_password           = random_string.db_pass.id
  server_version                   = try(local.values.psql_server.server_version, "")
  ssl_enforcement_enabled          = try(local.values.psql_server.ssl_enabled, true)
  ssl_minimal_tls_version_enforced = try(local.values.psql_server.ssl_min_tls_version, "")
  public_network_access_enabled    = try(local.values.psql_server.public_access_enabled, false)
  db_names                         = try(local.values.psql_server.db_names, [""])
  db_charset                       = try(local.values.psql_server.db_charset, "")
  db_collation                     = try(local.values.psql_server.db_collation, "")

  firewall_rule_prefix = "${local.values.prefix}-${var.env}-fw-rule-"
  firewall_rules       = try(local.values.psql_server.fw_rules, [{}])

  vnet_rule_name_prefix = "${local.values.prefix}-${var.env}-psql-vnet-rule-"
  vnet_rules = [
    for x in try(local.values.psql_server.vnet_rules, []) : {
      name      = x,
      subnet_id = lookup(module.demo-vnet.vnet_subnets_name_id, x)
    }
  ]

  tags = merge(
    try(local.values.tags, {}),
    try(local.values.psql_server.tags, {})
  )

  postgresql_configurations = {
    backslash_quote = "on",
  }
}

resource "azurerm_container_registry" "acr" {
  name                          = "${local.values.prefix}${var.env}registry"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = try(local.values.acr.sku, "")
  admin_enabled                 = try(local.values.acr.admin_enabled, false)
  public_network_access_enabled = try(local.values.acr.public_access_enabled, false)
  anonymous_pull_enabled        = try(local.values.acr.anonymous_pull_enabled, false)
}
