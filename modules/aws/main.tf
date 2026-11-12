locals {
  tags = merge({ Name = var.name, ManagedBy = "terraform", Project = "TerraformOpenVPN" }, var.tags)

  ssh_enabled = var.ssh_public_key != null && length(var.ssh_allowed_cidrs) > 0
  burstable   = data.aws_ec2_instance_type.this.burstable_performance_supported
  arch        = contains(data.aws_ec2_instance_type.this.supported_architectures, "arm64") ? "arm64" : "amd64"
  ami_id      = coalesce(var.ami_id, try(data.aws_ami.ubuntu[0].id, null))

  # First AZ (alphabetically) that both is available and offers the instance type.
  availability_zone = coalesce(var.availability_zone, try(sort(tolist(setintersection(
    toset(data.aws_availability_zones.available.names),
    toset(data.aws_ec2_instance_type_offerings.available.locations),
  )))[0], null))
}

################################################################################
# Lookups
################################################################################

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ec2_instance_type_offerings" "available" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
}

data "aws_ec2_instance_type" "this" {
  instance_type = var.instance_type
}

data "aws_ami" "ubuntu" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-${local.arch}-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

################################################################################
# OpenVPN configuration (PKI, cloud-init, client profiles)
################################################################################

module "openvpn_config" {
  source = "../openvpn-config"

  name                 = var.name
  server_address       = aws_eip.this.public_ip
  clients              = var.clients
  port                 = var.vpn_port
  protocol             = var.vpn_protocol
  vpn_cidr             = var.vpn_cidr
  dns_servers          = var.dns_servers
  full_tunnel          = var.full_tunnel
  pushed_routes        = var.pushed_routes
  cert_subject         = var.cert_subject
  client_config_dir    = var.client_config_dir
  client_config_prefix = var.client_config_prefix
  enable_fail2ban      = local.ssh_enabled
}

################################################################################
# Network
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.tags
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = local.tags
}

resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.vpc_cidr
  availability_zone = local.availability_zone

  tags = local.tags

  lifecycle {
    precondition {
      condition     = local.availability_zone != null
      error_message = "No available zone in this region offers instance type ${var.instance_type}."
    }
  }
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = local.tags
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "OpenVPN server"
  vpc_id      = aws_vpc.this.id

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpn" {
  for_each = toset(var.vpn_allowed_cidrs)

  security_group_id = aws_security_group.this.id
  description       = "OpenVPN"
  ip_protocol       = var.vpn_protocol
  from_port         = var.vpn_port
  to_port           = var.vpn_port
  cidr_ipv4         = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = local.ssh_enabled ? toset(var.ssh_allowed_cidrs) : toset([])

  security_group_id = aws_security_group.this.id
  description       = "SSH"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.tags
}

# The ENI and Elastic IP exist before the instance, so the instance has its
# public address from first boot and keeps it across replacements.
resource "aws_network_interface" "this" {
  subnet_id       = aws_subnet.this.id
  security_groups = [aws_security_group.this.id]

  tags = local.tags
}

resource "aws_eip" "this" {
  domain            = "vpc"
  network_interface = aws_network_interface.this.id

  tags = local.tags

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# Instance
################################################################################

resource "aws_key_pair" "this" {
  count = var.ssh_public_key == null ? 0 : 1

  key_name_prefix = "${var.name}-"
  public_key      = var.ssh_public_key

  tags = local.tags
}

resource "aws_instance" "this" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = try(aws_key_pair.this[0].key_name, null)

  user_data                   = module.openvpn_config.user_data
  user_data_replace_on_change = true

  primary_network_interface {
    network_interface_id = aws_network_interface.this.id
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  dynamic "credit_specification" {
    for_each = local.burstable ? [1] : []

    content {
      cpu_credits = "standard"
    }
  }

  tags        = local.tags
  volume_tags = local.tags

  depends_on = [aws_eip.this, aws_route_table_association.this]
}
