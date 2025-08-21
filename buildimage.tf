locals {

servicelink_build_images = {
	v39 = {
		desc = "Upgrade helm to 3.16.3"
		vm_sku = "Standard_D4s_v4"
		disk_size_gb = 100
		source_image = {
			publisher = "Canonical"
			offer = "0001-com-ubuntu-server-jammy"
			sku = "22_04-lts"
			version = "latest"
		}
	}
	v40 = {
		desc = "Instal Cortex"
		vm_sku = "Standard_D4s_v4"
		disk_size_gb = 100
		source_image = {
			publisher = "Canonical"
			offer = "0001-com-ubuntu-server-jammy"
			sku = "22_04-lts"
			version = "latest"
		}
	}
	v41= {
		desc = "Terraform v0.14.11"
		vm_sku = "Standard_D4s_v4"
		disk_size_gb = 100
		source_image = {
			publisher = "Canonical"
			offer = "0001-com-ubuntu-server-jammy"
			sku = "22_04-lts"
			version = "latest"
		}
	}
    v42= {
		desc = "Install Cortex v8.9"
		vm_sku = "Standard_D4s_v4"
		disk_size_gb = 100
		source_image = {
	    publisher = "Canonical"
	    offer = "0001-com-ubuntu-server-jammy"
		sku = "22_04-lts"
		version = "latest"
		}
	}
}
	
}
