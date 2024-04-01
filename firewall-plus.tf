

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

/*
# allow ingress through TF
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
src_ip_ranges = [var.subnet_ip_cidr]
  dest_ip_ranges = [var.subnet_ip_cidr]

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
*/


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

/* # To allow private access for tagged account


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

  metadata_startup_script = file("${path.module}/assets/securevertex-www.sh")
  metadata = {
    SWP_IP = "${google_network_services_gateway.default.addresses[0]}"

  }
  labels = {
    asset_type = "server-machine"
  }

  depends_on = [
    google_compute_network.vpc_network,
    google_compute_subnetwork.securevertex-subnet-a,
    time_sleep.wait_for_swp,
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

  metadata_startup_script = file("${path.module}/assets/securevertex-client.sh")
  metadata = {
  SWP_IP = "${google_network_services_gateway.default.addresses[0]}"
  TARGET_PRIVATE_IP = "${google_compute_instance.securevertex_www[count.index].network_interface.0.network_ip}"
  }
  labels = {
    asset_type = "server-machine"
  }

  depends_on = [
    google_compute_network.vpc_network,
    google_compute_subnetwork.securevertex-subnet-a,
    time_sleep.wait_for_swp,
    google_compute_instance.securevertex_www,
  ]
}



########################### Compute Instance Tagging #############

resource "google_tags_location_tag_binding" "binding_www" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
    parent    = "//compute.googleapis.com/projects/${google_project.vertex-project.number}/zones/${var.zone}/instances/${google_compute_instance.securevertex_www[count.index].instance_id}"
    tag_value = "tagValues/${google_tags_tag_value.server_value[count.index].name}"
 location = var.zone
    depends_on = [
      google_tags_tag_value.server_value,
      google_compute_instance.securevertex_www,
    ]

}

resource "google_tags_location_tag_binding" "binding_client" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
    parent    = "//compute.googleapis.com/projects/${google_project.vertex-project.number}/zones/${var.zone}/instances/${google_compute_instance.securevertex_client[count.index].instance_id}"
    tag_value = "tagValues/${google_tags_tag_value.client_value[count.index].name}"
  location = var.zone
    depends_on = [
      google_tags_tag_value.client_value,
      google_compute_instance.securevertex_client,
    ]
}


########################### Cloud Firewall Plus Endpoint creation #############

resource "null_resource" "fwp_endpoint_profile" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  triggers = {
    zone = "${var.zone}"
    org_id = "${var.organization_id}"
    network_name = "${var.network_name}"
    proj_id = "${google_project.vertex-project.project_id}"
    random_id = "${random_id.random_suffix.hex}"
    
  }

  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security security-profiles threat-prevention create securevertex-sp-threat-${self.triggers.random_id} --organization ${self.triggers.org_id} --location=global --quiet --no-async
gcloud config unset project
  EOT
  }

   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security security-profiles threat-prevention delete securevertex-sp-threat-${self.triggers.random_id} --organization ${self.triggers.org_id} --location=global --quiet --no-async
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
    random_id = "${random_id.random_suffix.hex}"

  }

  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security security-profile-groups create securevertex-spg-${self.triggers.random_id} --organization ${self.triggers.org_id} --location=global --threat-prevention-profile organizations/${self.triggers.org_id}/locations/global/securityProfiles/securevertex-sp-threat-${self.triggers.random_id}  --quiet --no-async
gcloud config unset project
  EOT
  }


   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud alpha network-security security-profile-groups delete securevertex-spg-${self.triggers.random_id} --organization ${self.triggers.org_id} --location=global  --quiet --no-async
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
        random_id = "${random_id.random_suffix.hex}"

  }

  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud network-security firewall-endpoints create securevertex-${self.triggers.zone}-${self.triggers.random_id} --zone=${self.triggers.zone} --organization ${self.triggers.org_id} --billing-project=${self.triggers.proj_id} --quiet --no-async
gcloud config unset project
  EOT
  }

   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud network-security firewall-endpoints delete securevertex-${self.triggers.zone}-${self.triggers.random_id} --zone=${self.triggers.zone} --organization ${self.triggers.org_id}  --quiet --no-async
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
        random_id = "${random_id.random_suffix.hex}"

  }


  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud network-security firewall-endpoint-associations create securevertex-association-${self.triggers.random_id} --zone ${self.triggers.zone} --network=${self.triggers.network_name} --endpoint securevertex-${self.triggers.zone}-${self.triggers.random_id} --organization ${self.triggers.org_id} --quiet --no-async
gcloud config unset project
  EOT
  }

   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud  network-security firewall-endpoint-associations delete securevertex-association-${self.triggers.random_id} --zone ${self.triggers.zone}  --quiet --no-async
gcloud config unset project
  EOT
  }
 depends_on              = [resource.null_resource.fwp_endpoint_endpoint]

}

## Create the FW ruke and update to apply FW+ L7 rule

resource "null_resource" "fwp_rule_update_apply_l7" {
  count      = var.firewall_ips_enabled == false ? 0 : 1
  triggers = {
    zone = "${var.zone}"
    org_id = "${var.organization_id}"
    network_name = "${var.network_name}"
    proj_id = "${google_project.vertex-project.project_id}"
    firewall_policy = "${google_compute_network_firewall_policy.primary.name}"
        random_id = "${random_id.random_suffix.hex}"
        ip_cidr = "${var.subnet_ip_cidr}"

  }

  provisioner "local-exec" {
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud compute network-firewall-policies rules create 500 --description "allow ingress internal traffic from tagged clients" \
	--action=allow \
	--firewall-policy=secure-notebook-policy \
	--global-firewall-policy \
	--direction=INGRESS \
	--enable-logging \
	--layer4-configs all \
	--src-ip-ranges=${self.triggers.ip_cidr} \
	--dest-ip-ranges=${self.triggers.ip_cidr} \
  --target-secure-tags ${self.triggers.proj_id}/securevertex-vpc-tags/securevertex-vpc-client,${self.triggers.proj_id}/securevertex-vpc-tags/securevertex-vpc-server

gcloud beta compute network-firewall-policies rules update 500 --action=apply_security_profile_group --firewall-policy=${self.triggers.firewall_policy} --global-firewall-policy --security-profile-group=//networksecurity.googleapis.com/organizations/${self.triggers.org_id}/locations/global/securityProfileGroups/securevertex-spg-${self.triggers.random_id} --enable-logging
gcloud config unset project
  EOT
  }

   provisioner "local-exec" {
    when = destroy
    command = <<EOT
gcloud config set project ${self.triggers.proj_id}
gcloud compute network-firewall-policies rules delete 500 \
  --firewall-policy=secure-notebook-policy \
	--global-firewall-policy
gcloud config unset project
  EOT
  }

 depends_on              = [
  resource.null_resource.fwp_endpoint_endpoint,
 resource.null_resource.fwp_endpoint_association,
 ]

}
