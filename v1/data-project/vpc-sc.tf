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


resource "google_access_context_manager_access_policy" "access_context_manager_policy_data_project" {
  provider   = google-beta.data
  parent     = "organizations/${var.organization_id}"
  title      = "data_project_policy"
  scopes     = ["projects/${google_project.data_vertex-project.number}"]
  depends_on = [google_bigquery_job.import_job_bq]
}


resource "google_access_context_manager_service_perimeter" "service_perimeter_data_project" {
  provider    = google-beta.data
  parent      = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy_data_project.name}"
  name        = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy_data_project.name}/servicePerimeters/data_perimeter"
  description = "Perimeter_data_project"
  title       = "data_perimeter"
  #    use_explicit_dry_run_spec = true  
  status {
    #     spec {
    restricted_services = [
      "storage.googleapis.com",
      "bigquery.googleapis.com",
    ]

    resources = ["projects/${google_project.data_vertex-project.number}"]

    ## Cloud Shell access
    ingress_policies {
      ingress_to {
        resources = ["*"]
        operations {
          service_name = "*"
          #method_selectors {
          #   method = "*"
          #}
        }
      }

      ingress_from {
        #    identity_type = "ANY_IDENTITY"
        identities = var.vpc_sc_users
        sources {
          resource = "projects/751522334863" ## This project is to allow cloudshell access, disable if not using cloudshell
        }
      }
    }

    ## Ingress access from vertex project
    ingress_policies {
      ingress_to {
        resources = ["projects/${google_project.data_vertex-project.number}"]
        operations {
          service_name = "bigquery.googleapis.com"

          method_selectors {
            method = "*"
          }
        }
        operations {
          service_name = "storage.googleapis.com"
          method_selectors {
            method = "*"
          }
        }
      }

      ingress_from {
        #    identity_type = "ANY_IDENTITY"
        identities = [
          "${var.srv1}",
          "${var.srv2}",
        ]
        sources {
          resource = "projects/${var.vertex_project_number}"
        }
      }
    }
  }
  depends_on = [
    google_access_context_manager_access_policy.access_context_manager_policy_data_project,
  ]
}