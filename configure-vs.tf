##Provider - The provider tells Terraform which type of environment you are connecting to. Here we are connecting to vSphere using the vSphere provider

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

##Data -  Data resources define the vSphere environment and the resources terraform needs to interact with to clone and create the new virtual machine

data "vsphere_datacenter" "dc" {
  name = "Hetzner Environment"
}

data "vsphere_resource_pool" "pool" {
  name          = "Resources"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_virtual_machine
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_tag_category" "category" {
  name        = "terraform-test-category"
  cardinality = "SINGLE"
  description = "Managed by Terraform"

  associable_types = [
    "VirtualMachine",
    "Datastore",
  ]
}

resource "vsphere_tag" "tag" {
  name        = "terraform-test-tag"
  category_id = vsphere_tag_category.category.id
  description = "Managed by Terraform"

}

##vSphere VMs - This is the section where we actually do the cloning of the virtual machine

resource "vsphere_virtual_machine" "vm01" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  guest_id = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  num_cpus = 2
  memory   = 4096
  tags = [vsphere_tag.tag.id]


  network_interface {
    network_id   = data.vsphere_network.network.id
  }

  disk {
    label = "vm-one.vmdk"
    size = "30"
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  provisioner "file" {
    source = "./scripts/"
    destination = "/tmp/"

    connection {
      agent = false
      type     = "ssh"
      user     = var.vm_user
      password = var.vm_password
      host     = vsphere_virtual_machine.vm01.default_ip_address
    }
  }

  # Execute script on remote vm after this creation
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/*sh",
      "sudo /tmp/tomcat-create.sh",
      "sudo /tmp/tomcat-configure.sh",
      "sudo /tmp/tomcat-start.sh",
      "echo ${self.default_ip_address}",
    ]

    connection {
      agent = false
      type     = "ssh"
      user     = var.vm_user
      password = var.vm_password
      host     = vsphere_virtual_machine.vm01.default_ip_address
    }
  }
}
