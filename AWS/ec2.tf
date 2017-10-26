data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "ovpn" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.nano"

  associate_public_ip_address = true
  source_dest_check = false
  security_groups = ["${aws_security_group.ovpn_sg.name}"]

  key_name = "${aws_key_pair.ec2-key.key_name}"

  user_data = "${data.template_file.deployment_shell_script.rendered}"

  ## TO DO: Consider adding a remote-exec to come before next local-exec in place of the sleep

  provisioner "local-exec" {
    command = "sleep 180 && scp -o StrictHostKeyChecking=no -i ${var.private_key_file} ubuntu@${aws_instance.ovpn.public_ip}:/etc/openvpn/client.ovpn ${var.client_config_path}/${var.client_config_name}.ovpn"
  }

  provisioner "local-exec" {
    command = "rm -f ${var.client_config_path}/${var.client_config_name}.ovpn"
    when = destroy
  }

  tags {
    Name = "ovpn"
  }
}

data "template_file" "deployment_shell_script" {
  template = "${file("userdata.sh")}"

  vars {
    cert_details = "${file(var.cert_details)}"
    client_config_name = "${var.client_config_name}"
  }
}

resource "aws_key_pair" "ec2-key" {
  key_name_prefix  = "ovpn-key-"
  public_key       = "${file(var.public_key_file)}"
}
