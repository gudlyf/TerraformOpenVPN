# Plan/apply the AWS module against a mocked AWS provider.
# Run with: terraform test   (no AWS credentials required)

mock_provider "aws" {
  override_data {
    target = data.aws_availability_zones.available
    values = { names = ["ca-central-1a", "ca-central-1b", "ca-central-1d"] }
  }

  override_data {
    target = data.aws_ec2_instance_type_offerings.available
    values = { locations = ["ca-central-1d", "ca-central-1b"] }
  }

  override_data {
    target = data.aws_ec2_instance_type.this
    values = { supported_architectures = ["arm64"], burstable_performance_supported = true }
  }

  override_data {
    target = data.aws_ami.ubuntu
    values = { id = "ami-0123456789abcdef0" }
  }

  override_resource {
    target = aws_eip.this
    values = { public_ip = "203.0.113.20" }
  }
}

run "defaults" {
  assert {
    condition     = aws_subnet.this.availability_zone == "ca-central-1b"
    error_message = "Should pick the first AZ that offers the instance type."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ssh) == 0
    error_message = "SSH must be closed by default."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.vpn["0.0.0.0/0"].ip_protocol == "udp" && aws_vpc_security_group_ingress_rule.vpn["0.0.0.0/0"].from_port == 1194
    error_message = "VPN port must be open on UDP 1194."
  }

  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required."
  }

  assert {
    condition     = aws_instance.this.credit_specification[0].cpu_credits == "standard"
    error_message = "Burstable instances should use standard credits to avoid surprise charges."
  }

  assert {
    condition     = length(aws_key_pair.this) == 0
    error_message = "No key pair should be created by default."
  }

  assert {
    condition     = strcontains(nonsensitive(module.openvpn_config.client_configs["client"]), "remote 203.0.113.20 1194")
    error_message = "Client profile must use the Elastic IP."
  }
}

run "ssh_enabled" {
  variables {
    ssh_public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtxl2X4gk5ywJSqPLUvd+SVQIDGb/kqzONGmNI9PZGo test"
    ssh_allowed_cidrs = ["198.51.100.7/32"]
    vpn_allowed_cidrs = ["198.51.100.0/24"]
    vpn_protocol      = "tcp"
    vpn_port          = 443
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ssh) == 1
    error_message = "SSH rule expected when a key and CIDRs are given."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.vpn["198.51.100.0/24"].ip_protocol == "tcp"
    error_message = "VPN rule must follow vpn_protocol."
  }

  assert {
    condition     = strcontains(nonsensitive(aws_instance.this.user_data), "fail2ban")
    error_message = "fail2ban should be enabled with SSH."
  }
}

run "rejects_bad_cidr" {
  command = plan

  variables {
    ssh_allowed_cidrs = ["not-a-cidr"]
  }

  expect_failures = [var.ssh_allowed_cidrs]
}
