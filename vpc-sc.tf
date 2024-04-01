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


resource "time_sleep" "vpc_access_policy_wait" {

  create_duration  = "45s"
  destroy_duration = "60s"
  depends_on = [
  #  resource.null_resource.set_secure_boot,
    time_sleep.wait_for_notebook,
    google_storage_bucket.notebook_bucket,
    google_storage_bucket.bucket,
    google_network_services_gateway.default,
  ]
}

resource "google_access_context_manager_access_policy" "access_context_manager_policy" {
  provider   = google-beta.service
  parent     = "organizations/${var.organization_id}"
  title      = "${var.vpc_sc_policy_name}_policy"
  scopes     = ["projects/${google_project.vertex-project.number}"]
  depends_on = [time_sleep.vpc_access_policy_wait]
}


resource "google_access_context_manager_access_level" "access_level" {
  provider = google-beta.service
  parent   = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}"
  name     = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}/accessLevels/${var.vpc_sc_policy_name}_levels"
  title    = "${var.vpc_sc_policy_name}_levels"
  basic {
    conditions {
      members = var.vpc_sc_users
      regions = var.enforced_regional_access
    }
  }
  depends_on = [google_access_context_manager_access_policy.access_context_manager_policy]
}

resource "google_access_context_manager_access_level" "service_account" {
  provider = google-beta.service
  parent   = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}"
  name     = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}/accessLevels/${var.vpc_sc_policy_name}_levels_srv"
  title    = "${var.vpc_sc_policy_name}_levels_srv"
  basic {
    conditions {
      members = ["serviceAccount:${google_service_account.sa.email}",
        "serviceAccount:service-${google_project.vertex-project.number}@compute-system.iam.gserviceaccount.com",
      ]

    }
  }
  depends_on = [google_access_context_manager_access_policy.access_context_manager_policy]
}


data "google_project" "data_project" {
  project_id = "data-project-${random_id.random_suffix.hex}"
  depends_on = [
    time_sleep.wait_for_org_policy,
    module.data_project.google_project,
  ]
}




resource "time_sleep" "vpc_sc_wait" {
  depends_on = [
    google_access_context_manager_access_policy.access_context_manager_policy,
    google_access_context_manager_access_level.access_level,
  ]
  create_duration  = "60s"
  destroy_duration = "90s"
}




resource "google_access_context_manager_service_perimeter" "service_perimeter" {
  provider    = google-beta.service
  parent      = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}"
  name        = "accessPolicies/${google_access_context_manager_access_policy.access_context_manager_policy.name}/servicePerimeters/${var.perimeter_name}"
  description = "Perimeter_${var.perimeter_name}"
  title       = var.perimeter_name
  #  use_explicit_dry_run_spec = true  
  status {
    # spec {
    restricted_services = var.restricted_services
    access_levels = [
      google_access_context_manager_access_level.access_level.name,
      google_access_context_manager_access_level.service_account.name,
    ]
    resources = ["projects/${google_project.vertex-project.number}"]

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
    egress_policies {
      egress_from {
        identities = ["serviceAccount:${google_service_account.sa.email}",
        "serviceAccount:service-${google_project.vertex-project.number}@compute-system.iam.gserviceaccount.com"]
      }

      egress_to {
        resources = ["projects/${data.google_project.data_project.number}"]
 #         resources = ["projects/${module.data_project.google_project.data_vertex-project.number}"]
        operations {
          service_name = "*"
        }
      }


    }
  }
  depends_on = [
    time_sleep.vpc_sc_wait,
    data.google_project.data_project,
#module.data_project.google_project.data_vertex-project,
  ]
}


resource "time_sleep" "vpc_sc_apply_wait" {
  depends_on = [
    google_access_context_manager_service_perimeter.service_perimeter,

  ]
  create_duration = "45s"
  #  destroy_duration = "90s"
}

