#---------- Variables defined in the pipeline ----------
variable "app_ref" { type = string }
variable "env_ref" { type = string }
variable "region_ref" { type = string }
variable "tf_step" { type = string }
variable "subscription_id" { type = string }
variable "machine_date" { type = string }
variable "first_run" { type = bool }

#---------- Variables designed to be defined globally ----------
variable "common_subscription_id" { type = map(string) }
variable "common_subscription_name" { type = map(string) }
variable "tenant_id" { type = string }

variable "default_admin_username" { type = string }

variable "vm_patching_keeper" { type = string }
variable "vm_restart_keeper" { type = string }

variable "spns" {
	type = map(object({
		password_expiration = string
	}))
}

variable "log_retention_days" { type = string }

variable "nsg_flow_logs" {
	type = object({
		retention_days = number
		traffic_analytics_interval = number
	})
}

variable "email_addresses" {
	type = map(string)
}

variable "unused_ip_space" {
	type = map(list(string))
}

variable "devops_infra_spn_oid" { type = map(string) }

#---------- Variables unique to each environment ----------
/*
App_Code1 = 272
App_ID = EXOS
Parent_HostingID =	1.1 - Sandbox
					2.1 - Development
					2.2 - Quality Assurance
					2.3 - Integration
					2.4 - Functional Testing
					3.1 - NonProduction
					3.2 - Load Test
					3.3 - UAT
					3.4 - Performance Test
					3.5 - Pre-Sales
					4.1 - Production
					4.2 - Disaster Recovery (Prod)
*/
variable "fnf_rg_tags" { type = map(string) }

variable "public_prefix" {
	type = object({
		length = number
	})
	
	default = null
}

variable "backhaul_firewall" {
	type = object({
		use_prefix = bool
		prefix_usage = number
	})
}

variable "external_hostnames" { type = list(string) }

variable "minimum_tls_version" { type = string }

variable "dns_vm_forward_zones" {
	type = map(object({
		name = string
		addresses = list(string)
	}))
}

variable "public_dns_spf_record" { type = string }
variable "public_dns_dkim_record" {
	type = object({
		name = string
		value = string
	})
}
variable "public_dns_dkim_record_secondary" {
	type = object({
		name = string
		value = string
	})
	default = null
}

variable "redis2_family" { type = string }
variable "redis2_capacity" { type = number }
variable "redis2_sku_name" { type = string }
variable "redis2_subnet" { type = string }

variable "nginx_edge_hsm_client_key_id" { type = string }
variable "nginx_edge_external_domain_names" { type = list(string) }
variable "nginx_edge_internal_domain_names" { type = list(string) }
variable "nginx_edge_traffic_manager_healthy" {
	type = bool
	default = true
}
variable "nginx_edge_hsm" {
	type = object({
		ca_cert_names = list(string)
		partition_name = string
		devices = list(object({
			numeric = string
			ip = string
			port = string
			htl = string
		}))
	})
}
variable "nginx_edge_service_proxy_whitelist" { type = list(string) }
variable "nginx_edge_service_restart_keeper" { type = string }
variable "nginx_edge_enable_hudsonandmarshall" {
	type = bool
	default = false
}
variable "nginx_edge_maint_mode" {
	type = string
	default = "off"
	# Acceptable values: off, all, external_only    If an invalid value is used, it will default to off
}

variable "traffic_manager_enabled" { type = bool }
variable "traffic_manager" {
	type = object({
		routing_method = string
		dns_ttl = number
		monitor_protocol = string
		monitor_port = number
		monitor_path = string
		monitor_interval_in_seconds = number
		monitor_timeout_in_seconds = number
		monitor_tolerated_number_of_failures = number
	})
}

variable "create_wvd_infra" { type = bool }
variable "wvd" {
	type = object({
		address_space = string
		region = string
		region_short = string
		user_groups = map(string)
	})
}

variable "oracle_sftp_pgp_keys" {
	type = object({
		type                    = string
		length                  = number
		name                    = string
		comment                 = string
		email                   = string
		passphrase              = string
		public_key_secret_name  = string
		private_key_secret_name = string
		manual_trigger          = string
	})
}

#variable "nginx_edge_corporate_allowed" { type = list(string) }

variable "sre_team" {
	type = object({
		team_name = string
		email_address = string
	})
}
