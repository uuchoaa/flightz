# Hetzner Cloud infra for the inventario app.
# Provisions a single CX23 server + SSH key + firewall; Kamal deploys onto it.
# Token is read from the HCLOUD_TOKEN env var (never hardcode it here).
#
#   cd infra && tofu init && tofu apply
#   tofu destroy   # tears the server + IP down, billing stops

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.48"
    }
  }
}

provider "hcloud" {}

resource "hcloud_ssh_key" "mac" {
  name       = "inventario-mac"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "hcloud_firewall" "inventario" {
  name = "inventario-fw"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "inventario" {
  name         = "inventario"
  server_type  = "cx23"
  image        = "ubuntu-24.04"
  location     = "fsn1"
  ssh_keys     = [hcloud_ssh_key.mac.id]
  firewall_ids = [hcloud_firewall.inventario.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

output "ipv4" {
  value = hcloud_server.inventario.ipv4_address
}

output "sslip_host" {
  value = "${replace(hcloud_server.inventario.ipv4_address, ".", "-")}.sslip.io"
}
