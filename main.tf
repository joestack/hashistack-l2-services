data "terraform_remote_state" "l1" {
  backend = "remote"

  config = {
    organization = var.remote_state_org
    workspaces = {
      name = var.remote_state_l1
    }
  }
}


locals {
  consul_cluster_addr    = data.terraform_remote_state.l1.outputs.cluster_url
  consul_datacenter      = data.terraform_remote_state.l1.outputs.consul_datacenter
  consul_init_token      = data.terraform_remote_state.l1.outputs.consul_init_token
  vault_admin_token      = var.root_token
}


provider "consul" {
  address    = "${local.consul_cluster_addr}:8500"
  datacenter = local.consul_datacenter
  token      = local.consul_init_token
}



resource "consul_acl_policy" "web" {
  name  = "web-services"
  rules = <<-RULE
    node_prefix "web-" {
        policy = "write"
    }
     service_prefix "web-" {
        policy = "write"
    }
    RULE
}


resource "consul_acl_policy" "db" {
  name  = "db-services"
  rules = <<-RULE
    node_prefix "db-" {
        policy = "write"
    }
    service_prefix "db-" {
        policy = "write"
    }
    RULE
}



provider "vault" {
  address = "https://${local.consul_cluster_addr}:8200"
  skip_tls_verify = true
  token = local.vault_admin_token
}

// Create the secrets_backend Consul
resource "vault_consul_secret_backend" "services" {
  path        = "consul"
  description = "Manages the Consul backend"
  address     = "${local.consul_cluster_addr}:8500"
  token       = local.consul_init_token
}

// Create a Vault role tied to consul policies
resource "vault_consul_secret_backend_role" "services" {
    depends_on = [ consul_acl_policy.db, consul_acl_policy.web ]

  name    = "services-role"
  backend = vault_consul_secret_backend.services.path

  consul_policies = [
    "db-services",
    "web-services"
  ]
}

// Vault auth_engine for Consul agents to be authenticated
//    auth-aws is not possible due to doormat restrictions
//    user/password instead
// Vault policy assigned to Consul auth with access to Vault role

# resource "vault_auth_backend" "userpass" {
#   type = "userpass"
# }

# resource "vault_generic_endpoint" "adm-user" {
#   depends_on           = [vault_auth_backend.userpass]
#   path                 = "auth/userpass/users/${var.vault_user}"
#   ignore_absent_fields = true

#     data_json = data.template_file.user.rendered
# }

# data "template_file" "user" {
#   template = file("${path.root}/templates/user.tpl")
#   vars = {
#     policy = vault_policy.consul_svc.name
#     password = var.vault_user_pw
#   }
# }

// same aproach as user/pass but as token to provide access to consul_secret_backend via vault agent on each workload node

resource "vault_token" "vault_agent" {
  #role_name = "services-role"

  policies = [vault_policy.consul_svc.name]

  renewable = true
  ttl = "24h"

  # renew_min_lease = 43200
  # renew_increment = 86400

  # metadata = {
  #   "purpose" = "vault-agent"
  # }
}


resource "vault_policy" "consul_svc" {
  name = "consul-svc"

  policy = <<EOT

# Allow managing leases
path "sys/leases/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage auth backends broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete auth backends
path "sys/auth/*"
{
  capabilities = ["create", "read", "update", "delete", "sudo"]
}

# List existing policies
path "sys/policies"
{
  capabilities = ["read"]
}

# Create and manage ACL policies broadly across Vault
path "sys/policies/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete consul secrets
path "consul/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}


# Manage and manage secret backends broadly across Vault.
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secret engines.
path "sys/mounts"
{
  capabilities = ["read"]
}

# Read health checks
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

EOT
}
