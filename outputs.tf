output "vault_user" {
  value = var.vault_user
}

output "vault_user_pw" {
  value = var.vault_user_pw
}

output "consul_secrets_token" {
  value = vault_token.consul_agent.client_token
}