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


output "_1_ssh_workstation_command" {
  description = "The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value."
  value       = "gcloud compute ssh --zone ${var.zone} ${var.workbench_name} --tunnel-through-iap --project ${google_project.vertex-project.project_id}"
}


output "_2_failing_curl" {
  description = "The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value."
  value       = "curl https://google.com --proxy-insecure"
}


output "_3_success_curl" {
  description = "The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value."
  value       = "curl https://github.com/GoogleCloudPlatform/terraform-google-cloud-ids --proxy-insecure"
}


output "_4_notebook_url_access" {
  description = "The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value."
  value       = "https://${google_notebooks_instance.vertex_workbench_instance.proxy_uri}"
}


output "_5_notebook_terminal_set_proxy" {
  description = "The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value."
  value       = "export http_proxy='http://${google_network_services_gateway.default.addresses[0]}:443' && export https_proxy='http://${google_network_services_gateway.default.addresses[0]}:443'"
}


output "_6_notebook_proxy_test" {
  description = "The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value."
  value       = "import requests; proxies = {'https': '${google_network_services_gateway.default.addresses[0]}:443'}; r = requests.get('https://github.com/GoogleCloudPlatform/terraform-google-cloud-ids', proxies=proxies); print(f'Status Code: {r.status_code}')"
}


output "_7_notebook_proxy_test" {
  description = "The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value."
  value       = "! pip3 install --upgrade google-cloud-aiplatform --proxy http://${google_network_services_gateway.default.addresses[0]}:443"
}

/*
output "_8_gateway_ip" {
  description = "The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value."
  value       = google_network_services_gateway.default.addresses[0]
}
*/