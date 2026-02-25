# In a real world application the SSL certificate would be issued by a valid CA
# instead of self-signed. The resources below exist only for demo purposes.
resource "tls_private_key" "self_signed" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self_signed" {
  private_key_pem = tls_private_key.self_signed.private_key_pem

  subject {
    common_name  = var.domain_name
    organization = var.project
  }

  dns_names = [var.domain_name]

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
