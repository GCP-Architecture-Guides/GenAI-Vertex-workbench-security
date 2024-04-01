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


resource "random_id" "random_suffix" {
  byte_length = 3
}


# Create Folder in GCP Organization
resource "google_folder" "genai_training" {
  display_name = var.folder_name
  # parent       = "organizations/${var.organization_id}"
  parent       = "folders/276635808742"
}


// Create a basic project.
resource "google_project" "vertex-project" {
  billing_account = var.billing_account
  #  org_id              = var.organization_id
  folder_id  = google_folder.genai_training.name
  labels     = var.labels
  name       = var.project_name
  project_id = "${var.project_name}-${random_id.random_suffix.hex}"

  // Only one of `org_id` or `folder_id` may be specified, so we prefer the folder here.
  // Note that `organization_id` is required, making this safe.
  //org_id = var.folder_id == "" ? var.organization_id : var.folder_id

  skip_delete = var.skip_delete
  depends_on  = [google_folder.genai_training]
}



# Enable the necessary API services
resource "google_project_service" "gcp_apis" {
  for_each = toset([
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "notebooks.googleapis.com",
    "dns.googleapis.com",
    "artifactregistry.googleapis.com",
    "storage.googleapis.com",
    "logging.googleapis.com",
    "aiplatform.googleapis.com",
    "compute.googleapis.com",
    "networkservices.googleapis.com",
    "certificatemanager.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "networksecurity.googleapis.com",
    "bigquery.googleapis.com",
    "dlp.googleapis.com",
  ])

  service                    = each.key
  project                    = google_project.vertex-project.project_id
  disable_on_destroy         = false
  disable_dependent_services = false
  depends_on                 = [google_project.vertex-project]
}



// Set Org policies to allow Vertex AI Workbench configuration

module "org-policy-requireShieldedVm" {
  source      = "terraform-google-modules/org-policy/google"
  policy_for  = "project"
  project_id  = google_project.vertex-project.project_id
  constraint  = "compute.requireShieldedVm"
  policy_type = "boolean"
  enforce     = false
}

/*
## To allow access beyond your org; to be disabled before broader rollout
module "org-policy-domain-restricted-sharing" {
  source      = "terraform-google-modules/org-policy/google"
  policy_for  = "project"
  project_id  = google_project.vertex-project.project_id
  constraint  = "iam.allowedPolicyMemberDomains"
  policy_type = "list"
  enforce     = false
}



module "org-policy-vmExternalIpAccess" {
  source      = "terraform-google-modules/org-policy/google"
  policy_for  = "project"
  project_id  = google_project.vertex-project.project_id
  constraint  = "compute.vmExternalIpAccess"
  policy_type = "list"
  enforce     = false
}
*/


resource "time_sleep" "wait_for_org_policy" {
  depends_on = [module.org-policy-requireShieldedVm,
    # module "org-policy-domain-restricted-sharing,
    # module.org-policy-vmExternalIpAccess, 
    google_project_service.gcp_apis
  ]
  create_duration  = "150s"
  destroy_duration = "30s"
}



module "data_project" {
  source                = "./data-project"
  folder_id             = google_folder.genai_training.name
  project_name          = "data-project"
  organization_id       = var.organization_id
  region                = var.region
  random_string         = random_id.random_suffix.hex
  billing_account       = var.billing_account
  skip_delete           = var.skip_delete
  labels                = var.labels
  notebook_srv_account  = google_service_account.sa.email
  vpc_sc_users          = var.vpc_sc_users
  vertex_project_number = google_project.vertex-project.number
  srv1                  = "serviceAccount:${google_service_account.sa.email}"
  srv2                  = "serviceAccount:service-${google_project.vertex-project.number}@compute-system.iam.gserviceaccount.com"
}
