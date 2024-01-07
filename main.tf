terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

##########################################################################################################
#########
# Locals
#########

locals {
  source_image         = var.source_image != "" ? var.source_image : "centos-7-v20201112"
  source_image_family  = var.source_image_family != "" ? var.source_image_family : "centos-7"
  source_image_project = var.source_image_project != "" ? var.source_image_project : "centos-cloud"

  boot_disk = [
    {
      source_image = var.source_image != "" ? format("${local.source_image_project}/${local.source_image}") : format("${local.source_image_project}/${local.source_image_family}")
      disk_size_gb = var.disk_size_gb
      disk_type    = var.disk_type
      disk_labels  = var.disk_labels
      auto_delete  = var.auto_delete
      boot         = "true"
    },
  ]

  all_disks = concat(local.boot_disk, var.additional_disks)

  # NOTE: Even if all the shielded_instance_config or confidential_instance_config
  # values are false, if the config block exists and an unsupported image is chosen,
  # the apply will fail so we use a single-value array with the default value to
  # initialize the block only if it is enabled.
  shielded_vm_configs = var.enable_shielded_vm ? [true] : []

  gpu_enabled            = var.gpu != null
  alias_ip_range_enabled = var.alias_ip_range != null
  on_host_maintenance = (
    var.preemptible || var.enable_confidential_vm || local.gpu_enabled || var.spot
    ? "TERMINATE"
    : var.on_host_maintenance
  )
  automatic_restart = (
    # must be false when preemptible or spot is true
    var.preemptible || var.spot ? false : var.automatic_restart
  )
  preemptible = (
    # must be true when preemtible or spot is true
    var.preemptible || var.spot ? true : false
  )
}

####################
# Instance Template
####################
resource "google_compute_instance_template" "tpl" {
  name_prefix             = "${var.name_prefix}-"
  project                 = var.project_id
  machine_type            = var.machine_type
  labels                  = var.labels
  metadata                = var.metadata
  tags                    = var.tags
  can_ip_forward          = var.can_ip_forward
  metadata_startup_script = var.startup_script
  region                  = var.region
  min_cpu_platform        = var.min_cpu_platform
  resource_policies       = var.resource_policies
  dynamic "disk" {
    for_each = local.all_disks
    content {
      auto_delete     = lookup(disk.value, "auto_delete", null)
      boot            = lookup(disk.value, "boot", null)
      device_name     = lookup(disk.value, "device_name", null)
      disk_name       = lookup(disk.value, "disk_name", null)
      disk_size_gb    = lookup(disk.value, "disk_size_gb", lookup(disk.value, "disk_type", null) == "local-ssd" ? "375" : null)
      disk_type       = lookup(disk.value, "disk_type", null)
      interface       = lookup(disk.value, "interface", lookup(disk.value, "disk_type", null) == "local-ssd" ? "NVME" : null)
      mode            = lookup(disk.value, "mode", null)
      source          = lookup(disk.value, "source", null)
      source_image    = lookup(disk.value, "source_image", null)
      source_snapshot = lookup(disk.value, "source_snapshot", null)
      type            = lookup(disk.value, "disk_type", null) == "local-ssd" ? "SCRATCH" : "PERSISTENT"
      labels          = lookup(disk.value, "disk_labels", null)

      dynamic "disk_encryption_key" {
        for_each = compact([var.disk_encryption_key == null ? null : 1])
        content {
          kms_key_self_link = var.disk_encryption_key
        }
      }
    }
  }

  dynamic "service_account" {
    for_each = var.service_account == null ? [] : [var.service_account]
    content {
      email  = lookup(service_account.value, "email", null)
      scopes = lookup(service_account.value, "scopes", null)
    }
  }

  network_interface {
    network            = var.network
    subnetwork         = var.subnetwork
    subnetwork_project = var.subnetwork_project
    network_ip         = length(var.network_ip) > 0 ? var.network_ip : null
    nic_type           = var.nic_type
    stack_type         = var.stack_type
    dynamic "access_config" {
      for_each = var.access_config
      content {
        nat_ip       = access_config.value.nat_ip
        network_tier = access_config.value.network_tier
      }
    }
    dynamic "ipv6_access_config" {
      for_each = var.ipv6_access_config
      content {
        network_tier = ipv6_access_config.value.network_tier
      }
    }
    dynamic "alias_ip_range" {
      for_each = local.alias_ip_range_enabled ? [var.alias_ip_range] : []
      content {
        ip_cidr_range         = alias_ip_range.value.ip_cidr_range
        subnetwork_range_name = alias_ip_range.value.subnetwork_range_name
      }
    }
  }

  dynamic "network_interface" {
    for_each = var.additional_networks
    content {
      network            = network_interface.value.network
      subnetwork         = network_interface.value.subnetwork
      subnetwork_project = network_interface.value.subnetwork_project
      network_ip         = length(network_interface.value.network_ip) > 0 ? network_interface.value.network_ip : null
      nic_type           = network_interface.value.nic_type
      stack_type         = network_interface.value.stack_type
      queue_count        = network_interface.value.queue_count
      dynamic "access_config" {
        for_each = network_interface.value.access_config
        content {
          nat_ip       = access_config.value.nat_ip
          network_tier = access_config.value.network_tier
        }
      }
      dynamic "ipv6_access_config" {
        for_each = network_interface.value.ipv6_access_config
        content {
          network_tier = ipv6_access_config.value.network_tier
        }
      }
      dynamic "alias_ip_range" {
        for_each = network_interface.value.alias_ip_range
        content {
          ip_cidr_range         = alias_ip_range.value.ip_cidr_range
          subnetwork_range_name = alias_ip_range.value.subnetwork_range_name
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = "true"
  }

  scheduling {
    preemptible                 = local.preemptible
    automatic_restart           = local.automatic_restart
    on_host_maintenance         = local.on_host_maintenance
    provisioning_model          = var.spot ? "SPOT" : null
    instance_termination_action = var.spot ? var.spot_instance_termination_action : null
  }

  advanced_machine_features {
    enable_nested_virtualization = var.enable_nested_virtualization
    threads_per_core             = var.threads_per_core
  }

  dynamic "shielded_instance_config" {
    for_each = local.shielded_vm_configs
    content {
      enable_secure_boot          = lookup(var.shielded_instance_config, "enable_secure_boot", shielded_instance_config.value)
      enable_vtpm                 = lookup(var.shielded_instance_config, "enable_vtpm", shielded_instance_config.value)
      enable_integrity_monitoring = lookup(var.shielded_instance_config, "enable_integrity_monitoring", shielded_instance_config.value)
    }
  }

  confidential_instance_config {
    enable_confidential_compute = var.enable_confidential_vm
  }

  network_performance_config {
    total_egress_bandwidth_tier = var.total_egress_bandwidth_tier
  }

  dynamic "guest_accelerator" {
    for_each = local.gpu_enabled ? [var.gpu] : []
    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }
}

##########################################################################################################
locals {
  subnets = ["public","private"]
}

locals {
  healthchecks = concat(
    google_compute_health_check.https[*].self_link,
    google_compute_health_check.http[*].self_link,
    google_compute_health_check.tcp[*].self_link,
  )
  distribution_policy_zones    = coalescelist(var.distribution_policy_zones, data.google_compute_zones.available.names)
  autoscaling_scale_in_enabled = var.autoscaling_scale_in_control.fixed_replicas != null || var.autoscaling_scale_in_control.percent_replicas != null
}

provider "google" {
  credentials = file("terraform-on-gcp.json")
  project     = var.gcp_project
  region      = var.gcp_region
}

resource "google_compute_network" "mig_vpc" {
  name = var.vpcname
  delete_default_routes_on_create = false
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
}

resource"google_compute_subnetwork""migsubnet" {
count= 2
name="${var.name}-${local.subnets[count.index]}-subnet"
ip_cidr_range= var.subnet_cidr_range[count.index]
region=var.subnet_region[count.index]
network=google_compute_network.mig_vpc.id
private_ip_google_access =true
}

resource "google_compute_region_instance_group_manager" "mig" {
  provider           = google-beta
  base_instance_name = var.hostname
  project            = var.gcp_project

  version {
    name              = "${var.hostname}-mig-version-0"
    instance_template = var.instance_template
  }

  name   = var.mig_name == "" ? "${var.hostname}-mig" : var.mig_name
  region = var.gcp_region
  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = lookup(named_port.value, "name", null)
      port = lookup(named_port.value, "port", null)
    }
  }
  target_pools = var.target_pools
  target_size  = var.autoscaling_enabled ? null : var.target_size

  wait_for_instances = var.wait_for_instances

  dynamic "auto_healing_policies" {
    for_each = local.healthchecks
    content {
      health_check      = auto_healing_policies.value
      initial_delay_sec = var.health_check["initial_delay_sec"]
    }
  }

  dynamic "stateful_disk" {
    for_each = var.stateful_disks
    content {
      device_name = stateful_disk.value.device_name
      delete_rule = lookup(stateful_disk.value, "delete_rule", null)
    }
  }

  dynamic "stateful_internal_ip" {
    for_each = [for static_ip in var.stateful_ips : static_ip if static_ip["is_external"] == false]
    content {
      interface_name = stateful_internal_ip.value.interface_name
      delete_rule    = lookup(stateful_internal_ip.value, "delete_rule", null)
    }
  }

  dynamic "stateful_external_ip" {
    for_each = [for static_ip in var.stateful_ips : static_ip if static_ip["is_external"] == true]
    content {
      interface_name = stateful_external_ip.value.interface_name
      delete_rule    = lookup(stateful_external_ip.value, "delete_rule", null)
    }
  }

  distribution_policy_target_shape = var.distribution_policy_target_shape
  distribution_policy_zones        = local.distribution_policy_zones
  dynamic "update_policy" {
    for_each = var.update_policy
    content {
      instance_redistribution_type = lookup(update_policy.value, "instance_redistribution_type", null)
      max_surge_fixed              = lookup(update_policy.value, "max_surge_fixed", null)
      max_surge_percent            = lookup(update_policy.value, "max_surge_percent", null)
      max_unavailable_fixed        = lookup(update_policy.value, "max_unavailable_fixed", null)
      max_unavailable_percent      = lookup(update_policy.value, "max_unavailable_percent", null)
      min_ready_sec                = lookup(update_policy.value, "min_ready_sec", null)
      replacement_method           = lookup(update_policy.value, "replacement_method", null)
      minimal_action               = update_policy.value.minimal_action
      type                         = update_policy.value.type
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [distribution_policy_zones]
  }

  timeouts {
    create = var.mig_timeouts.create
    update = var.mig_timeouts.update
    delete = var.mig_timeouts.delete
  }
}

