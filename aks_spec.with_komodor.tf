locals {

aks_instances = {
	app = {
		name = ""
		numeric = "01"
		support_plan = "AKSLongTermSupport"
		version = {
			default = "1.30.0"
			env_override = {}
		}
		nginx_ingress_version_tag = {
			default = "3.4.3"
			env_override = {
			}

    komodor_enabled = {
      default      = true
      env_override = {}
      mg_override  = {}
    }
    komodor_version_tag = {
      default      = "1.8.11"
      env_override = {}
      mg_override  = {}
    }

		}
		use_nginx_ingress_version_tag = {
			default = false
			env_override = {
			}
		}
		linkerd_version = {
			default = "enterprise-2.17.2"
			env_override = {
			}
		}
		use_linkerd_version = {
			default = false
			env_override = {
			}
		}
		nginx_ingress_replicas = {
			default = 1
			env_override = {
				perf = 2
			}
			mg_override = {
				prod = 2
			}
		}
		nodepools = {
			default = {
				node_count = 3
				node_size = {
					default = "Standard_D16s_v4"
					env_override = {}
				}
				disk_size = "256"
				node_max_pods = "125"
				os_type = "Linux"
				enable_auto_scaling = true
				min_node_count = 3
				max_node_count = 10
				labels = {
				}
				taints = []
				subnet_key = "aks_default_nodepool"
			}
			appdefault = {
				node_count = 30
				node_size = {
					default = "Standard_E16s_v4"
					env_override = {}
				}
				disk_size = "512"
				node_max_pods = "125"
				os_type = "Linux"
				enable_auto_scaling = true
				min_node_count = {
					default = 1
					env_override = {
						perf = 26
						prod = 29
					}
				}
				max_node_count = {
					default = 28
					env_override = {
						perf = 26
						prod = 29
					}
				}
				labels = {
					"schedule" = "appdefault"
				}
				taints = [
					"schedule=appdefault:NoSchedule"
				]
				subnet_key = "aks_appdefault_nodepool"
			}
			docgen = {
				node_count = 0
				node_size = {
					default = "Standard_E16s_v4"
					env_override = {}
				}
				disk_size = "512"
				node_max_pods = "125"
				os_type = "Linux"
				enable_auto_scaling = true
				min_node_count = {
					default = 0
					env_override = {}
				}
				max_node_count = {
					default = 10
					env_override = {
						stage = 0
						prod = 0
					}
				}
				labels = {
					"schedule" = "docgen"
				}
				taints = [
					"schedule=docgen:NoSchedule"
				]
				subnet_key = "aks_docgen_nodepool"
			}
			gpu = {
				node_count = 0
				node_size = {
					default = "Standard_NC4as_T4_v3"
					env_override = {
						perf = "Standard_NC8as_T4_v3"
					}
				}
				disk_size = "512"
				node_max_pods = "125"
				os_type = "Linux"
				enable_auto_scaling = false
				min_node_count = {
					default = 1
					env_override = {
						sandbox = 1
						dev2 = 2
						perf = 2
						uat2 = 2
						stage = 2
						prod = 2
					}
				}
				max_node_count = {
					default = 1
					env_override = {
						sandbox = 2
						dev2 = 2
						perf = 2
						uat2 = 2
						stage = 2
						prod = 2
					}
				}
				labels = {
					"schedule" = "gpu"
				}
				taints = [
					"schedule=gpu:NoSchedule"
				]
				subnet_key = "aks_gpu_nodepool"
			}
			els = {
				node_count = 0
				node_size = {
					default = "Standard_E16s_v4"
					env_override = {}
				}
				disk_size = "512"
				node_max_pods = "125"
				os_type = "Linux"
				enable_auto_scaling = true
				min_node_count = {
					default = 0
					env_override = {}
				}
				max_node_count = {
					default = 10
					env_override = {
						stage = 0
						prod = 0
					}
				}
				labels = {
					"schedule" = "els"
				}
				taints = [
					"schedule=els:NoSchedule"
				]
				subnet_key = "aks_els_nodepool"
			}
			exos3 = {
				node_count = 0
				node_size = {
					default = "Standard_E16s_v4"
					env_override = {}
				}
				disk_size = "512"
				node_max_pods = "125"
				os_type = "Linux"
				enable_auto_scaling = true
				min_node_count = {
					default = 0
					env_override = {}
				}
				max_node_count = {
					default = 10
					env_override = {
						sandbox = 0
						dev2 = 0
						perf = 2
						uat2 = 0
						stage = 2
						prod = 2
					}
				}
				labels = {
					"schedule" = "exos3"
				}
				taints = [
					"schedule=exos3:NoSchedule"
				]
				subnet_key = "aks_exos3_nodepool"
			}
		}
	}
}
			
}

  # --- Komodor integration toggles ---
  komodor_enabled = {
    default      = true
    env_override = {}
    mg_override  = {}
  }

  komodor_version_tag = {
    default      = "1.8.11"
    env_override = {}
    mg_override  = {}
  }
