output "build_servers" {
	value = { for k, v in azurerm_virtual_network.build_pool : 
		k => {
			address_space = v.address_space[0]
			vnet_id = v.id
			vnet_name = v.name
			vnet_rg_name = v.resource_group_name
			subnet_id = azurerm_subnet.build_pool_lan[k].id
			ngw_pip = azurerm_public_ip.build_pool_ngw[k].ip_address
		}
	}
}

output "build_servers_mi" {
	value = azurerm_user_assigned_identity.build_pool
}

output "build_servers_mi_per_mg" {
	value = azurerm_user_assigned_identity.build_pool_mi_per_mg
}

output "container_registry" {
	value = {
		id = azurerm_container_registry.common.id
		name = azurerm_container_registry.common.name
		fqdn = azurerm_container_registry.common.login_server
	}
}

output "container_registry_2" {
	value = {
		id = azurerm_container_registry_2.common2.id
		name = azurerm_container_registry_2.common2.name
		fqdn = azurerm_container_registry_2.common2.login_server
	}
}
output "container_registries" {
	value = { for acr in [azurerm_container_registry.common,azurerm_container_registry.common2] : 
		acr.name => {
			id = acr.id
			name = acr.name
			fqdn = acr.login_server
		}
	}
}

output "event_hub_diag_logging" {
	value = { for k, v in local.envs_to_regions : k =>
		{
			name = azurerm_eventhub_namespace.diag_logging[k].name
			diag_logging_auth_rule_id = azurerm_eventhub_namespace_authorization_rule.default_diag_logging[k].id
			splunk_auth_rule_id = azurerm_eventhub_namespace_authorization_rule.default_splunk[k].id
		}
	}
}

output "key_vaults" {
	value = {
		infra = merge(
			{ for k, v in azurerm_key_vault.infra :
				k => {
					id = v.id
					name = v.name
					resource_group_name = v.resource_group_name
				}
			},
			{
				common = { for k, v in local.region_shorts :
					k => {
						id = azurerm_key_vault.infra_common[v].id
						name = azurerm_key_vault.infra_common[v].name
						resource_group_name = azurerm_key_vault.infra_common[v].resource_group_name
					}
				}
			}
		)
		scm = { for k, v in azurerm_key_vault.scm :
			k => {
				id = v.id
				name = v.name
				resource_group_name = v.resource_group_name
			}
		}
		common_enc = { for k, v in azurerm_key_vault.common_enc :
			k => {
				id = v.id
				name = v.name
				resource_group_name = v.resource_group_name
			}
		}
	}
}

output "log_analytics" {
	sensitive = true

	value = {
		default = {
			id = azurerm_log_analytics_workspace.common.id
			name = azurerm_log_analytics_workspace.common.name
			workspace_id = azurerm_log_analytics_workspace.common.workspace_id
			location = azurerm_log_analytics_workspace.common.location
			keys = {
				primary = azurerm_log_analytics_workspace.common.primary_shared_key
				secondary = azurerm_log_analytics_workspace.common.secondary_shared_key
			}
		}
	}
}

output "ama_data_collection" {
	value = {
		rules = { for k, v in azurerm_monitor_data_collection_rule.ama_dc_rules : 
			k => {
				id = v.id
				name = v.name
			}
		}
		endpoints = { for k, v in azurerm_monitor_data_collection_endpoint.ama_dc_endpoint : 
			k => {
				id = v.id
			}
		}
	}
}
output "resource_groups" {
	value = { for k, v in azurerm_resource_group.common :
		k => {
			name = azurerm_resource_group.common[k].name
			location = azurerm_resource_group.common[k].location
		}
	}
}

output "storage_accounts" {
	sensitive = true

	value = {
		print = {
			id = azurerm_storage_account.print.id
			name = azurerm_storage_account.print.name
			rg_name = azurerm_storage_account.print.resource_group_name
			primary_connection_string = azurerm_storage_account.print.primary_connection_string
		}
		tools = {
			id = azurerm_storage_account.tools.id
			name = azurerm_storage_account.tools.name
			rg_name = azurerm_storage_account.tools.resource_group_name
			primary_connection_string = azurerm_storage_account.tools.primary_connection_string
		}
	}
}
output "fcx_vnet" {
	value = { for k, v in azurerm_virtual_network.common_fcx_vnet : 
		k => {
			address_space = v.address_space[0]
			vnet_id = v.id
			vnet_name = v.name
			vnet_rg_name = v.resource_group_name
			# subnet_id = azurerm_subnet.build_pool_lan[k].id
			# ngw_pip = azurerm_public_ip.build_pool_ngw[k].ip_address
		}
	}
}

output "openai_master_instance" {
	value = azurerm_cognitive_account.openai_master_instance
}

