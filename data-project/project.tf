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



// Create a basic project.
resource "google_project" "data_vertex-project" {
  billing_account = var.billing_account
  #  org_id              = var.organization_id
  folder_id  = var.folder_id
  labels     = var.labels
  name       = var.project_name
  project_id = "${var.project_name}-${var.random_string}"

  // Only one of `org_id` or `folder_id` may be specified, so we prefer the folder here.
  // Note that `organization_id` is required, making this safe.
  //org_id = var.folder_id == "" ? var.organization_id : var.folder_id

  skip_delete = var.skip_delete
}

resource "random_id" "random_suffix" {
  byte_length = 4
}



# Enable the necessary API services
resource "google_project_service" "data_gcp_apis" {
  for_each = toset([
    "storage.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com",
    "accesscontextmanager.googleapis.com",
  ])

  service = each.key

  project                    = google_project.data_vertex-project.project_id
  disable_on_destroy         = false
  disable_dependent_services = false
  depends_on                 = [google_project.data_vertex-project]
}


# Wait delay after enabling APIs
resource "time_sleep" "wait_enable_service_data" {
  depends_on       = [google_project_service.data_gcp_apis]
  create_duration  = "100s"
  destroy_duration = "100s"
}