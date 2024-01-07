terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

######################## VPC & SUBNET #########################
locals {
  subnets = ["private1", "private2"]
}

provider "google" {
  credentials = file("terraform-on-gcp.json")
  project     = var.gcp_project
  region      = var.gcp_region
}

resource "google_compute_network" "mig_vpc" {
  name                            = var.vpcname
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
}

resource "google_compute_subnetwork" "migsubnet" {
  count                    = 2
  name                     = "${var.name}-${local.subnets[count.index]}-subnet"
  ip_cidr_range            = var.subnet_cidr_range[count.index]
  region                   = var.subnet_region[count.index]
  network                  = google_compute_network.mig_vpc.id
  private_ip_google_access = true
  depends_on               = [google_compute_network.mig_vpc]
}

################################ FIREWALL RULE #########################################
resource "google_compute_firewall" "mig-firewall" {
  name    = "test-firewall"
  network = google_compute_network.mig_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8080", "22", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "helth-check" {
  name    = "app-allow-health-check"
  network = google_compute_network.mig_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}


#############################################################################

################################### INSTANCE TEMPLATE #######################

resource "google_compute_instance_template" "mig_template" {

  #name_prefix             = "${var.name_prefix}-"
  name         = var.mig_name
  project      = var.gcp_project
  machine_type = var.machine_type
  labels       = var.labels
  metadata     = var.metadata
  #metadata_startup_script = var.startup_script
  region = var.mig_region

  can_ip_forward = false

  scheduling {
    automatic_restart = false
    preemptible       = true

  }

  disk {
    source_image = "centos-cloud/centos-7"
    auto_delete  = true
    disk_size_gb = 20
    boot         = true
  }

  network_interface {
    #network    = "jenkinsvpc"
    network    = google_compute_network.mig_vpc.name
    subnetwork = "tfvpcname-private1-subnet"
    #subnetwork = "jenkinssubnet"
    access_config {}

  }

  depends_on = [google_compute_network.mig_vpc, google_compute_subnetwork.migsubnet]
}

data "google_compute_image" "mig_image" {
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_disk" "mig-disk" {
  name  = "existing-disk"
  image = data.google_compute_image.mig_image.self_link
  size  = 20
  type  = "pd-standard"
  zone  = "us-east1-b"
}

################################################################################################
######################################## Managed Instance Group ################################
resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds
  http_health_check {
    #request_path = "/healthz"
    port = "80"
  }
}

resource "google_compute_region_instance_group_manager" "appserver" {
  name                      = "appserver-igm"
  base_instance_name        = "app"
  region                    = "us-east1"
  distribution_policy_zones = ["us-east1-b", "us-east1-c", "us-east1-d"]
  #region                    = "us-central1"
  #distribution_policy_zones = ["us-central1-a", "us-central1-b", "us-central1-c"]
  version {
    instance_template = google_compute_instance_template.mig_template.self_link_unique
  }
  target_size = 3



  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}


###################################### Load Balancer ###########################################

resource "google_compute_backend_service" "default" {
  description                     = "mig-backend-service"
  project                         = var.gcp_project
  name                            = var.backend-svc-name
  protocol                        = var.bg-protocol
  timeout_sec                     = 30
  session_affinity                = "NONE"
  #enable_cdn                      = "true"
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  locality_lb_policy              = "ROUND_ROBIN"
  connection_draining_timeout_sec = "300"

  health_checks = [google_compute_health_check.autohealing.id]
  
backend {
    group           = google_compute_region_instance_group_manager.appserver.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

}

resource "google_compute_url_map" "mg-url-map" {
  name            = "${var.lb-name}-url-map"
  default_service = google_compute_backend_service.default.id
  depends_on = [ google_compute_backend_service.default]
}

resource "google_compute_target_http_proxy" "http" {
  #count   = var.enable_http ? 1 : 0
  project = var.gcp_project
  name    = "${var.lb-name}-target-proxy"
  url_map = google_compute_url_map.mg-url-map.id
  depends_on = [google_compute_url_map.mg-url-map]
}

resource "google_compute_global_forwarding_rule" "http" {
  project               = var.gcp_project
  name                  = "${var.name}-http-rule"
  target                = google_compute_target_http_proxy.http.id
  port_range            = "80"
  ip_protocol           = "TCP"
  description           = "mig-frontend-service"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  depends_on = [ google_compute_target_http_proxy.http ]
  
}


