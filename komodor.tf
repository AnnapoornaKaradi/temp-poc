/*
  Komodor install — matches the style used for NGINX Ingress (locals + for_each + helm_release).
  Assumptions:
  - You have azurerm_kubernetes_cluster.aks defined with for_each = local.aks_instances
  - You already have helm/kubernetes providers wired to the AKS in providers.tf (same as NGINX file uses)
*/
locals {
  # Per-AKS instance toggle and chart version, with optional env / mg overrides
  komodor_enabled = { for k, v in local.aks_instances :
    k => (
      try(lookup(lookup(v.komodor_enabled, "env_override", {}), local.basic["local"].env_short, null) != null, false) ?
        v.komodor_enabled.env_override[local.basic["local"].env_short] :
      try(lookup(lookup(v.komodor_enabled, "mg_override", {}), local.basic["local"].env_short, null) != null, false) ?
        v.komodor_enabled.mg_override[local.basic["local"].env_short] :
        try(v.komodor_enabled.default, true)
    )
  }

  komodor_version_tag = { for k, v in local.aks_instances :
    k => (
      try(lookup(lookup(v.komodor_version_tag, "env_override", {}), local.basic["local"].env_short, null) != null, false) ?
        v.komodor_version_tag.env_override[local.basic["local"].env_short] :
      try(lookup(lookup(v.komodor_version_tag, "mg_override", {}), local.basic["local"].env_short, null) != null, false) ?
        v.komodor_version_tag.mg_override[local.basic["local"].env_short] :
        try(v.komodor_version_tag.default, "1.8.11")
    )
  }

  komodor_namespace = "komodor"
}

# -- Namespace (optional; you can rely on create_namespace=true in helm_release if you prefer)
resource "kubernetes_namespace" "komodor" {
  for_each = { for k, v in local.aks_instances : k => v if local.komodor_enabled[k] }

  metadata {
    name = local.komodor_namespace
    labels = {
      "app.kubernetes.io/name" = "komodor-agent"
      "fnf.env"                = local.basic["local"].env_short
    }
  }
}

resource "helm_release" "komodor" {
  for_each = { for k, v in local.aks_instances : k => v if local.komodor_enabled[k] }

  name             = "komodor-agent"
  repository       = "https://helm-charts.komodor.io"
  chart            = "komodor-agent"
  version          = local.komodor_version_tag[each.key]

  namespace        = local.komodor_namespace
  create_namespace = true

  # non-secret config
  values = [
    templatefile("${path.module}/values-komodor.yaml", {
      clusterName = azurerm_kubernetes_cluster.aks[each.key].name
    })
  ]

  # secret from pipeline or tfvars (map by environment)

  # secret resolution precedence:
  # 1) by AKS cluster name
  # 2) by AKS instance key (e.g., "app")
  # 3) by environment short code (var.env_ref)
  set_sensitive {
    name  = "apiKey"
    value = coalesce(
      lookup(var.komodor_api_keys_by_cluster, azurerm_kubernetes_cluster.aks[each.key].name, null),
      lookup(var.komodor_api_keys_by_instance, each.key, null),
      lookup(var.komodor_api_keys_by_env, var.env_ref, null),
      ""
    )
  }

  # wait until AKS exists
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    kubernetes_namespace.komodor
  ]
}
