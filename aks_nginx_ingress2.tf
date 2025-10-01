locals {
	nginx_ingress_app_name = "nginx-ingress-nginx-ingress"
	nginx_ingress_namespace = "nginx-ingress"
	
	nginx_ingress_replicas = { for k, v in local.aks_instances :
		k => (
			lookup(lookup(v.nginx_ingress_replicas, "env_override", {}), local.basic["local"].env_short, null) != null ? v.nginx_ingress_replicas.env_override[local.basic["local"].env_short] :
			lookup(lookup(v.nginx_ingress_replicas, "mg_override", {}), local.basic["local"].env_short, null) != null ? v.nginx_ingress_replicas.mg_override[local.basic["local"].env_short] :
			v.nginx_ingress_replicas.default
		)
	}
	nginx_ingress_version_tag = { for k, v in local.aks_instances :
		k => (
			lookup(lookup(v.nginx_ingress_version_tag, "env_override",{}), local.my_env_short, null) != null ? v.nginx_ingress_version_tag.env_override[local.my_env_short] : v.nginx_ingress_version_tag.default
		)
	}
	use_nginx_ingress_version_tag = { for k, v in local.aks_instances :
		k => (
			lookup(lookup(v.use_nginx_ingress_version_tag, "env_override",{}), local.my_env_short, null) != null ? v.use_nginx_ingress_version_tag.env_override[local.my_env_short] : v.use_nginx_ingress_version_tag.default
		)
	}
	nginx_chart = { for k, v in local.aks_instances :
		k => (
			local.use_nginx_ingress_version_tag[k] ? "nginx-ingress_${local.nginx_ingress_version_tag[k]}" : "nginx-ingress"
		)
	}
}

#----- Create a self-signed TLS cert and key for the default config on the ingress controller
resource "tls_private_key" "nginx_ingress_default_key" {
	for_each = local.aks_instances

	algorithm = "RSA"
	rsa_bits = local.internal_pki.client_key_bits
}

resource "tls_self_signed_cert" "nginx_ingress_default_cert" {
	for_each = local.aks_instances

	private_key_pem = tls_private_key.nginx_ingress_default_key[each.key].private_key_pem
	is_ca_certificate = false
	
	validity_period_hours = local.internal_pki.client_cert_validity
	early_renewal_hours = local.internal_pki.client_cert_renewal
	
	subject {
		common_name = lower("services.${local.basic["local"].env_short}.${local.my_dns.private_tld}")
		street_address = []
	}
	
	allowed_uses = [
		"server_auth"
	]

	
}

#----- Create the nginx ingress namespace
resource "kubernetes_namespace" "nginx_ingress" {
	for_each = local.aks_instances
	
	metadata {
		name = local.nginx_ingress_namespace
	}
	
	lifecycle {
		ignore_changes = [
			metadata[0].annotations, metadata[0].labels,
		]
	
	}
	
}

#----- Create a limit range for the linkerd namespace
resource "kubernetes_limit_range" "nginx_ingress" {
	for_each = local.aks_instances
	
	metadata {
		name = local.nginx_ingress_namespace
		namespace = local.nginx_ingress_namespace
	}
	
	spec {
		limit {
			type = "Pod"
			max = {
				cpu = "2"
				memory = "4Gi"
			}
		}
	}
	
	depends_on = [
		kubernetes_namespace.nginx_ingress
	]
}



#----- Deploy the ingress controller along with its dependencies
resource "helm_release" "nginx_ingress" {
	for_each = local.aks_instances

	name = "nginx-ingress"
	namespace = local.nginx_ingress_namespace
	create_namespace = false
	chart = "${path.module}/helm_charts/${local.nginx_chart[each.key]}"

	# Increased timeout to 15 minutes in case an auto scale operation has to happen to accomodate a new release
	timeout = 900
	
	disable_webhooks = true

	values = [
		file("${path.module}/helm_charts/${local.nginx_chart[each.key]}/values.yaml"),
		file("${path.module}/helm_charts/nginx_ingress_config.yaml"),
	]
	
	set {
		name = "controller.nginxplus"
		value = "true"
	}
	
	set_sensitive {
		name = "controller.defaultTLS.cert"
		value = base64encode(tls_self_signed_cert.nginx_ingress_default_cert[each.key].cert_pem)
	}
	
	set_sensitive {
		name = "controller.defaultTLS.key"
		value = base64encode(tls_private_key.nginx_ingress_default_key[each.key].private_key_pem)
	}
	
	set {
		name = "namespace"
		value = local.nginx_ingress_namespace
	}
	
	set {
		name = "controller.selectorLabels.app"
		value = local.nginx_ingress_app_name
	}

	set {
		name = "controller.replicaCount"
		value = local.nginx_ingress_replicas[each.key]
	}

	set {
		name = "controller.image.repository"
		value = "${data.terraform_remote_state.common.outputs.container_registry_2.fqdn}/nginx-plus-ingress"
	}
	
	set {
		name = "controller.image.tag"
		value = local.nginx_ingress_version_tag[each.key]
	}
	
	set {
		name = "controller.pod.annotations.linkerd\\.io/inject"
		value = "enabled"
	}
	
	set {
		name = "controller.enableSnippets"
		value = "true"
	}
	
	set {
		name = "controller.enableCustomResources"
		value = "true"
	}
	
	set {
		name = "controller.enableLatencyMetrics"
		value = "true"
	}
	
	set {
		name = "toleration_key"
		value = ""
	}
	
	set {
		name = "toleration_value"
		value = ""
	}
	
	set {
		name = "toleration_operator"
		value = ""
	}
	
	set {
		name = "toleration_effect"
		value = ""
	}
	
	depends_on = [
		null_resource.nginx_ingress_image_sync,
		azurerm_role_assignment.aks_mi_acr_role_assignment,
		kubernetes_namespace.nginx_ingress,
		kubernetes_limit_range.nginx_ingress,
		helm_release.linkerd-control-plane,
	]
}

#----- Create the azure load balancer service
resource "kubernetes_service" "nginx_ingress_lb" {
	for_each = local.aks_instances
	
	metadata {
		name = "${local.nginx_ingress_app_name}-lb"
		namespace = local.nginx_ingress_namespace
		
		annotations = {
			"service.beta.kubernetes.io/azure-load-balancer-internal" = true
		}
	}
	
	spec {
		selector = {
			app = local.nginx_ingress_app_name
		}

		port {
			port = 443
			target_port = 443
		}
		
		type = "LoadBalancer"
	}
	
	depends_on = [
		helm_release.nginx_ingress,
	]
}

#----- Create the DNS entry for the ingress controller and friendly name for services
resource "azurerm_private_dns_a_record" "nginx_ingress" {
	for_each = local.aks_instances

	# For this to truely support multiple AKS instances, the name will have to be adjusted
	name = "aks-ingress"
	zone_name = azurerm_private_dns_zone.env.name
	resource_group_name = azurerm_private_dns_zone.env.resource_group_name

	ttl = 300
	records = [
		kubernetes_service.nginx_ingress_lb[each.key].status[0].load_balancer[0].ingress[0].ip,
	]
}
