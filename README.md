# terraform-gce-3tier
==================================
Three tier setup on Google Compute Engine using [terraform.io](terraform.io)

Terraform configuration to set up a VPC-like environment in Google Compute Engine (GCE).With firewalls separating the layers from each other and internal nodes on private subnet accessible only by a bastion box.

![plot](images/plot.png?raw=true)

**Components**

*Bastion Box*

Provides access from the outside world for ssh access via a trusted channel , with key separation.Internal nodes have different ssh key from the bastion box.

*NATGateway*

Provides internat access from the internal nodes that have no external IP addresss , provided by tagging with "no-ip".

*Layer1*

The load balancers are spread across all availability zones in a particular region , in this case uscentral1 a through f with static IP addresses provisioned and attached on creation.

*Layer2*

Application layer nodes created after the NAT Gateway is ready and firewall rules are complete.

*Layer3*

Database layer nodes are created after provisioning of persistent storage.Data disks are attached to the launched instances and using script mountformat.sh , mounted and formatted using the XFS.


**Variables**

The variables needed to run the script:

- account_\_file_\_path -- Full path ocation of the project-file.json

- client_\_secrets_\_path -- Full path to the secrets file client_secret_........googleusercontent.com.json

- project_name -- project name from GCE dashboard

- region_name  -- region in which to launch the stack (uscentral1)

- network_name -- Name of the network to launch instances in

- internal_net -- Internal network subnet range eg 192.168.10.0/16

- ip_range -- Internal network subnet range eg 192.168.10.0/16



**Layertypes**

Set the size/type of instances to launch for each particular group of instances.


**Scripts**

Three scripts are provided to aid in the setup of the instances before configuration.

* setnat.sh - makes the required changes to the NATGateway instance to allow ip forwarding.
* mountformat.sh - mounts and formats the persistent storage disks of the database nodes.
* setfire.sh - for configuration management (ansible) to be able to use ssh pipeline mode and allow protocol forwarding from the bastion node to the rest of the hosts.

**Usage**

> `$terraform plan -out leaf`

Genaerates the topology to apply to the leaf file interactively asking the for the needed variables to be supplied.These can alternativel be preset into a variables.tfvars file and called with the switch:

> `$terraform plan -var-file=vars.tfvars -out leaf`


and finally to apply the plan to create the topology on GCE:

> `$terraform apply leaf`



