# Configure the variables to use

variable "account_file_path" {}
variable "client_secrets_path" {}
variable "project_name" {}
variable "region_name" {}

variable "network_name" {}
variable "external_net" {}
variable "internal_net" {}

variable "iprange" {}

variable "layer1type" {
	default = {
		gce = "g1-small"
		aws = ""
	}
}

variable "layer2type" {
	default = {
		gce = "g1-small"
		aws = ""
	}
}

variable "layer3type" {
	default = {
		gce = "g1-small"
		aws = ""
	}
}

variable "azones" {
	default = {
		zon0 = "us-central1-a"
		zon1 = "us-central1-b"
		zon2 = "us-central1-f"
	}
}

variable "ezones" {
	default = {
		zon0 = "asia-east1-a"
		zon1 = "asia-east1-b"
		zon2 = "asia-east1-c"
	}
}