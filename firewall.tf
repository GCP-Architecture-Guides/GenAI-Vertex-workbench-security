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



# Enable SSH through IAP
resource "google_compute_firewall" "allow_iap_proxy" {
  name      = "allow-iap-proxy"
  network   = google_compute_network.vpc_network.self_link
  project   = google_project.vertex-project.project_id
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
  priority      = 1000
  source_ranges = ["35.235.240.0/20"]
  depends_on = [
    google_compute_subnetwork.securevertex-subnet-a,
  ]
}

/*
resource "google_compute_firewall" "deny_egress_ip4" {
  name      = "deny-egress-ip4"
  network   = google_compute_network.vpc_network.self_link
  project   = google_project.vertex-project.project_id
  direction = "EGRESS"
  deny {
    protocol = "all"
  }
  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
  destination_ranges = ["0.0.0.0/0"]
  priority = 1000
  depends_on = [
    google_compute_subnetwork.securevertex-subnet-a,
  ]
}


resource "google_compute_firewall" "deny_egress_ip_6" {
  name      = "deny-egress-ip6"
  network   = google_compute_network.vpc_network.self_link
  project   = google_project.vertex-project.project_id
  direction = "EGRESS"
  deny {
    protocol = "all"
  }
  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
  destination_ranges = ["::/0"]
  priority = 1000
  depends_on = [
    google_compute_subnetwork.securevertex-subnet-a,
  ]
}
*/

resource "google_compute_network_firewall_policy" "primary" {
  name = "secure-notebook-policy"

  description = "Global network firewall policy for secure notebook"
  project     = google_project.vertex-project.project_id

  depends_on = [
    google_compute_network.vpc_network,
  ]
}

resource "google_compute_network_firewall_policy_association" "primary" {
  name              = "association"
  attachment_target = google_compute_network.vpc_network.id
  firewall_policy   = google_compute_network_firewall_policy.primary.name
  project           = google_project.vertex-project.project_id
  depends_on = [
    google_compute_network_firewall_policy.primary,
  ]
}



# Deny ingress trafic
resource "google_compute_network_firewall_policy_rule" "deny_ingress_ipv4_threat" {
  project         = google_project.vertex-project.project_id
  action          = "deny"
  description     = "deny-ingress-ipv4-threat-intel"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 1000000000
  rule_name       = "deny-ingress-ipv4-threat"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    src_threat_intelligences = ["iplist-tor-exit-nodes", "iplist-known-malicious-ips", "iplist-crypto-miners"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}


# Deny ingress trafic
resource "google_compute_network_firewall_policy_rule" "deny_egress_ipv4_threat" {
  project         = google_project.vertex-project.project_id
  action          = "deny"
  description     = "deny-egress-ipv4-threat-intel"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 1000000001
  rule_name       = "deny-egress-ipv4-threat"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    dest_threat_intelligences = ["iplist-tor-exit-nodes", "iplist-known-malicious-ips", "iplist-crypto-miners"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}


################################################
# Deny ingress trafic
resource "google_compute_network_firewall_policy_rule" "deny_egress_ipv4_sanctioned_location" {
  project         = google_project.vertex-project.project_id
  action          = "deny"
  description     = "deny-egress-ipv4-sanctioned-location"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 1000000002
  rule_name       = "deny-egress-ipv4-threat"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    dest_region_codes = ["CU", "IR", "SY", "XC", "XD", "KP"]
    layer4_configs {
      ip_protocol = "all"
    }
  }

  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}



# Network Firewall rule for your instances to download packages private access 
resource "google_compute_network_firewall_policy_rule" "allow_access_proxy" {
  project                 = google_project.vertex-project.project_id
  action                  = "allow"
  description             = "Rule to allow access Secure Proxy"
  direction               = "EGRESS"
  disabled                = false
  enable_logging          = true
  firewall_policy         = google_compute_network_firewall_policy.primary.name
  priority                = 1000000
  rule_name               = "allow-private-access"
  target_service_accounts = ["${google_service_account.sa.email}"]

  match {
    dest_ip_ranges = ["${google_network_services_gateway.default.addresses[0]}"]

    layer4_configs {
      ip_protocol = "tcp"
      #      ports       = [443]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}



# Network Firewall rule for your instances to download packages private access 
resource "google_compute_network_firewall_policy_rule" "allow_private_access" {
  project                 = google_project.vertex-project.project_id
  action                  = "allow"
  description             = "Rule to allow access to Private Google APIs"
  direction               = "EGRESS"
  disabled                = false
  enable_logging          = true
  firewall_policy         = google_compute_network_firewall_policy.primary.name
  priority                = 2000000
  rule_name               = "allow-private-access"
  target_service_accounts = ["${google_service_account.sa.email}"]

  match {
    dest_ip_ranges = ["199.36.153.8/30"]

    layer4_configs {
      ip_protocol = "tcp"
      #      ports       = [443]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}


# Network Firewall rule for your instances to download packages private access 
resource "google_compute_network_firewall_policy_rule" "allow_restricted_access" {
  project                 = google_project.vertex-project.project_id
  action                  = "allow"
  description             = "Rule to allow access to Restricted Google APIs"
  direction               = "EGRESS"
  disabled                = false
  enable_logging          = true
  firewall_policy         = google_compute_network_firewall_policy.primary.name
  priority                = 2000010
  rule_name               = "allow-restricted-access"
  target_service_accounts = ["${google_service_account.sa.email}"]

  match {
    dest_ip_ranges = ["199.36.153.4/30"]

    layer4_configs {
      ip_protocol = "tcp"
      #      ports       = [443]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}


resource "google_compute_network_firewall_policy_rule" "allow_restricted_access_php" {
  project                 = google_project.vertex-project.project_id
  action                  = "allow"
  description             = "Allow access to install PHP Google Client Libraries"
  direction               = "EGRESS"
  disabled                = false
  enable_logging          = true
  firewall_policy         = google_compute_network_firewall_policy.primary.name
  priority                = 2000100
  rule_name               = "allow-restricted-access-php"
  target_service_accounts = ["${google_service_account.sa.email}"]

  match {
    dest_fqdns = ["github.com", "pypi.org", "pypi.python.org", "files.pythonhosted.org", "packaging.python.org", "cloud.r-project.org"]

    layer4_configs {
      ip_protocol = "tcp"
      #      ports       = [443]
    }
  }
  depends_on = [
    google_compute_network_firewall_policy.primary,
    google_compute_network_firewall_policy_association.primary,
  ]
}

# Deny ingress trafic
resource "google_compute_network_firewall_policy_rule" "deny_ingress_ipv4" {
  project         = google_project.vertex-project.project_id
  action          = "deny"
  description     = "deny-ingress-ipv4"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 2000000000
  rule_name       = "deny-ingress-ipv4"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    src_ip_ranges = ["0.0.0.0/0"]

    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}


# Deny ingress trafic
resource "google_compute_network_firewall_policy_rule" "deny_ingress_ipv6" {
  project         = google_project.vertex-project.project_id
  action          = "deny"
  description     = "deny-ingress-ipv6"
  direction       = "INGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 2000000001
  rule_name       = "deny-ingress-ipv6"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    src_ip_ranges = ["0::0/0"]

    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}



# Deny egress trafic
resource "google_compute_network_firewall_policy_rule" "deny_egress_ipv4" {
  project         = google_project.vertex-project.project_id
  action          = "deny"
  description     = "deny-ingress-ipv4"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 2000000010
  rule_name       = "deny-ingress-ipv4"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    dest_ip_ranges = ["0.0.0.0/0"]

    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}


# Deny egress trafic
resource "google_compute_network_firewall_policy_rule" "deny_egress_ipv6" {
  project         = google_project.vertex-project.project_id
  action          = "deny"
  description     = "deny-ingress-ipv6"
  direction       = "EGRESS"
  disabled        = false
  enable_logging  = true
  firewall_policy = google_compute_network_firewall_policy.primary.name
  priority        = 2000000011
  rule_name       = "deny-ingress-ipv6"
  #  target_service_accounts = ["emailAddress:my@service-account.com"]

  match {
    dest_ip_ranges = ["0::0/0"]

    layer4_configs {
      ip_protocol = "all"
    }
  }
  depends_on = [
    google_compute_network_firewall_policy_association.primary,
  ]
}
