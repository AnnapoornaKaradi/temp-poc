locals {
	linkerd_namespace = "linkerd"
	license_secret_name = "buoyant-license"
	linkerd_version = { for k, v in local.aks_instances :
		k => (
			lookup(lookup(v.linkerd_version, "env_override",{}), local.my_env_short, null) != null ? v.linkerd_version.env_override[local.my_env_short] : v.linkerd_version.default
		)
	}
	use_linkerd_version = { for k, v in local.aks_instances :
		k => (
			lookup(lookup(v.use_linkerd_version, "env_override",{}), local.my_env_short, null) != null ? v.use_linkerd_version.env_override[local.my_env_short] : v.use_linkerd_version.default
		)
	}
	linkerd_chart = { for k, v in local.aks_instances :
		k => (
			local.use_linkerd_version[k] ? "linkerd-control-plane_${local.linkerd_version[k]}" : "linkerd-control-plane"
		)
	}
	linkerd_crds_chart = { for k, v in local.aks_instances :
		k => (
			local.use_linkerd_version[k] ? "linkerd-crds_${local.linkerd_version[k]}" : "linkerd-crds"
		)
	}
}

#----- Create the resources needed for service mesh PKI.  Note that all clusters currently share these resources in case they need to cross talk
# Create the root CA (trust anchor) certificate and key
resource "tls_private_key" "linkerd_trust_anchor_key" {
	algorithm = "ECDSA"
	ecdsa_curve = "P256"
}

data "azurerm_key_vault_secret" "linkerd_license_key" {
	provider = azurerm.common
	
	name = "BuoyantLicense--Key"
	key_vault_id = data.terraform_remote_state.common.outputs.key_vaults.infra.common["eus2"].id
}

resource "tls_self_signed_cert" "linkerd_trust_anchor_cert" {  
	private_key_pem = tls_private_key.linkerd_trust_anchor_key.private_key_pem
	validity_period_hours = local.internal_pki.ca_cert_validity
	early_renewal_hours = local.internal_pki.ca_cert_renewal
	is_ca_certificate = true

	subject {
		common_name = "identity.linkerd.cluster.local"
		street_address = []
	}

	allowed_uses = [
		"crl_signing",
		"cert_signing"
	]
}

#----- Generate the issuer certificate and key and sign it (for linkerd)
resource "tls_private_key" "linkerd_issuer_key" {  
	algorithm = "ECDSA"
	ecdsa_curve = "P256"
}

resource "tls_cert_request" "linkerd_issuer_req" {  
	private_key_pem = tls_private_key.linkerd_issuer_key.private_key_pem
	
	subject {
		common_name = "identity.linkerd.cluster.local"
		street_address = []
	}
}

resource "tls_locally_signed_cert" "linkerd_issuer_cert" {  
	cert_request_pem = tls_cert_request.linkerd_issuer_req.cert_request_pem
	ca_private_key_pem = tls_private_key.linkerd_trust_anchor_key.private_key_pem
	ca_cert_pem = tls_self_signed_cert.linkerd_trust_anchor_cert.cert_pem
	is_ca_certificate = true

	validity_period_hours = local.internal_pki.issuer_cert_validity
	early_renewal_hours = local.internal_pki.issuer_cert_renewal

	allowed_uses = [
		"crl_signing",
		"cert_signing"
	]
}

#----- Create the linkerd namespace
resource "kubernetes_namespace" "linkerd" {
	for_each = local.aks_instances

	metadata {
		name = local.linkerd_namespace
		
		annotations = {
			"linkerd.io/inject" = "disabled"
		}
		
		labels = {
			"linkerd.io/is-control-plane" = "true"
			"config.linkerd.io/admission-webhooks" = "disabled"
			"linkerd.io/control-plane-ns" = local.linkerd_namespace
		}
	}
	
	lifecycle {
		ignore_changes = [
			metadata[0].annotations, metadata[0].labels,
		]
	}
}

resource "kubernetes_secret" "linkerd_license_key" {
  metadata {
    name = local.license_secret_name
  }

  data = {
    license = data.azurerm_key_vault_secret.linkerd_license_key.value
  }

  type = "Opaque"
}


#----- Create a limit range for the linkerd namespace
resource "kubernetes_limit_range" "linkerd" {
	for_each = local.aks_instances

	metadata {
		name = local.linkerd_namespace
		namespace = local.linkerd_namespace
	}
	/*
	spec {
		limit {
			type = "Pod"
			max = {
				cpu = "2"
				memory = "10542Mi"
			}
		}
	}
	*/
	depends_on = [
		kubernetes_namespace.linkerd
	]
}

#----- Deploy linkerd
resource "kubernetes_secret" "license_key" {
	for_each = local.aks_instances

	metadata {
		name = "buoyant-license"
		namespace = local.linkerd_namespace
	}

	data = {
		license = data.azurerm_key_vault_secret.linkerd_license_key.value
	}

	type = "Opaque"
}

resource "helm_release" "linkerd-crds" {  
	for_each = local.aks_instances

	name = "linkerd-crds"
	namespace = local.linkerd_namespace
	create_namespace = false
	chart = "${path.module}/helm_charts/${local.linkerd_crds_chart[each.key]}"
	
	depends_on = [
		kubernetes_namespace.linkerd,
		kubernetes_limit_range.linkerd,
	]
}

resource "helm_release" "linkerd-control-plane" {  
	for_each = local.aks_instances

	name = "linkerd-control-plane"
	namespace = local.linkerd_namespace
	create_namespace = false
	chart = "${path.module}/helm_charts/${local.linkerd_chart[each.key]}"
	
	# Increased timeout to 10 minutes in case an auto scale operation has to happen to accomodate a new release
	timeout = 600
	
	values = [
		file("${path.module}/helm_charts/${local.linkerd_chart[each.key]}/values.yaml"),
		file("${path.module}/helm_charts/${local.linkerd_chart[each.key]}/values-ha.yaml"),
	]
	
	set {
		name = "namespace"
		value = local.linkerd_namespace
	}
	
	set {
		name = "installNamespace"
		value = "false"
	}

	set {
		name = "proxy.resources.cpu.limits"
		value = "2000m"
	}

	set {
		name = "proxy.resources.memory.limits"
		value = "2000Mi"
	}
	
	set {
		name = "prometheus.enabled"
		value = "false"
	}

	set {
		name = "buoyant-license"
		value = local.license_secret_name
	}
	
	set_sensitive {
		name = "identityTrustAnchorsPEM"
		value = tls_self_signed_cert.linkerd_trust_anchor_cert.cert_pem
	}

	set_sensitive {
		name = "identity.issuer.tls.crtPEM"
		value = tls_locally_signed_cert.linkerd_issuer_cert.cert_pem
	}

	set {
		name = "identity.issuer.crtExpiry"
		value = tls_locally_signed_cert.linkerd_issuer_cert.validity_end_time
	}
	
	set_sensitive {
		name = "identity.issuer.tls.keyPEM"
		value = tls_private_key.linkerd_issuer_key.private_key_pem
	}
	
	set {
		name = "cniEnabled"
		value = "false"
	}
	
	depends_on = [
		kubernetes_namespace.linkerd,
		kubernetes_limit_range.linkerd,
		kubernetes_secret.license_key
	]
}
