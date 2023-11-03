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




resource "null_resource" "create_certificate1" {
  triggers = {
    REGION           = "${var.region}"
    DOMAINNAME       = "${var.domainname}"
    CERTIFICATE_NAME = "${var.certificate_name}"
    KEY_NAME         = "${var.key_name}"
    PROJECT_ID       = "${google_project.vertex-project.project_id}"
  }

  provisioner "local-exec" {
    command = <<EOT

    export DOMAINNAME=${var.domainname}
    export CERTIFICATE_NAME=${var.certificate_name}
    export KEY_NAME=${var.key_name}

    openssl req -x509 -newkey rsa:2048 \
    -keyout $PWD/tmp_files/${self.triggers.KEY_NAME}.pem \
    -out $PWD/tmp_files/${self.triggers.CERTIFICATE_NAME}.pem -days 365 \
    -subj '/CN='${self.triggers.DOMAINNAME}'' -nodes -addext \
    "subjectAltName=DNS:${self.triggers.DOMAINNAME}"

    gcloud certificate-manager certificates create ${self.triggers.CERTIFICATE_NAME} --certificate-file="$PWD/tmp_files/${self.triggers.CERTIFICATE_NAME}.pem" \
    --private-key-file="$PWD/tmp_files/${self.triggers.KEY_NAME}.pem" --location=${self.triggers.REGION} --project=${self.triggers.PROJECT_ID}

    rm $PWD/tmp_files/*
    EOT
  }
  depends_on = [
    time_sleep.wait_for_org_policy,
    google_compute_subnetwork.secure_proxy_subnet,
    google_compute_subnetwork.securevertex-subnet-a,

  ]
}


resource "google_network_security_gateway_security_policy" "default" {
  name        = var.policy_name
  location    = var.region
  description = "my-gateway-security-policy"
  project     = google_project.vertex-project.project_id
  depends_on = [
    resource.null_resource.create_certificate1,
  ]
}



resource "google_network_security_url_lists" "default" {
  name        = "my-url-lists"
  project     = google_project.vertex-project.project_id
  location    = var.region
  description = "my description"
  values = [
    "github.com",
    "pypi.org",
    "pypi.python.org",
    "files.pythonhosted.org",
    "packaging.python.org",
    "cloud.r-project.org",
  ]
  depends_on = [
    google_network_security_gateway_security_policy.default,
  ]
}




resource "google_network_security_gateway_security_policy_rule" "default" {
  name                    = var.rule_name
  location                = var.region
  description             = "Allow external repositories"
  gateway_security_policy = google_network_security_gateway_security_policy.default.name
  enabled                 = true
  priority                = 1
  session_matcher         = "inUrlList(host(), 'projects/${google_project.vertex-project.project_id}/locations/${var.region}/urlLists/${google_network_security_url_lists.default.name}')"
  basic_profile           = "ALLOW"
  project                 = google_project.vertex-project.project_id
  depends_on = [
    google_network_security_url_lists.default,
  ]
}



resource "google_network_services_gateway" "default" {
  name                                 = var.gateway_name
  location                             = var.region
  project                              = google_project.vertex-project.project_id
  addresses                            = [var.swp_gateway_ip]
  type                                 = "SECURE_WEB_GATEWAY"
  ports                                = [443]
  scope                                = "samplescope"
  certificate_urls                     = ["projects/${google_project.vertex-project.project_id}/locations/${var.region}/certificates/${var.certificate_name}"]
  gateway_security_policy              = google_network_security_gateway_security_policy.default.id
  network                              = google_compute_network.vpc_network.id
  subnetwork                           = google_compute_subnetwork.securevertex-subnet-a.id
  delete_swg_autogen_router_on_destroy = true
  depends_on = [
    google_compute_subnetwork.secure_proxy_subnet,
    google_network_security_gateway_security_policy_rule.default,
  ]
}





resource "null_resource" "create_start_up_file" {
  triggers = {
#    always_run = "${timestamp()}"
    gateway_ip = "${google_network_services_gateway.default.addresses[0]}"
  }

  provisioner "local-exec" {
    command = <<EOT
    cat <<EOF >$PWD/assets/install_script.sh
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


##  This code creates demo environment for CSA Network Firewall microsegmentation 
##  This demo code is not built for production workload ##

#!/bin/bash
 
sudo apt-get update -y 
sudo echo http_proxy=https://${google_network_services_gateway.default.addresses[0]}:443/ >> /etc/environment
sudo echo https_proxy=https://${google_network_services_gateway.default.addresses[0]}:443/ >> /etc/environment
  echo "Current user: `id`" >> /tmp/notebook_config.log 2>&1
  echo "Changing dir to /home/jupyter" >> /tmp/notebook_config.log 2>&1
  export PATH="/home/jupyter/.local/bin:$PATH"
  cd /home/jupyter
  echo "Current user: `id`" >> /tmp/notebook_config.log 2>&1
  su - jupyter -c "git config --global http.proxy http://${google_network_services_gateway.default.addresses[0]}:443" >> /tmp/notebook_config.log 2>&1
  echo "Cloning generative-ai from github" >> /tmp/notebook_config.log 2>&1
  su - jupyter -c "export http_proxy='http://${google_network_services_gateway.default.addresses[0]}:443' && export https_proxy='http://${google_network_services_gateway.default.addresses[0]}:443'"
  su - jupyter -c "git clone https://github.com/GCP-Architecture-Guides/GenAI-vertex-security.git" >> /tmp/notebook_config.log 2>&1
  su - jupyter -c "mv GenAI-vertex-security/assets/*.ipynb /home/jupyter/" >> /tmp/notebook_config.log 2>&1
  su - jupyter -c "rm -r -f src" >> /tmp/notebook_config.log 2>&1
  su - jupyter -c "rm -r -f tutorials" >> /tmp/notebook_config.log 2>&1
  su - jupyter -c "rm -r -f GenAI-vertex-security" >> /tmp/notebook_config.log 2>&1
  echo "Installing python packages" >> /tmp/notebook_config.log 2&1
  su - jupyter -c "pip install --trusted-host pypi.org \
    --trusted-host pypi.python.org --trusted-host \
    files.pythonhosted.org pip setuptools" >> /tmp/notebook_config.log 2>&1
  su - jupyter -c "pip install --upgrade --no-warn-conflicts --no-warn-script-location --user \
      google-cloud-bigquery \
      google-cloud-pipeline-components \
      google-cloud-aiplatform \
      seaborn \
      kfp --proxy http://${google_network_services_gateway.default.addresses[0]}:443" >> /tmp/notebook_config.log 2>&1

EOF
EOT
  }

  depends_on = [
    google_network_services_gateway.default,

  ]
}



# Wait delay after notebook
resource "time_sleep" "wait_for_swp" {
  depends_on      = [resource.null_resource.create_start_up_file]
  create_duration = "45s"
}

