

########################### IAM Tags#############

resource "google_tags_tag_key" "key" {
      count      = var.firewall_ips_enabled == false ? 0 : 1
  parent     = "projects/${google_project.vertex-project.project_id}"
  short_name = "securevertex-vpc-tags"

  description = "For use with network firewall rule for firewall plus."
  purpose     = "GCE_FIREWALL"
  purpose_data = {
    network = "${google_project.vertex-project.project_id}/${var.network_name}"
  }
  depends_on              = [
    time_sleep.wait_for_org_policy,
  google_compute_subnetwork.securevertex-subnet-a,
  ]
}

resource "google_tags_tag_value" "client_value" {
        count      = var.firewall_ips_enabled == false ? 0 : 1
  parent      = "tagKeys/${google_tags_tag_key.key[count.index].name}"
  short_name  = "securevertex-vpc-client"
  description = "Tag for vpc client."
  depends_on = [
    google_tags_tag_key.key,
  ]
}

resource "google_tags_tag_value" "server_value" {
        count      = var.firewall_ips_enabled == false ? 0 : 1
  parent      = "tagKeys/${google_tags_tag_key.key[count.index].name}"
  short_name  = "securevertex-vpc-server"
  description = "Tag for vpc server."
  depends_on = [
    google_tags_tag_key.key,
  ]
}




########################### Firewall rules #############


# Allow access from Internal Load Balancer
resource "google_compute_network_firewall_policy_rule" "allow_system_updates" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  project         = "${google_project.vertex-project.project_id}"
  action          = "allow"
  description     = "allow system updates"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 400
  rule_name       = "fwp-allow-system-updates"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]


  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.client_value[count.index].name}"
  }



  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.server_value[count.index].name}"
  }

  match {
    #dest_ip_ranges = [""]
dest_fqdns = ["ftp.us.debian.org", "deb.debian.org", "packages.cloud.google.com"]
    layer4_configs {
      ip_protocol = "all"
    #  ports       = [80]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_tags_tag_value.client_value,
    google_tags_tag_value.server_value,
  ]
}


# allow ingress
resource "google_compute_network_firewall_policy_rule" "fwp_allow_ingress" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  project         = "${google_project.vertex-project.project_id}"
  action          = "allow"
  description     = "allow ingress internal traffic from tagged clients"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 500
  rule_name       = "fwp-allow-ingress"
  #  targetSecureTag   = true
  #  target_service_accounts = ["emailAddress:my@service-account.com"]
  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.client_value[count.index].name}"
  }



  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.server_value[count.index].name}"
  }

  match {
src_ip_ranges = ["10.10.10.0/24"]
  dest_ip_ranges = ["10.10.10.0/24"]

    layer4_configs {
      ip_protocol = "all"
    #  ports       = [80]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_tags_tag_value.client_value,
    google_tags_tag_value.server_value,
    google_compute_subnetwork.securevertex-subnet-a,
    
  ]
}


# allow egress internal traffic from tagged clients
resource "google_compute_network_firewall_policy_rule" "allow_egress_tagged" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  project         = "${google_project.vertex-project.project_id}"
  action          = "allow"
  description     = "allow egress internal traffic from tagged clients"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 600
  rule_name       = "fwp-allow-egress"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]


  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.client_value[count.index].name}"
  }



  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.server_value[count.index].name}"
  }

  match {
        src_ip_ranges = ["${google_compute_subnetwork.securevertex-subnet-a.ip_cidr_range}"]
dest_ip_ranges = ["${google_compute_subnetwork.securevertex-subnet-a.ip_cidr_range}"]

    layer4_configs {
      ip_protocol = "all"
    #  ports       = [80]
    }
  }
 depends_on = [
    google_compute_network_firewall_policy.primary,
    google_tags_tag_value.client_value,
    google_tags_tag_value.server_value,
    google_compute_subnetwork.securevertex-subnet-a,
    google_network_services_gateway.default,
    
  ]
}

/*

# Network Firewall rule for your instances to download packages private access 
resource "google_compute_network_firewall_policy_rule" "fwp_allow_private_access" {
    count      = var.firewall_ips_enabled == false ? 0 : 1
  project                 = google_project.vertex-project.project_id
  action                  = "allow"
  description             = "FWP Rule to allow access to Private Google APIs"
  direction               = "EGRESS"
  disabled                = false
  enable_logging          = true
  firewall_policy         = google_compute_network_firewall_policy.primary.name
  priority                = 700
  rule_name               = "fwp-allow-private-access"
 # target_service_accounts = ["${google_service_account.sa.email}"]
 target_secure_tags {
    name = "tagValues/${google_tags_tag_value.client_value[count.index].name}"
  }



  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.server_value[count.index].name}"
  }
  match {
    dest_ip_ranges = ["199.36.153.8/30"]

    layer4_configs {
      ip_protocol = "all"
      #      ports       = [443]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}


# Network Firewall rule for your instances to download packages private access 
resource "google_compute_network_firewall_policy_rule" "fwp_allow_restricted_access" {
    count      = var.firewall_ips_enabled == false ? 0 : 1
  project                 = google_project.vertex-project.project_id
  action                  = "allow"
  description             = "FWP Rule to allow access to Restricted Google APIs"
  direction               = "EGRESS"
  disabled                = false
  enable_logging          = true
  firewall_policy         = google_compute_network_firewall_policy.primary.name
  priority                = 800
  rule_name               = "fwp-allow-restricted-access"
 # target_service_accounts = ["${google_service_account.sa.email}"]
 target_secure_tags {
    name = "tagValues/${google_tags_tag_value.client_value[count.index].name}"
  }



  target_secure_tags {
    name = "tagValues/${google_tags_tag_value.server_value[count.index].name}"
  }
  match {
    dest_ip_ranges = ["199.36.153.4/30"]

    layer4_configs {
      ip_protocol = "all"
      #      ports       = [443]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
        google_tags_tag_value.client_value,
    google_tags_tag_value.server_value,
  ]
}
*/


########################### Secure Web Proxy #############

resource "google_network_security_url_lists" "fwp_url_list" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  name        = "fwplus-url-list"
  project     = "${google_project.vertex-project.project_id}"
  location    = var.region
  description = "fwplus-url-list"
  values = [
    "deb.debian.org",
    "ftp.us.debian.org",
    "pypi.python.org",
    "packages.cloud.google.com",
  ]
  depends_on = [
    google_network_security_gateway_security_policy.default,
        google_tags_tag_value.client_value,
    google_tags_tag_value.server_value,
  ]
}





resource "google_network_security_gateway_security_policy_rule" "fwp_system_updates" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  name                    = "fwplus-system-updates"
  location                = var.region
  description             = "fwplus-system-updates"
  gateway_security_policy = google_network_security_gateway_security_policy.default.name
  enabled                 = true
  priority                = 2
  session_matcher         = "inUrlList(host(), 'projects/${google_project.vertex-project.project_id}/locations/${var.region}/urlLists/${google_network_security_url_lists.fwp_url_list[count.index].name}')"
  basic_profile           = "ALLOW"
  project                 = google_project.vertex-project.project_id
  depends_on = [
    google_network_security_url_lists.fwp_url_list,
  ]
}



########################### Compute Instance #############

#script export to file

/*
resource "null_resource" "securevertex_startup" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  triggers = {
    REGION           = "${var.region}"
    DOMAINNAME       = "${var.domainname}"
    CERTIFICATE_NAME = "${var.certificate_name}"
    KEY_NAME         = "${var.key_name}"
    PROJECT_ID       = "${google_project.vertex-project.project_id}"
  }

  provisioner "local-exec" {
    command = <<EOT
cat <<EOF >$PWD/tmp_files/securevertex-www.sh
#! /bin/bash
sleep 180
    TARGET_IP=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/TARGET_IP" -H "Metadata-Flavor: Google")
sudo echo http_proxy=https://${google_network_services_gateway.default.addresses[0]}:443/ >> /etc/environment
sudo echo https_proxy=https://${google_network_services_gateway.default.addresses[0]}:443/ >> /etc/environment
sudo touch /etc/apt/apt.conf.d/proxy.conf
sudo echo 'Acquire::https::Proxy "https://${google_network_services_gateway.default.addresses[0]}:443/";' | sudo tee /etc/apt/apt.conf.d/proxy.conf
sudo touch /etc/apt/apt.conf.d/99verify-peer.conf
echo "Acquire { https::Verify-Peer false }" | sudo tee /etc/apt/apt.conf.d/99verify-peer.conf
sudo apt-get update
sudo apt-get install apache2 tcpdump iperf3 -y
sudo a2ensite default-ssl
sudo a2enmod ssl
echo "Page served from securevertex webserver" | sudo tee /var/www/html/index.html
sudo systemctl restart apache2


EOF



cat <<EOF >$PWD/tmp_files/securevertex-client.sh
#! /bin/bash
sleep 180
    TARGET_IP=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/TARGET_IP" -H "Metadata-Flavor: Google")
sudo echo http_proxy=https://${google_network_services_gateway.default.addresses[0]}:443/ >> /etc/environment
sudo echo https_proxy=https://${google_network_services_gateway.default.addresses[0]}:443/ >> /etc/environment
sudo touch /etc/apt/apt.conf.d/proxy.conf
sudo echo 'Acquire::https::Proxy "https://${google_network_services_gateway.default.addresses[0]}:443/";' | sudo tee /etc/apt/apt.conf.d/proxy.conf
echo 'Acquire::http::Proxy "http://${google_network_services_gateway.default.addresses[0]}:443/";' | sudo tee /etc/apt/apt.conf.d/proxy.conf
sudo touch /etc/apt/apt.conf.d/99verify-peer.conf
echo "Acquire { https::Verify-Peer false }" | sudo tee /etc/apt/apt.conf.d/99verify-peer.conf
sudo apt-get update
sudo apt-get install apache2 tcpdump iperf3 -y

EOF

    EOT
  }
  depends_on = [
    google_network_services_gateway.default,
    time_sleep.wait_for_swp,
  ]
}
*/

# Create Server Instance
resource "google_compute_instance" "securevertex_www" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  project      = "${google_project.vertex-project.project_id}"
  name         = "securevertex-${var.zone}-www"
  machine_type = "f1-micro"
  zone         = var.zone
  shielded_instance_config {
    enable_secure_boot = true
  }
  

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.securevertex-subnet-a.self_link
  }

  #service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
  #  email  = data.google_compute_default_service_account.default.email
  #  scopes = ["cloud-platform"]
  #}

  metadata_startup_script = file("${path.module}/assets/securevertex-www.sh")
  metadata = {
    SWP_IP = "${google_network_services_gateway.default.addresses[0]}"

  }
  labels = {
    asset_type = "server-machine"
  }

  depends_on = [
   # resource.null_resource.securevertex_startup,
    google_compute_network.vpc_network,
    google_compute_subnetwork.securevertex-subnet-a,
    time_sleep.wait_for_swp,
#   google_compute_packet_mirroring.cloud_ids_packet_mirroring,
  ]
}





# Create Server Instance
resource "google_compute_instance" "securevertex_client" {
count      = var.firewall_ips_enabled == false ? 0 : 1
  project      = "${google_project.vertex-project.project_id}"
  name         = "securevertex-${var.zone}-client"
  machine_type = "f1-micro"
  zone         = var.zone
  shielded_instance_config {
    enable_secure_boot = true
  }
  

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.securevertex-subnet-a.self_link
  }

  #service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
  #  email  = data.google_compute_default_service_account.default.email
  #  scopes = ["cloud-platform"]
  #}

  metadata_startup_script = file("${path.module}/assets/securevertex-client.sh")
  metadata = {
  SWP_IP = "${google_network_services_gateway.default.addresses[0]}"
  TARGET_PRIVATE_IP = "${google_compute_instance.securevertex_www[count.index].network_interface.0.network_ip}"
  }
  labels = {
    asset_type = "server-machine"
  }

  depends_on = [
  #  resource.null_resource.securevertex_startup,
    google_compute_network.vpc_network,
    google_compute_subnetwork.securevertex-subnet-a,
    time_sleep.wait_for_swp,
    google_compute_instance.securevertex_www,
  ]
}



########################### Compute Instance Tagging #############


resource "google_tags_location_tag_binding" "binding_www" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
 #   parent = "//compute.googleapis.com/${google_compute_instance.securevertex_www[count.index].id}"
    parent    = "//compute.googleapis.com/projects/${google_project.vertex-project.project_id}/zones/${var.zone}/instances/${google_compute_instance.securevertex_www[count.index].instance_id}"

    tag_value = "tagValues/${google_tags_tag_value.server_value[count.index].name}"
 location = var.zone
    depends_on = [
      google_tags_tag_value.server_value,
      google_compute_instance.securevertex_www,
    ]

}

resource "google_tags_location_tag_binding" "binding_client" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  #  parent = "//compute.googleapis.com/${google_compute_instance.securevertex_client[count.index].id}"
    parent    = "//compute.googleapis.com/projects/${google_project.vertex-project.project_id}/zones/${var.zone}/instances/${google_compute_instance.securevertex_client[count.index].instance_id}"

    tag_value = "tagValues/${google_tags_tag_value.client_value[count.index].name}"
  location = var.zone
    depends_on = [
      google_tags_tag_value.client_value,
      google_compute_instance.securevertex_client,
    ]
}


/*
# Got to create new null resource for tags
resource "null_resource" "fwp_iam_tagging" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  triggers = {
  #  REGION           = "${var.region}"
  #  DOMAINNAME       = "${var.domainname}"
  #  CERTIFICATE_NAME = "${var.certificate_name}"
  #  KEY_NAME         = "${var.key_name}"
  #  PROJECT_ID       = "${google_project.vertex-project.project_id}"
    instance_server = "${google_compute_instance.securevertex_www[count.index].id}"
    instance_client = "${google_compute_instance.securevertex_client[count.index].id}"
    tag_server = "${google_tags_tag_value.server_value[count.index].namespaced_name}"
    tag_client = "${google_tags_tag_value.client_value[count.index].namespaced_name}"
    zone = "${var.zone}"
  }

  provisioner "local-exec" {
    command = <<EOT
  gcloud resource-manager tags bindings create \
  --location ${var.zone} \
  --tag-value $project_id/${google_tags_tag_value.server_value[count.index].namespaced_name} \
  --parent //compute.googleapis.com/projects/${google_compute_instance.securevertex_www[count.index].id}

  gcloud resource-manager tags bindings create \
  --location ${var.zone} \
  --tag-value ${google_tags_tag_value.client_value[count.index].namespaced_name} \
  --parent //compute.googleapis.com/${google_compute_instance.securevertex_client[count.index].id}
  EOT
  }


   provisioner "local-exec" {
    when = destroy
    command = <<EOT
  gcloud resource-manager tags bindings delete \
  --location ${self.triggers.zone} \
  --tag-value $project_id/${self.triggers.tag_server} \
  --parent //compute.googleapis.com/projects/${self.triggers.instance_server}

  gcloud resource-manager tags bindings delete \
  --location ${self.triggers.zone} \
  --tag-value ${self.triggers.tag_client} \
  --parent //compute.googleapis.com/${self.triggers.instance_client}
  EOT
  }
  #   --location ${self.triggers.zone} \
  depends_on = [
    google_compute_instance.securevertex_www,
    google_compute_instance.securevertex_client,
    google_tags_tag_value.server_value,
    google_tags_tag_value.client_value,
  ]
}
*/



########################### Cloud Firewall Plus Endpoint creation #############


resource "null_resource" "fwp_endpoint_profile" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  triggers = {
    zone = "${var.zone}"
    org_id = "${var.organization_id}"
    network_name = "${var.network_name}"
    proj_id = "${google_project.vertex-project.project_id}"
  }

  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security security-profiles threat-prevention create securevertex-sp-threat --organization ${self.triggers.org_id} --location=global
gcloud config unset project
  EOT
  }

   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security security-profiles threat-prevention delete securevertex-sp-threat --organization ${self.triggers.org_id} --location=global
gcloud config unset project
  EOT
  }

 depends_on              = [time_sleep.wait_for_org_policy,
 google_compute_network.vpc_network,
  ]
}


resource "null_resource" "fwp_endpoint_group" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  triggers = {
    zone = "${var.zone}"
    org_id = "${var.organization_id}"
    network_name = "${var.network_name}"
    proj_id = "${google_project.vertex-project.project_id}"

  }

  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security security-profile-groups create securevertex-spg --organization ${self.triggers.org_id} --location=global --threat-prevention-profile organizations/${self.triggers.org_id}/locations/global/securityProfiles/securevertex-sp-threat
gcloud config unset project
  EOT
  }

   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security security-profile-groups delete securevertex-spg --organization ${self.triggers.org_id} --location=global --threat-prevention-profile organizations/${self.triggers.org_id}/locations/global/securityProfiles/securevertex-sp-threat
gcloud config unset project
  EOT
  }

 depends_on              = [resource.null_resource.fwp_endpoint_profile]
}


resource "null_resource" "fwp_endpoint_endpoint" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  triggers = {
    zone = "${var.zone}"
    org_id = "${var.organization_id}"
    network_name = "${var.network_name}"
    proj_id = "${google_project.vertex-project.project_id}"
  }

  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security firewall-endpoints create securevertex-${self.triggers.zone} --zone=${self.triggers.zone} --organization ${self.triggers.org_id} --no-async
gcloud config unset project
  EOT
  }

   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security firewall-endpoints delete securevertex-${self.triggers.zone} --zone=${self.triggers.zone} --organization ${self.triggers.org_id}
gcloud config unset project
  EOT
  }

 depends_on              = [resource.null_resource.fwp_endpoint_group]
}



resource "null_resource" "fwp_endpoint_association" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  triggers = {
    zone = "${var.zone}"
    org_id = "${var.organization_id}"
    network_name = "${var.network_name}"
    proj_id = "${google_project.vertex-project.project_id}"
  }

  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security firewall-endpoint-associations create securevertex-association --zone ${self.triggers.zone} --network=${self.triggers.network_name} --endpoint securevertex-${self.triggers.zone} --organization ${self.triggers.org_id}
gcloud config unset project
  EOT
  }

   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security firewall-endpoint-associations delete securevertex-association --zone ${self.triggers.zone} --network=${self.triggers.network_name} --endpoint securevertex-${self.triggers.zone} --organization ${self.triggers.org_id}
gcloud config unset project
  EOT
  }

 depends_on              = [resource.null_resource.fwp_endpoint_endpoint]

}

## Update to apply FW+ L7 rule
/*
gcloud beta compute network-firewall-policies rules update 500 \
	--action=apply_security_profile_group \
	--firewall-policy=secure-notebook-policy \
	--global-firewall-policy \
--security-profile-group=//networksecurity.googleapis.com/organizations/$org_id/locations/global/securityProfileGroups/$prefix-spg
*/


resource "null_resource" "fwp_rule_update_apply_l7" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  triggers = {
    zone = "${var.zone}"
    org_id = "${var.organization_id}"
    network_name = "${var.network_name}"
    proj_id = "${google_project.vertex-project.project_id}"
    firewall_policy = "${google_compute_network_firewall_policy.primary.name}"
    rule_name = "${google_compute_network_firewall_policy_rule.fwp_allow_ingress[count.index].rule_name}"
  }

  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud beta compute network-firewall-policies rules update 500 --action=apply_security_profile_group --firewall-policy=${self.triggers.firewall_policy} --global-firewall-policy --security-profile-group=//networksecurity.googleapis.com/organizations/${self.triggers.org_id}/locations/global/securityProfileGroups/securevertex-spg
gcloud config unset project
  EOT
  }

   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud compute network-firewall-policies rules update 500 --description "allow ingress internal traffic from tagged clients" \
	--action=allow \
	--firewall-policy=secure-notebook-policy \
	--global-firewall-policy \
	--direction=INGRESS \
	--enable-logging \
	--layer4-configs all \
	--src-ip-ranges=10.10.10.0/24 \
	--dest-ip-ranges=10.10.10.0/24 \
  --target-secure-tags ${self.triggers.proj_id}/securevertex-vpc-tags/securevertex-vpc-client,${self.triggers.proj_id}/securevertex-vpc-tags/securevertex-vpc-server
gcloud config unset project
  EOT
  }

 depends_on              = [
  resource.null_resource.fwp_endpoint_endpoint,
 google_compute_network_firewall_policy_rule.fwp_allow_ingress,
 resource.null_resource.fwp_endpoint_association,
 ]

}
