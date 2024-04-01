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


/*************************************
    Vertex AI Workbench Instance

    all variables and their defaults can be
    can be found in variables.tf under
    the root directory
************************************/

/*************************************
    Vertex AI Workbench Instance

    all variables and their defaults can be
    can be found in variables.tf under
    the root directory
************************************/
resource "google_workbench_instance" "vertex_workbench_instance" {
  project      = google_project.vertex-project.project_id
  name         = var.workbench_name #default: securevertex-notebook
  location     = var.zone           #default: us-central1-a
  disable_proxy_access = var.no_proxy_access #default: false

  gce_setup {
  machine_type = var.machine_type   #default: c2d-standard-2 (2 vCPU, 8GB RAM)
    vm_image {
    project      = var.source_image_project #default: deeplearning-platform-release
    family = var.source_image_family  #default: common-cpu-notebooks-ubuntu-2004
    }
/*****************************************************
no GPU enabled on the workbench instance for this template. 
However the terraform would look something like this:


  dynamic "accelerator_config" {
    for_each = var.enable_gpu ? [1] : []
    content {
      core_count = var.accelerator_config_core_count
      type       = var.accelerator_config_type
    }
  }

  
******************************************************/

  
    #  instance_owners = [google_service_account.sa.email]
  service_accounts {
    email = google_service_account.sa.email
  }

   shielded_instance_config {
    enable_secure_boot          = var.secure_boot #default: true
    enable_integrity_monitoring = true
    enable_vtpm                 = true
  }

    #install_gpu_driver = var.enable_gpu #default: false
boot_disk {
  disk_type      = var.boot_disk_type      #default: PD_SSD
  disk_size_gb   = var.boot_disk_size_gb   #default 150 GB
  #  disk_encryption     = var.disk_encryption     #default: GMEK
  }

  data_disks {
  disk_type      = var.data_disk_type      #default: PD_SSD
  disk_size_gb   = var.data_disk_size_gb   #default: 150 GB
#  no_remove_data_disk = var.no_remove_data_disk #default: false Not supported
#  disk_encryption     = var.disk_encryption     #default: GMEK
  }

  disable_public_ip    = var.no_public_ip    #default: true
  network_interfaces {
  network             = google_compute_network.vpc_network.id
  subnet              = google_compute_subnetwork.securevertex-subnet-a.id
  }
  //labels = merge(local.required_labels, var.labels)
  metadata = {
    notebook-disable-root      = "true"
    notebook-disable-downloads = "true"
    notebook-disable-nbconvert = "false"
    serial-port-enable         = "false"
    block-project-ssh-keys     = "true"
    proxy-mode                 = "service_account"
    notebook-upgrade-schedule  = var.update-schedule               #default: "0 7 * * SUN" = weekly Sunday morning 2am US Eastern
    gcs-data-bucket            = google_storage_bucket.bucket.name #enables jupyter notebook backups
    PROJ_ID                    = google_project.vertex-project.project_id
    DATASET                    = "dataset_${random_id.random_suffix.hex}"
    DATA_PROJ_ID               = "${data.google_project.data_project.project_id}"
    DATA_BUCKET                = "data-bucket-${random_id.random_suffix.hex}"
    PROXY_IP                   = "${google_network_services_gateway.default.addresses[0]}:443"
    post_startup_script = "gs://${google_storage_bucket.notebook_bucket.name}/${google_storage_bucket_object.notebook.name}"
  }
  }



  depends_on = [
    google_storage_bucket.bucket,
    google_storage_bucket.notebook_bucket,
    time_sleep.wait_for_org_policy,
    google_service_account.sa,
    #resource.null_resource.create_secure_web_gateway,
    #    resource.null_resource.destroy_secure_web_proxy,
    #   google_network_services_gateway.default,
    time_sleep.wait_for_swp,
  ]
}

/*
resource "google_workbench_instance" "vertex_workbench_instance_2" {
  project      = google_project.vertex-project.project_id
  name         = "${var.workbench_name}-2" #default: securevertex-notebook
  location     = var.zone                  #default: us-central1-a
  disable_proxy_access = var.no_proxy_access #default: false

   instance_owners = var.instance_owners
  gce_setup {
  machine_type = var.machine_type          #default: c2d-standard-2 (2 vCPU, 8GB RAM)

  vm_image {
    project      = var.source_image_project #default: deeplearning-platform-release
    family = var.source_image_family  #default: common-cpu-notebooks-ubuntu-2004

  service_accounts {
    email = google_service_account.sa.email
  }

  shielded_instance_config {
    enable_secure_boot          = var.secure_boot #default: true
    enable_integrity_monitoring = true
    enable_vtpm                 = true
  }



  #install_gpu_driver = var.enable_gpu #default: false

  #install_gpu_driver = var.enable_gpu #default: false
boot_disk {
  disk_type      = var.boot_disk_type      #default: PD_SSD
  disk_size_gb   = var.boot_disk_size_gb   #default 150 GB
  }

  data_disks {
  disk_type      = var.data_disk_type      #default: PD_SSD
  disk_size_gb   = var.data_disk_size_gb   #default: 150 GB
 # no_remove_data_disk = var.no_remove_data_disk #default: false
#  disk_encryption     = var.disk_encryption     #default: GMEK
  }
  disable_public_ip    = var.no_public_ip    #default: true
  network_interfaces {
  network             = google_compute_network.vpc_network.id
  subnet              = google_compute_subnetwork.securevertex-subnet-a.id
  }
  //labels = merge(local.required_labels, var.labels)

  metadata = {
    notebook-disable-root      = "true"
    notebook-disable-downloads = "true"
    notebook-disable-nbconvert = "false"
    serial-port-enable         = "false"
    block-project-ssh-keys     = "true"
    proxy-mode                 = "service_account"
    notebook-upgrade-schedule  = var.update-schedule               #default: "0 7 * * SUN" = weekly Sunday morning 2am US Eastern
    gcs-data-bucket            = google_storage_bucket.bucket.name #enables jupyter notebook backups
    PROJ_ID                    = google_project.vertex-project.project_id
    DATASET                    = "dataset_${random_id.random_suffix.hex}"
    DATA_PROJ_ID               = "${data.google_project.data_project.project_id}"
    DATA_BUCKET                = "data-bucket-${random_id.random_suffix.hex}"
    PROXY_IP                   = "${google_network_services_gateway.default.addresses[0]}:443"
    post_startup_script = "gs://${google_storage_bucket.notebook_bucket.name}/${google_storage_bucket_object.notebook.name}"

  }
  }
  }
  depends_on = [
    google_storage_bucket.bucket,
    google_storage_bucket.notebook_bucket,
    time_sleep.wait_for_org_policy,
    google_service_account.sa,
    time_sleep.wait_for_swp,
  ]
}
*/

# Wait delay after notebook
resource "time_sleep" "wait_for_notebook" {
  depends_on      = [google_workbench_instance.vertex_workbench_instance]
  create_duration = "60s"
}




/*
resource "null_resource" "set_secure_boot" {
  count = var.enable_gpu ? 1 : 0
  triggers = {
    proj_id   = "${google_project.vertex-project.project_id}"
    vertex_id = "${google_notebooks_instance.vertex_workbench_instance.id}"
  }

  provisioner "local-exec" {
    command = <<EOF
    gcloud compute instances stop ${google_notebooks_instance.vertex_workbench_instance.name} --zone ${var.zone} --project ${google_project.vertex-project.project_id}
    sleep 120
    gcloud compute instances update ${google_notebooks_instance.vertex_workbench_instance.name} --shielded-secure-boot --zone ${var.zone} --project ${google_project.vertex-project.project_id}
    gcloud compute instances start ${google_notebooks_instance.vertex_workbench_instance.name} --zone ${var.zone} --project ${google_project.vertex-project.project_id}
    gcloud compute instances update ${google_notebooks_instance.vertex_workbench_instance.name} --shielded-learn-integrity-policy --zone ${var.zone} --project ${google_project.vertex-project.project_id}
    EOF
  }
  depends_on = [time_sleep.wait_for_notebook]
}

resource "null_resource" "set_secure_boot_instance_2" {
  count = var.enable_gpu ? 1 : 0
  triggers = {
    #    always_run = "${timestamp()}"
    proj_id   = "${google_project.vertex-project.project_id}"
    vertex_id = "${google_notebooks_instance.vertex_workbench_instance_2.id}"
  }

  provisioner "local-exec" {
    command = <<EOF
    gcloud compute instances stop ${google_notebooks_instance.vertex_workbench_instance_2.name} --zone ${var.zone} --project ${google_project.vertex-project.project_id}
    sleep 120
    gcloud compute instances update ${google_notebooks_instance.vertex_workbench_instance_2.name} --shielded-secure-boot --zone ${var.zone} --project ${google_project.vertex-project.project_id}
    gcloud compute instances start ${google_notebooks_instance.vertex_workbench_instance_2.name} --zone ${var.zone} --project ${google_project.vertex-project.project_id}
    gcloud compute instances update ${google_notebooks_instance.vertex_workbench_instance_2.name} --shielded-learn-integrity-policy --zone ${var.zone} --project ${google_project.vertex-project.project_id}
    EOF
  }
  depends_on = [time_sleep.wait_for_notebook]
}
*/