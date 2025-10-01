#----- Create the container registry
resource "azurerm_container_registry" "common" {
	provider = azurerm.common

	name = "acrapp${local.app_short}commoneus201"
	resource_group_name = azurerm_resource_group.common["infra_eus2"].name
	location = azurerm_resource_group.common["infra_eus2"].location
	
	sku = "Premium"
	
	admin_enabled = false
	
	georeplications {
			location = "West US 2"
			zone_redundancy_enabled = false
			regional_endpoint_enabled = true
			tags = local.common_tags
	}
 	
	tags = local.common_tags
	
	lifecycle {
		ignore_changes = [ georeplications[0].tags, tags ]
	}
}

#----- Enable diagnostic logging
data "azurerm_monitor_diagnostic_categories" "common_acr" {
	resource_id = azurerm_container_registry.common.id
}

resource "azurerm_monitor_diagnostic_setting" "common_acr" {
	provider = azurerm.common

	name = "log_all"
	target_resource_id = azurerm_container_registry.common.id
	
	log_analytics_workspace_id = azurerm_log_analytics_workspace.common.id
	
	dynamic "enabled_log" {
		for_each = data.azurerm_monitor_diagnostic_categories.common_acr.logs
		
		content {
			category = enabled_log.value
		}
	}
	
	dynamic "metric" {
		for_each = data.azurerm_monitor_diagnostic_categories.common_acr.metrics
		
		content {
			category = metric.value
			enabled = true
		}
	}
}

locals{
	container_registry_name = lower("acrapp${local.app_short}commoneus202")
}


#----- Create the new container registry
resource "azurerm_container_registry" "common2" {
	provider = azurerm.common

	name = local.container_registry_name
	resource_group_name = azurerm_resource_group.common["infra_eus2"].name
	location = azurerm_resource_group.common["infra_eus2"].location
	
	sku = "Premium"
	
	admin_enabled = false
	
	georeplications {
		location = "West US 2"
		zone_redundancy_enabled = false
		regional_endpoint_enabled = true
		tags = local.common_tags
	}
 	
	identity {
		type = "UserAssigned"
		identity_ids = [ azurerm_user_assigned_identity.common2_uai.id ]
  	}

	encryption {
		enabled = true
		key_vault_key_id = azurerm_key_vault_key.common2_cmk["${local.container_registry_name}_${local.environments["common"].keepers.encryption_key_use}"].versionless_id
		identity_client_id = azurerm_user_assigned_identity.common2_uai.client_id 
  	}

	tags = local.common_tags
	
	lifecycle {
		ignore_changes = [ georeplications[0].tags, tags ]
	}

	depends_on = [ azurerm_key_vault_key.common2_cmk,azurerm_user_assigned_identity.common2_uai ]
}


#----- Create the CMK used to encrypt new Container Registry
resource "azurerm_key_vault_key" "common2_cmk" {
	provider = azurerm.common

	for_each = { for k, v in (flatten(
		[ for suffix in local.environments["common"].keepers.encryption_key_suffixes :
			{
				acr_name = local.container_registry_name
				suffix = suffix
			}
		]
	)) : "${v.acr_name}_${v.suffix}" => v }

	name = "${each.value.acr_name}--${each.value.suffix}"
	key_vault_id = azurerm_key_vault.common_enc["eus2"].id
	key_type = "RSA-HSM"
	key_size = 2048
	
	key_opts = [ "encrypt", "decrypt", "sign", "verify", "unwrapKey", "wrapKey" ]

}

#----- Create identities for new Container Registry
resource "azurerm_user_assigned_identity" "common2_uai" {
	name = local.container_registry_name
	resource_group_name = azurerm_resource_group.common["infra_eus2"].name
	location = azurerm_resource_group.common["infra_eus2"].location
	
	tags = local.common_tags

	lifecycle {
		ignore_changes = [ tags ]
	}
}

#----- Enable diagnostic logging
data "azurerm_monitor_diagnostic_categories" "common2_acr" {
	resource_id = azurerm_container_registry.common2.id
}

resource "azurerm_monitor_diagnostic_setting" "common2_acr" {
	provider = azurerm.common

	name = "acr_log_all"
	target_resource_id = azurerm_container_registry.common2.id
	
	log_analytics_workspace_id = azurerm_log_analytics_workspace.common.id
	
	dynamic "enabled_log" {
		for_each = data.azurerm_monitor_diagnostic_categories.common2_acr.logs
		
		content {
			category = enabled_log.value
		}
	}
	
	dynamic "metric" {
		for_each = data.azurerm_monitor_diagnostic_categories.common2_acr.metrics
		
		content {
			category = metric.value
			enabled = true
		}
	}
}
