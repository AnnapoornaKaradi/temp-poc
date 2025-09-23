#----- Add all the providers
provider "azurerm" {
	subscription_id = var.subscription_id
	tenant_id = var.tenant_id

	features {
		key_vault {
			purge_soft_deleted_keys_on_destroy = false
			purge_soft_deleted_secrets_on_destroy = false
		}
	}
}

# Add blocks for providers which don't need additional configuration
provider "azapi" {}
provider "azuread" {}
provider "dns" {}
provider "external" {}
provider "local" {}
provider "null" {}
provider "pkcs12" {}
provider "random" {}
provider "time" {}
provider "tls" {}

terraform {
	// required_version = "= 0.13.7" # removing this will allow controlling version via build pool
	required_providers {
		azapi = {
			source = "azure/azapi"		
			version = "~> 1.12.0"
		}
		azurerm = {
			source  = "hashicorp/azurerm"
			version = "~> 3.117.0"
		}
		azuread = {
			source = "hashicorp/azuread"
			version = "~> 2.46.0"
		}
		dns = {
			source = "hashicorp/dns"
			version = "~> 3.2"
		}
		external = {
			source  = "hashicorp/external"
			version = "~> 2.1"
		}
		helm = {
			source = "hashicorp/helm"
			version = "~> 2.16.0"
		}
		kubernetes = {
			source = "hashicorp/kubernetes"
			version = "~> 2.17"
		}
		local = {
			source  = "hashicorp/local"
			version = "~> 2.1"
		}
		null = {
			source  = "hashicorp/null"
			version = "~> 3.1"
		}
		pkcs12 = {
			source = "chilicat/pkcs12"
			version = "~> 0.2.5"
		}
		random = {
			source = "hashicorp/random"
			version = "~> 3.4.1"
		}
		restapi = {
			source = "Mastercard/restapi"
			version = "1.20.0"
		}
		time = {
			source = "hashicorp/time"
			version = "~> 0.5"
		}
		tls = {
			source = "hashicorp/tls"
			version = "~> 3.4.0"
		}
	}	

	# The backend config is built in the pipeline
	backend "azurerm" {}
}

#----- Common subscription provider
provider "azurerm" {
	alias = "common"
	
	subscription_id = var.common_subscription_id[var.app_ref]
	tenant_id = var.tenant_id
	
	skip_provider_registration = true
	
	features {
		key_vault {
			purge_soft_deleted_keys_on_destroy = false
			purge_soft_deleted_secrets_on_destroy = false
		}
	}
}

#----- Routed vnet subscription provider
provider "azurerm" {
	alias = "routed_vnet"
	
	subscription_id = local.my_mg.routed_vnet_target[var.region_ref].subscription_id
	tenant_id = var.tenant_id
	
	skip_provider_registration = true
	
	features {}
}

#----- HSM vnet subscription provider
provider "azurerm" {
	alias = "hsm_vnet"
	
	subscription_id = local.my_mg.hsm_vnet_target[var.region_ref].subscription_id
	tenant_id = var.tenant_id
	
	skip_provider_registration = true
	
	features {}
}

#----- Public DNS parent zone subscription provider
provider "azurerm" {
	alias = "parent_public_dns_zone"
	
	#subscription_id = local.parent_public_dns_zone.subscription_id
	subscription_id = contains(keys(local.my_dns), "public_tld_subscription_id") ? local.my_dns.public_tld_subscription_id : var.common_subscription_id[var.app_ref]
	tenant_id = var.tenant_id
	
	skip_provider_registration = true
	
	features {}
}

data "azurerm_subscription" "env" {
}

data "azurerm_subscription" "common" {
	provider = azurerm.common
}
	
