variable "tfc_state_org" {
  description = "TFC Organization where to access remote_state from"
  default = "JoeStack"
}

variable "rs_platform_hcp" {
  description = "TFC Workspace where to consume outputs from (cluster_url)"
  default = "tfc-aws-hashistack"
}

variable "vault_admin_token" {
  description = "token to be used for provider authentication"
}

variable "vault_adm_user" {
  description = "Additinal non-root Username to access Vault"
}

variable "vault_adm_password" {
  description = "non-root Password to access Vault"
}