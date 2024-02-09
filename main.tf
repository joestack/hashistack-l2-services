data "terraform_remote_state" "hcp" {
  backend = "remote"

  config = {
    organization = var.tfc_state_org
    workspaces = {
      name = var.rs_platform_hcp
    }
  }
}


locals {
  consul_cluster_addr    = data.terraform_remote_state.hcp.outputs.cluster_url
  consul_datacenter      = data.terraform_remote_state.hcp.outputs.consul_datacenter
  consul_init_token      = data.terraform_remote_state.hcp.outputs.consul_init_token
}


provider "consul" {
  address    = "${local.consul_cluster_addr}:8500"
  datacenter = local.consul_datacenter
  token      = local.consul_init_token
}



resource "consul_acl_policy" "web" {
  name  = "web-services"
  rules = <<-RULE
    node_prefix "webnode-" {
        policy = "write"
    }
    node_prefix "" {
        policy = "read"
    }
    service_prefix "" {
        policy = "read"
    }
    RULE
}


resource "consul_acl_policy" "db" {
  name  = "db-services"
  rules = <<-RULE
    node_prefix "dbnode-" {
        policy = "write"
    }
    node_prefix "" {
        policy = "read"
    }
    service_prefix "" {
        policy = "read"
    }
    RULE
}



# resource "consul_acl_token" "web" {
#   description = "web-services token"
#   policies    = [consul_acl_policy.web.name]
#   local       = true
# }

# resource "consul_acl_token" "db" {
#   description = "db-services token"
#   policies    = [consul_acl_policy.db.name]
#   local       = true
# }


provider "vault" {
  address = "https://${local.consul_cluster_addr}:8200"
  skip_tls_verify = true
  token = var.vault_admin_token
}

resource "vault_consul_secret_backend" "services" {
  path        = "consul-services"
  description = "Manages the Consul backend"
  address     = "${local.consul_cluster_addr}:8500"
  token       = local.consul_init_token
}

resource "vault_consul_secret_backend_role" "example" {
    depends_on = [ consul_acl_policy.db, consul_acl_policy.web ]

  name    = "services-role"
  backend = vault_consul_secret_backend.services.path

  consul_policies = [
    "db-services",
    "web-services"
  ]
}