variable "gcp_region" {
  type = string
}

variable "gcp_project" {
  type        = string
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
  type        = string
  description = "Name for this infrastructure"
  default     = "mig-vpc"
}

variable "subnet_cidr_range" {
  type        = list(string)
  description = "List of The range of addresses"
  default     = ["10.10.10.0/24", "10.10.20.0/24"]
}

variable "name" {
  type        = string
  description = "Name for this infrastructure"
  default     = "tfvpcname"
}

variable "subnet_region" {
  type = list(string)
}


####################################### Instane Templates #################
variable "mig_region" {
  type = string
}
variable "mig_name" {
  type = string
}
variable "machine_type" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "labels" {
  type = map(string)
}

variable "metadata" {
  type = map(string)
}
####################################################### LB ###################
variable "lb-name" {
  type = string
}

variable "fb-service" {
  type = string
}

variable "backend-svc-name" {
  type = string
}

variable "bg-protocol" {
  type = string
}