variable "gcp_region" {
  type = string
}

variable "gcp_project" {
  type = string
  description = "The GCP project ID"
  default     = null
}
variable "instname" {
  type = list(string)
}
variable "zone_names" {
  type    = list(string)
  default = ["us-west-1a"]
}



variable "vpcname" {
  type           = string
  description  = "Name for this infrastructure"
  default       = "mig-vpc"
}

variable"subnet_cidr_range" {
type=list(string)
description="List of The range of addresses"
default=["10.10.10.0/24", "10.10.20.0/24"]
}

variable "name" {
  type           = string
  description  = "Name for this infrastructure"
  default       = "tfvpcname"
}

variable "subnet_region" {
  type = list(string)
}

###################################################################################################
variable "project_id" {
  type        = string
  description = "The GCP project ID"
  default     = null
}

variable "name_prefix" {
  description = "Name prefix for the instance template"
  type        = string
  default     = "default-instance-template"
}

variable "machine_type" {
  description = "Machine type to create, e.g. n1-standard-1"
  type        = string
  default     = "n1-standard-1"
}

variable "min_cpu_platform" {
  description = "Specifies a minimum CPU platform. Applicable values are the friendly names of CPU platforms, such as Intel Haswell or Intel Skylake. See the complete list: https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform"
  type        = string
  default     = null
}

variable "can_ip_forward" {
  description = "Enable IP forwarding, for NAT instances for example"
  type        = string
  default     = "false"
}

variable "tags" {
  type        = list(string)
  description = "Network tags, provided as a list"
  default     = []
}

variable "labels" {
  type        = map(string)
  description = "Labels, provided as a map"
  default     = {}
}

variable "preemptible" {
  type        = bool
  description = "Allow the instance to be preempted"
  default     = false
}

variable "spot" {
  type        = bool
  description = "Provision a SPOT instance"
  default     = false
}

variable "automatic_restart" {
  type        = bool
  description = "(Optional) Specifies whether the instance should be automatically restarted if it is terminated by Compute Engine (not terminated by a user)."
  default     = true
}

variable "on_host_maintenance" {
  type        = string
  description = "Instance availability Policy"
  default     = "MIGRATE"
}

variable "spot_instance_termination_action" {
  description = "Action to take when Compute Engine preempts a Spot VM."
  type        = string
  default     = "STOP"

  validation {
    condition     = contains(["STOP", "DELETE"], var.spot_instance_termination_action)
    error_message = "Allowed values for spot_instance_termination_action are: \"STOP\" or \"DELETE\"."
  }
}

variable "region" {
  type        = string
  description = "Region where the instance template should be created."
  default     = null
}

variable "enable_nested_virtualization" {
  type        = bool
  description = "Defines whether the instance should have nested virtualization enabled."
  default     = false
}

variable "threads_per_core" {
  description = "The number of threads per physical core. To disable simultaneous multithreading (SMT) set this to 1."
  type        = number
  default     = null
}

variable "resource_policies" {
  type        = list(string)
  description = "A list of self_links of resource policies to attach to the instance. Modifying this list will cause the instance to recreate. Currently a max of 1 resource policy is supported."
  default     = []
}

#######
# disk
#######
variable "source_image" {
  description = "Source disk image. If neither source_image nor source_image_family is specified, defaults to the latest public CentOS image."
  type        = string
  default     = ""
}

variable "source_image_family" {
  description = "Source image family. If neither source_image nor source_image_family is specified, defaults to the latest public CentOS image."
  type        = string
  default     = "centos-7"
}

variable "source_image_project" {
  description = "Project where the source image comes from. The default project contains CentOS images."
  type        = string
  default     = "centos-cloud"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = string
  default     = "100"
}

variable "disk_type" {
  description = "Boot disk type, can be either pd-ssd, local-ssd, or pd-standard"
  type        = string
  default     = "pd-standard"
}

variable "disk_labels" {
  description = "Labels to be assigned to boot disk, provided as a map"
  type        = map(string)
  default     = {}
}

variable "disk_encryption_key" {
  description = "The id of the encryption key that is stored in Google Cloud KMS to use to encrypt all the disks on this instance"
  type        = string
  default     = null
}

variable "auto_delete" {
  description = "Whether or not the boot disk should be auto-deleted"
  type        = string
  default     = "true"
}

variable "additional_disks" {
  description = "List of maps of additional disks. See https://www.terraform.io/docs/providers/google/r/compute_instance_template#disk_name"
  type = list(object({
    disk_name       = string
    device_name     = string
    auto_delete     = bool
    boot            = bool
    disk_size_gb    = number
    disk_type       = string
    disk_labels     = map(string)
    source_snapshot = optional(string)
  }))
  default = []
}

####################
# network_interface
####################
variable "network" {
  description = "The name or self_link of the network to attach this interface to. Use network attribute for Legacy or Auto subnetted networks and subnetwork for custom subnetted networks."
  type        = string
  default     = ""
}

variable "subnetwork" {
  description = "The name of the subnetwork to attach this interface to. The subnetwork must exist in the same region this instance will be created in. Either network or subnetwork must be provided."
  type        = string
  default     = ""
}

variable "subnetwork_project" {
  description = "The ID of the project in which the subnetwork belongs. If it is not provided, the provider project is used."
  type        = string
  default     = ""
}

variable "network_ip" {
  description = "Private IP address to assign to the instance if desired."
  type        = string
  default     = ""
}

variable "nic_type" {
  description = "Valid values are \"VIRTIO_NET\", \"GVNIC\" or set to null to accept API default behavior."
  type        = string
  default     = null

  validation {
    condition     = var.nic_type == null || var.nic_type == "GVNIC" || var.nic_type == "VIRTIO_NET"
    error_message = "The \"nic_type\" variable must be set to \"VIRTIO_NET\", \"GVNIC\", or null to allow API default selection."
  }
}

variable "stack_type" {
  description = "The stack type for this network interface to identify whether the IPv6 feature is enabled or not. Values are `IPV4_IPV6` or `IPV4_ONLY`. Default behavior is equivalent to IPV4_ONLY."
  type        = string
  default     = null
}

variable "additional_networks" {
  description = "Additional network interface details for GCE, if any."
  default     = []
  type = list(object({
    network            = string
    subnetwork         = string
    subnetwork_project = string
    network_ip         = string
    nic_type           = string
    stack_type         = string
    queue_count        = number
    access_config = list(object({
      nat_ip       = string
      network_tier = string
    }))
    ipv6_access_config = list(object({
      network_tier = string
    }))
    alias_ip_range = list(object({
      ip_cidr_range         = string
      subnetwork_range_name = string
    }))
  }))
  validation {
    condition = alltrue([
      for ni in var.additional_networks : ni.nic_type == "GVNIC" || ni.nic_type == "VIRTIO_NET" || ni.nic_type == null
    ])
    error_message = "In the variable additional_networks, field \"nic_type\" must be either \"GVNIC\", \"VIRTIO_NET\" or null."
  }
  validation {
    condition = alltrue([
      for ni in var.additional_networks : ni.stack_type == "IPV4_ONLY" || ni.stack_type == "IPV4_IPV6" || ni.stack_type == null
    ])
    error_message = "In the variable additional_networks, field \"stack_type\" must be either \"IPV4_ONLY\", \"IPV4_IPV6\" or null."
  }
}

variable "total_egress_bandwidth_tier" {
  description = "Egress bandwidth tier setting for supported VM families"
  type        = string
  default     = "DEFAULT"
  validation {
    condition     = contains(["DEFAULT", "TIER_1"], var.total_egress_bandwidth_tier)
    error_message = "Allowed values for bandwidth_tier are 'DEFAULT' or 'TIER_1'."
  }
}

###########
# metadata
###########

variable "startup_script" {
  description = "User startup script to run when instances spin up"
  type        = string
  default     = ""
}

variable "metadata" {
  type        = map(string)
  description = "Metadata, provided as a map"
  default     = {}
}

##################
# service_account
##################

variable "service_account" {
  type = object({
    email  = string
    scopes = set(string)
  })
  description = "Service account to attach to the instance. See https://www.terraform.io/docs/providers/google/r/compute_instance_template#service_account."
}

###########################
# Shielded VMs
###########################
variable "enable_shielded_vm" {
  type        = bool
  default     = false
  description = "Whether to enable the Shielded VM configuration on the instance. Note that the instance image must support Shielded VMs. See https://cloud.google.com/compute/docs/images"
}

variable "shielded_instance_config" {
  description = "Not used unless enable_shielded_vm is true. Shielded VM configuration for the instance."
  type = object({
    enable_secure_boot          = bool
    enable_vtpm                 = bool
    enable_integrity_monitoring = bool
  })

  default = {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

###########################
# Confidential Compute VMs
###########################
variable "enable_confidential_vm" {
  type        = bool
  default     = false
  description = "Whether to enable the Confidential VM configuration on the instance. Note that the instance image must support Confidential VMs. See https://cloud.google.com/compute/docs/images"
}

###########################
# Public IP
###########################
variable "access_config" {
  description = "Access configurations, i.e. IPs via which the VM instance can be accessed via the Internet."
  type = list(object({
    nat_ip       = string
    network_tier = string
  }))
  default = []
}

variable "ipv6_access_config" {
  description = "IPv6 access configurations. Currently a max of 1 IPv6 access configuration is supported. If not specified, the instance will have no external IPv6 Internet access."
  type = list(object({
    network_tier = string
  }))
  default = []
}

###########################
# Guest Accelerator (GPU)
###########################
variable "gpu" {
  description = "GPU information. Type and count of GPU to attach to the instance template. See https://cloud.google.com/compute/docs/gpus more details"
  type = object({
    type  = string
    count = number
  })
  default = null
}

##################
# alias IP range
##################
variable "alias_ip_range" {
  description = <<EOF
An array of alias IP ranges for this network interface. Can only be specified for network interfaces on subnet-mode networks.
ip_cidr_range: The IP CIDR range represented by this alias IP range. This IP CIDR range must belong to the specified subnetwork and cannot contain IP addresses reserved by system or used by other network interfaces. At the time of writing only a netmask (e.g. /24) may be supplied, with a CIDR format resulting in an API error.
subnetwork_range_name: The subnetwork secondary range name specifying the secondary range from which to allocate the IP CIDR range for this alias IP range. If left unspecified, the primary range of the subnetwork will be used.
EOF
  type = object({
    ip_cidr_range         = string
    subnetwork_range_name = string
  })
  default = null
}

###################################################################################################
variable "hostname" {
  description = "Hostname prefix for instances"
  type        = string
  default     = "default"
}

variable "mig_name" {
  type        = string
  description = "Managed instance group name. When variable is empty, name will be derived from var.hostname."
  default     = ""
}

variable "instance_template" {
  description = "Instance template self_link used to create compute instances"
  type        = string
}

variable "target_size" {
  description = "The target number of running instances for this managed instance group. This value should always be explicitly set unless this resource is attached to an autoscaler, in which case it should never be set."
  type        = number
  default     = 1
}

variable "target_pools" {
  description = "The target load balancing pools to assign this group to."
  type        = list(string)
  default     = []
}

variable "distribution_policy_target_shape" {
  description = "MIG target distribution shape (EVEN, BALANCED, ANY, ANY_SINGLE_ZONE)"
  type        = string
  default     = null
}

variable "distribution_policy_zones" {
  description = "The distribution policy, i.e. which zone(s) should instances be create in. Default is all zones in given region."
  type        = list(string)
  default     = []
}

variable "named_ports" {
  description = "Named name and named port. https://cloud.google.com/load-balancing/docs/backend-service#named_ports"
  type = list(object({
    name = string
    port = number
  }))
  default = []
}

variable "wait_for_instances" {
  description = "Whether to wait for all instances to be created/updated before returning. Note that if this is set to true and the operation does not succeed, Terraform will continue trying until it times out."
  type        = string
  default     = "false"
}

variable "mig_timeouts" {
  description = "Times for creation, deleting and updating the MIG resources. Can be helpful when using wait_for_instances to allow a longer VM startup time. "
  type = object({
    create = string
    update = string
    delete = string
  })
  default = {
    create = "5m"
    update = "5m"
    delete = "15m"
  }
}

#############
# Autoscaler
#############
variable "autoscaler_name" {
  type        = string
  description = "Autoscaler name. When variable is empty, name will be derived from var.hostname."
  default     = ""
}

variable "autoscaling_enabled" {
  description = "Creates an autoscaler for the managed instance group"
  default     = "false"
  type        = string
}

variable "max_replicas" {
  description = "The maximum number of instances that the autoscaler can scale up to. This is required when creating or updating an autoscaler. The maximum number of replicas should not be lower than minimal number of replicas."
  default     = 10
  type        = number
}

variable "min_replicas" {
  description = "The minimum number of replicas that the autoscaler can scale down to. This cannot be less than 0."
  default     = 2
  type        = number
}

variable "cooldown_period" {
  description = "The number of seconds that the autoscaler should wait before it starts collecting information from a new instance."
  default     = 60
  type        = number
}

variable "autoscaling_mode" {
  description = "Operating mode of the autoscaling policy. If omitted, the default value is ON. https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_autoscaler#mode"
  type        = string
  default     = null
}

variable "autoscaling_cpu" {
  description = "Autoscaling, cpu utilization policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler#cpu_utilization"
  type = list(object({
    target            = number
    predictive_method = string
  }))
  default = []
}

variable "autoscaling_metric" {
  description = "Autoscaling, metric policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler#metric"
  type = list(object({
    name   = string
    target = number
    type   = string
  }))
  default = []
}

variable "autoscaling_lb" {
  description = "Autoscaling, load balancing utilization policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler#load_balancing_utilization"
  type        = list(map(number))
  default     = []
}

variable "scaling_schedules" {
  description = "Autoscaling, scaling schedule block. https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_autoscaler#scaling_schedules"
  type = list(object({
    disabled              = bool
    duration_sec          = number
    min_required_replicas = number
    name                  = string
    schedule              = string
    time_zone             = string
  }))
  default = []
}

variable "autoscaling_scale_in_control" {
  description = "Autoscaling, scale-in control block. https://www.terraform.io/docs/providers/google/r/compute_autoscaler#scale_in_control"
  type = object({
    fixed_replicas   = number
    percent_replicas = number
    time_window_sec  = number
  })
  default = {
    fixed_replicas   = null
    percent_replicas = null
    time_window_sec  = null
  }
}

##############
# Healthcheck
##############

variable "health_check_name" {
  type        = string
  description = "Health check name. When variable is empty, name will be derived from var.hostname."
  default     = ""
}

variable "health_check" {
  description = "Health check to determine whether instances are responsive and able to do work"
  type = object({
    type                = string
    initial_delay_sec   = number
    check_interval_sec  = number
    healthy_threshold   = number
    timeout_sec         = number
    unhealthy_threshold = number
    response            = string
    proxy_header        = string
    port                = number
    request             = string
    request_path        = string
    host                = string
    enable_logging      = bool
  })
  default = {
    type                = ""
    initial_delay_sec   = 30
    check_interval_sec  = 30
    healthy_threshold   = 1
    timeout_sec         = 10
    unhealthy_threshold = 5
    response            = ""
    proxy_header        = "NONE"
    port                = 80
    request             = ""
    request_path        = "/"
    host                = ""
    enable_logging      = false
  }
}

#################
# Rolling Update
#################

variable "update_policy" {
  description = "The rolling update policy. https://www.terraform.io/docs/providers/google/r/compute_region_instance_group_manager#rolling_update_policy"
  type = list(object({
    max_surge_fixed              = number
    instance_redistribution_type = string
    max_surge_percent            = number
    max_unavailable_fixed        = number
    max_unavailable_percent      = number
    min_ready_sec                = number
    replacement_method           = string
    minimal_action               = string
    type                         = string
  }))
  default = []
}

#################
# Stateful disks
#################
variable "stateful_disks" {
  description = "Disks created on the instances that will be preserved on instance delete. https://cloud.google.com/compute/docs/instance-groups/configuring-stateful-disks-in-migs"
  type = list(object({
    device_name = string
    delete_rule = string
  }))
  default = []
}

#################
# Stateful IPs
#################
variable "stateful_ips" {
  description = "Statful IPs created on the instances that will be preserved on instance delete. https://cloud.google.com/compute/docs/instance-groups/configuring-stateful-ip-addresses-in-migs"
  type = list(object({
    interface_name = string
    delete_rule    = string
    is_external    = bool
  }))
  default = []
}