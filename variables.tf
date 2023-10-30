##  Copyright 2023 Google LLC
##  
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##  
##      https://www.apache.org/licenses/LICENSE-2.0
##  
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.


##  This code creates demo environment for GenAI Security for Vertex AI   ##
##  This demo code is not built for production workload ##

# set specific variables here for your own deployment

/******************************
    REQUIRED TO CHANGE
******************************/
variable "organization_id" {
  type        = string
  description = "organization id required"
  default     = "XXXXX"
}


variable "billing_account" {
  type        = string
  description = "billing account required"
  default     = "XXXXX-XXXXX-XXXXX"
}


variable "vpc_sc_users" {
  description = "User Email address that will need access through VPC-SC"
  type        = list(any)
  default     = ["user:USER@DOMAIN.com"]
}


variable "firewall_ips_enabled" {
  description = "Set the resources for IPS capability of firewall plus"
  type        = bool
  default     = false
}


variable "instance_owners" {
  description = "User Email address that will own Vertex Workbench"
  type        = list(any)
  default     = ["USER@DOMAIN.com"]
}


/*****************************
RECOMMENDED DEFAULTS - DO NOT CHANGE

unless you really really want to :)
*****************************/

variable "folder_name" {
  type        = string
  default     = "GenAI Security Training"
  description = "A folder to create this project under. If none is provided, the project will be created under the organization"
}

variable "project_name" {
  type        = string
  default     = "vertex-security"
  description = "vertex workbench project to be created"
}


variable "labels" {
  description = "A set of key/value label pairs to assign to the project."
  type        = map(string)

  default = {
    environment = "development"
  }
}
variable "environment" {
  description = "Environment tag to help identify the entire deployment"
  type        = string
  default     = "qa-test"
}

variable "skip_delete" {
  description = " If true, the Terraform resource can be deleted without deleting the Project via the Google API."
  default     = "false"
}

variable "region" {
  description = "what region to deploy to"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "The GCP zone to create the instance in"
  type        = string
  default     = "us-east1-b"
}

variable "roles" {
  type        = list(string)
  description = "The roles that will be granted to the service account."
  default     = ["roles/compute.admin", "roles/iam.serviceAccountUser", "roles/dlp.user", "roles/aiplatform.serviceAgent", "roles/storage.admin"]
}

variable "vpc-tf-roles" {
  type        = list(string)
  description = "The roles that will be granted to the service account."
  default     = ["roles/serviceusage.serviceUsageAdmin", "roles/accesscontextmanager.policyAdmin", "roles/resourcemanager.organizationViewer", "roles/iam.organizationRoleViewer"]
}
variable "workbench_name" {
  type        = string
  description = "name for workbench instance"
  default     = "securevertex-notebook"

}

variable "machine_type" {
  type        = string
  description = "compute engine machine type that workbench will run on"
  default     = "c2d-standard-2"

}

variable "secure_boot" {
  type        = bool
  description = "compute engine machine type that workbench will run on"
  default     = true

}

variable "source_image_family" {
  description = "The OS Image family"
  type        = string
  default     = "common-cu110-notebooks"
  #"common-cpu-notebooks-ubuntu-2004"
  #gcloud compute images list --project deeplearning-platform-release
}

variable "source_image_project" {
  description = "Google Cloud project with OS Image"
  type        = string
  default     = "deeplearning-platform-release"
}

variable "enable_gpu" {
  type        = bool
  description = "sets gpu enablement on the compute instance for vertex workbench"
  default     = false

}

variable "boot_disk_type" {
  type        = string
  description = "Possible disk types for notebook instances. Possible values are: DISK_TYPE_UNSPECIFIED, PD_STANDARD, PD_SSD, PD_BALANCED, PD_EXTREME"
  default     = "PD_SSD"
}

variable "boot_disk_size_gb" {
  type        = string
  description = "The size of the boot disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB). The minimum recommended value is 100 GB. If not specified, this defaults to 100."
  default     = "100"
}

variable "data_disk_type" {
  type        = string
  description = "Possible disk types for notebook instances. Possible values are: DISK_TYPE_UNSPECIFIED, PD_STANDARD, PD_SSD, PD_BALANCED, PD_EXTREME"
  default     = "PD_SSD"
}

variable "data_disk_size_gb" {
  type        = string
  description = "The size of the boot disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB). The minimum recommended value is 100 GB. If not specified, this defaults to 100."
  default     = "100"
}

variable "no_remove_data_disk" {
  type        = bool
  description = "If true, the data disk will not be auto deleted when deleting the instance."
  default     = false
}

variable "disk_encryption" {
  type        = string
  description = "Disk encryption method used on the boot and data disks, defaults to GMEK. Possible values are: DISK_ENCRYPTION_UNSPECIFIED, GMEK, CMEK"
  default     = "GMEK"
}

variable "no_public_ip" {
  type        = bool
  description = "No public IP will be assigned to this instance"
  default     = true
}

variable "no_proxy_access" {
  type        = bool
  description = "The notebook instance will not register with the proxy"
  default     = false
}

variable "create_default_access_policy" {
  type        = bool
  default     = false
  description = "Whether a default access policy needs to be created for the organization. If one already exists, this should be set to false."
}


variable "update-schedule" {
  type        = string
  description = "The time period you specify is stored as a notebook-upgrade-schedule metadata entry, in unix-cron format, Greenwich Mean Time (GMT)."
  default     = "0 7 * * SUN"
}


# VPC-SC
variable "vpc_sc_policy_name" {
  description = "The policy's name."
  type        = string
  default     = "service_perimeter_genai"
}

variable "perimeter_name" {
  description = "Name of perimeter."
  type        = string
  default     = "regular_perimeter"
}

variable "restricted_services" {
  description = "List of services to restrict."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "notebooks.googleapis.com",
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com",
  ]
}


variable "enforced_regional_access" {
  description = "CountryRegion "
  type        = list(string)
  default = [
    "US", # USA
    "CA", # Canada
    #    "UM", #  US Minor Outlying Islands
  ]
}

variable "network_name" {
  default = "securevertex-vpc"
  type    = string
}

variable "subnet_name" {
  default = "securevertex-subnet-a"
  type    = string
}


variable "domainname" {
  default = "example.com"
  type    = string
}

variable "certificate_name" {
  default = "secure-web-proxy-cert"
  type    = string
}

variable "key_name" {
  default = "secure-web-proxy-key"
  type    = string
}

variable "policy_name" {
  default = "secure-web-proxy"
  type    = string
}

variable "policy_file" {
  default = "basic_policy.yaml"
  type    = string
}

variable "url_name" {
  default = "external-url-list"
  type    = string
}

variable "url_file" {
  default = "url_policy.yaml"
  type    = string
}

variable "rule_name" {
  default = "external-respository"
  type    = string
}

variable "rule_file" {
  default = "rule_policy.yaml"
  type    = string
}

variable "gateway_name" {
  default = "secure-web-proxy"
  type    = string
}

variable "gateway_file" {
  default = "gateway_policy.yaml"
  type    = string
}
