variable "remote_state_org" {
  description = "Terraform Organization where to access remote_state from"
  default = "JoeStack"
}

variable "remote_state_l1" {
  description = "TFC Workspace where to consume Layer1 platform outputs from (i.e. cluster_url)"
  default = "hashistack-l1-platform"
}

variable "root_token" {
  description = "Vault token to be used for provider authentication"
}

variable "vault_user" {
  description = "Additinal non-root Username to access Vault"
}

variable "vault_user_pw" {
  description = "non-root Password to access Vault"
}