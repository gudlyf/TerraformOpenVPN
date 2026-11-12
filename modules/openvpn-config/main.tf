locals {
  server_common_name = "${var.name}-server"

  vpn_network = split("/", var.vpn_cidr)[0]
  vpn_netmask = cidrnetmask(var.vpn_cidr)

  subject = {
    organization        = var.cert_subject.organization
    organizational_unit = var.cert_subject.organizational_unit
    country             = var.cert_subject.country
    province            = var.cert_subject.province
    locality            = var.cert_subject.locality
  }
}

################################################################################
# Certificate authority
################################################################################

resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  is_ca_certificate     = true
  set_subject_key_id    = true
  set_authority_key_id  = true
  validity_period_hours = var.ca_validity_hours
  early_renewal_hours   = 720

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  subject {
    common_name         = "${var.name} CA"
    organization        = local.subject.organization
    organizational_unit = local.subject.organizational_unit
    country             = local.subject.country
    province            = local.subject.province
    locality            = local.subject.locality
  }
}

################################################################################
# Server certificate
################################################################################

resource "tls_private_key" "server" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name         = local.server_common_name
    organization        = local.subject.organization
    organizational_unit = local.subject.organizational_unit
    country             = local.subject.country
    province            = local.subject.province
    locality            = local.subject.locality
  }
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = var.cert_validity_hours
  early_renewal_hours   = 720
  set_subject_key_id    = true

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

################################################################################
# Client certificates (one per client)
################################################################################

resource "tls_private_key" "client" {
  for_each = var.clients

  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "client" {
  for_each = var.clients

  private_key_pem = tls_private_key.client[each.key].private_key_pem

  subject {
    common_name         = each.key
    organization        = local.subject.organization
    organizational_unit = local.subject.organizational_unit
    country             = local.subject.country
    province            = local.subject.province
    locality            = local.subject.locality
  }
}

resource "tls_locally_signed_cert" "client" {
  for_each = var.clients

  cert_request_pem   = tls_cert_request.client[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = var.cert_validity_hours
  early_renewal_hours   = 720
  set_subject_key_id    = true

  allowed_uses = [
    "digital_signature",
    "client_auth",
  ]
}

################################################################################
# tls-crypt pre-shared key (OpenVPN static key V1: 2048 bits)
################################################################################

resource "random_bytes" "tls_crypt" {
  length = 256
}

locals {
  tls_crypt_key = join("\n", concat(
    ["-----BEGIN OpenVPN Static key V1-----"],
    [for i in range(16) : substr(random_bytes.tls_crypt.hex, i * 32, 32)],
    ["-----END OpenVPN Static key V1-----"],
  ))
}

################################################################################
# Rendered configuration
################################################################################

locals {
  server_conf = templatefile("${path.module}/templates/server.conf.tftpl", {
    port        = var.port
    protocol    = var.protocol
    network     = local.vpn_network
    netmask     = local.vpn_netmask
    full_tunnel = var.full_tunnel
    dns_servers = var.dns_servers
    pushed_routes = [for r in var.pushed_routes : {
      network = cidrhost(r, 0)
      netmask = cidrnetmask(r)
    }]
  })

  client_configs = {
    for c in var.clients : c => templatefile("${path.module}/templates/client.ovpn.tftpl", {
      client             = c
      server_address     = var.server_address
      port               = var.port
      protocol           = var.protocol
      server_common_name = local.server_common_name
      ca_cert            = tls_self_signed_cert.ca.cert_pem
      client_cert        = tls_locally_signed_cert.client[c].cert_pem
      client_key         = tls_private_key.client[c].private_key_pem
      tls_crypt_key      = local.tls_crypt_key
    })
  }

  server_dir = "/etc/openvpn/server"

  # Every file is deferred so it is written after packages are installed and
  # just before runcmd executes.
  write_files = concat(
    [
      {
        path        = "${local.server_dir}/server.conf"
        permissions = "0644"
        content     = local.server_conf
      },
      {
        path        = "${local.server_dir}/ca.crt"
        permissions = "0644"
        content     = tls_self_signed_cert.ca.cert_pem
      },
      {
        path        = "${local.server_dir}/server.crt"
        permissions = "0644"
        content     = tls_locally_signed_cert.server.cert_pem
      },
      {
        path        = "${local.server_dir}/server.key"
        permissions = "0600"
        content     = tls_private_key.server.private_key_pem
      },
      {
        path        = "${local.server_dir}/tls-crypt.key"
        permissions = "0600"
        content     = "${local.tls_crypt_key}\n"
      },
      {
        path        = "/etc/sysctl.d/99-openvpn-forward.conf"
        permissions = "0644"
        content     = "net.ipv4.ip_forward = 1\n"
      },
      {
        path        = "/etc/default/openvpn-nat"
        permissions = "0644"
        content     = "VPN_CIDR=${var.vpn_cidr}\n"
      },
      {
        path        = "/usr/local/sbin/openvpn-nat"
        permissions = "0755"
        content     = file("${path.module}/files/openvpn-nat")
      },
      {
        path        = "/etc/systemd/system/openvpn-nat.service"
        permissions = "0644"
        content     = file("${path.module}/files/openvpn-nat.service")
      },
    ],
    [
      for c in sort(tolist(var.clients)) : {
        path        = "${local.server_dir}/ccd/${c}"
        permissions = "0644"
        content     = "# Managed by Terraform. This file authorizes client \"${c}\" (ccd-exclusive).\n"
      }
    ],
    var.enable_fail2ban ? [
      {
        path        = "/etc/fail2ban/jail.d/sshd.local"
        permissions = "0644"
        content     = file("${path.module}/files/fail2ban-sshd.local")
      },
    ] : [],
  )

  cloud_config = merge(
    {
      package_update  = true
      package_upgrade = var.upgrade_packages
      packages        = concat(["openvpn", "iptables"], var.enable_fail2ban ? ["fail2ban", "python3-systemd"] : [])

      write_files = [for f in local.write_files : merge(f, { owner = "root:root", defer = true })]

      runcmd = concat(
        [
          ["sysctl", "--load", "/etc/sysctl.d/99-openvpn-forward.conf"],
          ["systemctl", "daemon-reload"],
          ["systemctl", "enable", "--now", "openvpn-nat.service"],
          ["systemctl", "enable", "--now", "openvpn-server@server.service"],
        ],
        var.enable_fail2ban ? [["systemctl", "enable", "--now", "fail2ban.service"], ["systemctl", "restart", "fail2ban.service"]] : [],
      )
    },
    var.reboot_if_required ? {
      power_state = {
        mode      = "reboot"
        delay     = "now"
        message   = "Rebooting to finish applying package upgrades"
        condition = ["test", "-f", "/var/run/reboot-required"]
      }
    } : {},
  )

  user_data = "#cloud-config\n${yamlencode(local.cloud_config)}"
}

resource "local_sensitive_file" "client_config" {
  for_each = var.client_config_dir == null ? toset([]) : var.clients

  filename             = "${var.client_config_dir}/${var.client_config_prefix}${each.key}.ovpn"
  content              = local.client_configs[each.key]
  file_permission      = "0600"
  directory_permission = "0755"
}
