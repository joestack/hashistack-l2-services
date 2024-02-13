output "vault_user" {
  value = var.vault_user
}

output "vault_user_pw" {
  value = var.vault_user_pw
}

output "vault_agent_token" {
  value = vault_token.vault_agent.client_token
  sensitive = true
}