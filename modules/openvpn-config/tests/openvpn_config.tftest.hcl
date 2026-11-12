# Unit tests for the shared OpenVPN configuration module.
# Run with: terraform test   (no cloud credentials required)

variables {
  server_address = "203.0.113.10"
}

run "defaults" {
  assert {
    condition     = startswith(nonsensitive(output.user_data), "#cloud-config\n")
    error_message = "user_data must be a #cloud-config document."
  }

  assert {
    condition     = strcontains(nonsensitive(output.user_data), "openvpn-server@server.service")
    error_message = "user_data must enable the openvpn-server@server unit."
  }

  assert {
    condition     = keys(nonsensitive(output.client_configs)) == ["client"]
    error_message = "One profile should be generated for the default client."
  }

  assert {
    condition     = strcontains(nonsensitive(output.client_configs["client"]), "remote 203.0.113.10 1194")
    error_message = "Client profile must point at server_address:port."
  }

  assert {
    condition     = strcontains(nonsensitive(output.client_configs["client"]), "verify-x509-name openvpn-server name")
    error_message = "Client profile must pin the server certificate name."
  }

  assert {
    condition     = length(regexall("(?m)^[0-9a-f]{32}$", nonsensitive(local.tls_crypt_key))) == 16
    error_message = "tls-crypt key must be 16 lines of 32 hex characters."
  }

  assert {
    condition     = strcontains(local.server_conf, "push \"redirect-gateway def1 bypass-dhcp\"")
    error_message = "Full tunnel should push redirect-gateway."
  }

  assert {
    condition     = strcontains(local.server_conf, "explicit-exit-notify 1")
    error_message = "UDP servers should send explicit-exit-notify."
  }

  assert {
    condition     = contains([for f in nonsensitive(local.write_files) : f.path], "/etc/openvpn/server/ccd/client")
    error_message = "Each client needs a ccd file (ccd-exclusive)."
  }

  assert {
    condition     = !strcontains(nonsensitive(output.user_data), "fail2ban")
    error_message = "fail2ban should be off by default."
  }

  assert {
    condition     = output.client_config_files == {}
    error_message = "No files should be written when client_config_dir is null."
  }
}

run "tcp_split_tunnel_multiple_clients" {
  variables {
    protocol        = "tcp"
    port            = 443
    full_tunnel     = false
    pushed_routes   = ["10.20.0.0/16"]
    clients         = ["laptop", "phone"]
    vpn_cidr        = "10.99.0.0/24"
    enable_fail2ban = true
  }

  assert {
    condition     = strcontains(local.server_conf, "proto tcp") && strcontains(local.server_conf, "port 443")
    error_message = "Server must use the requested protocol and port."
  }

  assert {
    condition     = !strcontains(local.server_conf, "redirect-gateway") && !strcontains(local.server_conf, "explicit-exit-notify")
    error_message = "Split tunnel over TCP must not push redirect-gateway or explicit-exit-notify."
  }

  assert {
    condition     = strcontains(local.server_conf, "push \"route 10.20.0.0 255.255.0.0\"")
    error_message = "pushed_routes must be rendered as route pushes."
  }

  assert {
    condition     = strcontains(local.server_conf, "server 10.99.0.0 255.255.255.0")
    error_message = "vpn_cidr must be rendered as the server network."
  }

  assert {
    condition     = toset(keys(nonsensitive(output.client_configs))) == toset(["laptop", "phone"])
    error_message = "One profile per client."
  }

  assert {
    condition     = strcontains(nonsensitive(output.user_data), "fail2ban")
    error_message = "fail2ban should be installed when enabled."
  }
}

run "rejects_invalid_client_name" {
  command = plan

  variables {
    clients = ["ok", "not ok"]
  }

  expect_failures = [var.clients]
}

run "rejects_host_address_as_vpn_cidr" {
  command = plan

  variables {
    vpn_cidr = "10.8.0.5/24"
  }

  expect_failures = [var.vpn_cidr]
}

run "rejects_bad_protocol" {
  command = plan

  variables {
    protocol = "sctp"
  }

  expect_failures = [var.protocol]
}
