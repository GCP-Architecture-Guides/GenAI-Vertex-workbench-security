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

resource "google_project_iam_member" "notebook_bucket_iam" {
  # bucket = google_storage_bucket.bq_storage_bucket_name.name
  project = google_project.data_vertex-project.project_id

  role   = "roles/storage.admin"
  member = "serviceAccount:${var.notebook_srv_account}"

}


resource "google_project_iam_member" "bq_user" {
  #  bucket = google_storage_bucket.bq_storage_bucket_name.name
  project = google_project.data_vertex-project.project_id

  role   = "roles/bigquery.user"
  member = "serviceAccount:${var.notebook_srv_account}"

}


## BigQuery DataSet
#Creating  storage bucket
resource "google_storage_bucket" "bq_storage_bucket_name" {
  name                        = "data-bucket-${var.random_string}"
  location                    = var.region
  force_destroy               = true
  project                     = google_project.data_vertex-project.project_id
  uniform_bucket_level_access = true
  depends_on                  = [time_sleep.wait_enable_service_data]
}

# Add a sample file to the storage bucket
resource "google_storage_bucket_object" "clear_data_file" {
  name       = "clear-data"
  bucket     = google_storage_bucket.bq_storage_bucket_name.name
  source     = "data-project/sample_data/bq-test-data.csv"
  depends_on = [google_storage_bucket.bq_storage_bucket_name]
}



# Create dataset in bigquery
resource "google_bigquery_dataset" "clear_dataset" {
  dataset_id = "dataset_${var.random_string}"
  location   = var.region
  project    = google_project.data_vertex-project.project_id
  depends_on = [time_sleep.wait_enable_service_data]
  labels = {
    data_type = "test-sample-data"
  }
  description = "Sample sensitive data set"
}





# Create table in bigquery
resource "google_bigquery_table" "clear_table" {
  dataset_id          = google_bigquery_dataset.clear_dataset.dataset_id
  project             = google_project.data_vertex-project.project_id
  table_id            = "data-table"
  description         = "This table contain clear text sensitive data"
  deletion_protection = false
  depends_on          = [google_bigquery_dataset.clear_dataset]
}



# Import data in the BigQuery table 
resource "google_bigquery_job" "import_job_bq" {
  project  = google_project.data_vertex-project.project_id
  job_id   = "job_import_${var.random_string}"
  location = var.region

  labels = {
    "my_job" = "load"
  }

  load {
    source_uris = [
      "gs://${google_storage_bucket.bq_storage_bucket_name.name}/${google_storage_bucket_object.clear_data_file.name}",
    ]

    destination_table {
      project_id = google_bigquery_table.clear_table.project
      dataset_id = google_bigquery_table.clear_table.dataset_id
      table_id   = google_bigquery_table.clear_table.table_id
    }
    skip_leading_rows = 0
    autodetect        = true

  }
  depends_on = [google_storage_bucket_object.clear_data_file]
}