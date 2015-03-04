# Configure the Google Cloud provider
provider "google" {
    account_file = "${var.account_file_path}"
    client_secrets_file = "${var.client_secrets_path}"
    project = "${var.project_name}"
    region = "${var.region_name}"
}

#Set up the IP address space for the cluster
resource "google_compute_network" "production" {
	name = "${var.network_name}"
	ipv4_range = "${var.iprange}"
}

#Provision the static IPs for nginx
resource "google_compute_address" "ngnxaddress" {
	count = “3”
	name = "ngx${count.index}address"
}

#Provision the static IPs for nat
resource "google_compute_address" "nataddress" {
	count = "1"
	name = "nat${count.index}address"
}

#Provision the static IPs for bastionbox
resource "google_compute_address" "bastionaddress" {
	count = "1"
	name = "bast${count.index}address"
}

#Create the firewalls for the layered net ssh access
resource "google_compute_firewall" "ssh" {
	name = "sshwall"
	network = "${google_compute_network.production.name}"
	
    allow {
        protocol = "tcp"
        ports = ["22"]
    }	

	source_ranges = ["${var.external_net}"]
}

#Create the firewalls for the layered net
resource "google_compute_firewall" "internal" {
	name = "intwall"
	network = "${google_compute_network.production.name}"
	
    allow {
        protocol = "tcp"
        ports = ["1-65535"]
    }	

    allow {
        protocol = "udp"
        ports = ["1-65535"]
    }
	source_tags = ["internal"]
	source_ranges = ["${var.internal_net}"]
}

resource "google_compute_firewall" "webwall" {
    name = "webwall"
    network = "${google_compute_network.production.name}"

    allow {
        protocol = "tcp"
        ports = ["80", "443"]
    }

    source_ranges = ["${var.external_net}"]
    target_tags = ["web"]
}

#Create the route for nat and no ips
resource "google_compute_route" "no_ips" {
	name = "noiproute"
	dest_range = "${var.external_net}"
	network = "${google_compute_network.production.name}"
	next_hop_instance_zone = "${var.region_name}-a"
	next_hop_instance = "natgatew"
	priority = 500
	tags = ["no-ip"]
	depends_on = ["google_compute_instance.natgateway"]
} 

#Create the nat gateway instance
resource "google_compute_instance" "natgateway" {
	count = "1"
	name = "natgatew"
	machine_type = "${var.layer1type.gce}"
	zone = "${lookup(var.azones, concat("zon", count.index))}"
	tags = ["nat","internal","ssh"]
	can_ip_forward = "true"
	
	disk {
		image = "centos-6-v20141205"
		type = "pd-ssd"
	}	
	
	network_interface {
		network = "${google_compute_network.production.name}"
		access_config { 
		nat_ip = "${element(google_compute_address.nataddress.*.address,count.index)}"
		}
	}
	metadata {	
		host_group = "natgate"
		sshKeys = "${var.sshkeys.opskey}"
	}

	provisioner "remote-exec" {
		connection {
			user = "${var.bastion_user}"
			key_file = "${var.bastion_key}"
		}
		scripts = ["scripts/setnat.sh","scripts/setfire.sh"]
	}	

}

#Create the bastion box node
resource "google_compute_instance" "bastion" {
	count = "1"
	name = "bast${count.index}"
	machine_type = "${var.layer2type.gce}"
	zone = "${lookup(var.azones, concat("zon", count.index))}"
	tags = ["internal","ssh","bastion"]
	
	disk {
		image = "centos-6-v20141205"
	}
	
	network_intaerface {
		network = "${google_compute_network.production.name}"
		access_config { 
		nat_ip = "${element(google_compute_address.bastionaddress.*.address,count.index)}"
		}
	}
			
	metadata {	
		host_group = "bastionnodes"
		sshKeys = "${var.sshkeys.opskey}"
	}
	provisioner "remote-exec" {
		connection {
			user = "${var.bastion_user}"
			key_file = "${var.bastion_key}"
		}
		script = "scripts/setfire.sh"
	}
}

#Create the persistent disks for database storage
resource "google_compute_disk" "data" {
	count = "3"
	name = "data${count.index}"
	type = "pd-standard"
	zone = "${lookup(var.azones, concat("zon", count.index))}"
	size = "1000"
}

#Setup the frontend loadbalancers
resource "google_compute_instance" "loadbalancers" {
	count = “3”
	name = "lb${count.index}"
	machine_type = "${var.layer1type.gce}"
	zone = "${lookup(var.azones, concat("zon", count.index))}"
	tags = ["web","layer1","ssh"]
	
	disk {
		image = "centos-6-v20141205"
	}
	
	network_interface {
		network = "${google_compute_network.production.name}"
		access_config { 
		nat_ip = "${element(google_compute_address.ngnxaddress.*.address,count.index)}"
		}
	}
	
	metadata {	
		host_group = "loadbalancers"
		sshKeys = "${var.sshkeys.opskey}"
	}

	provisioner "remote-exec" {
		connection {
			user = "${var.bastion_user}"
			key_file = "${var.key_path}"
		}
		script = "scripts/setfire.sh"
	}
}

#Create the application nodes
resource "google_compute_instance" "appnodes" {
	count = "3"
	name = "app${count.index}"
	machine_type = "${var.layer2type.gce}"
	zone = "${element(google_compute_instance.loadbalancers.*.zone,count.index)}"
	tags = ["app", "internal", "layer2","ssh","no-ip"]
	depends_on = ["google_compute_route.no_ips"]

	
	disk {
		image = "centos-6-v20141205"
		type = "pd-ssd"
	}
	
	network_interface {
		network = "${google_compute_network.production.name}"
	}
			
	metadata {	
		host_group = "appnodes"
		sshKeys = "${var.sshkeys.opskey}"
	}

}

#Create the DB instances and attach the disks
resource "google_compute_instance" "dbsnodes" {
	count = "3"
	name = "dbs${count.index}"
	machine_type = "${var.layer3type.gce}"
	zone = "${element(google_compute_instance.loadbalancers.*.zone,count.index)}"
	tags = ["dbs", "internal", "layer3","ssh","no-ip"]
	depends_on = ["google_compute_route.no_ips"]
		
	disk {
		image = "centos-6-v20141205"
		type = "pd-ssd"
	}
	
	disk {
		disk = "${element(google_compute_disk.data.*.name,count.index)}"
	}
	
	network_interface {
		network = "${google_compute_network.production.name}"
	}
			
	metadata {	
		host_group = "dbsrvs"
		sshKeys = "${var.sshkeys.solidkey}"
	}
		
}
