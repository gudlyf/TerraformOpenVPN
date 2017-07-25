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
  instance_type = "t2.micro"

  associate_public_ip_address = true
  source_dest_check = false
  security_groups = ["${aws_security_group.ovpn_sg.name}"]

  key_name = "${aws_key_pair.ec2-key.key_name}"

  user_data = "${data.template_file.deployment_shell_script.rendered}"

  provisioner "local-exec" {
    command = "rm -f ./${aws_instance.ovpn.id}.ovpn && sleep 180 && scp -o StrictHostKeyChecking=no -i ${var.private_key_file} ubuntu@${aws_instance.ovpn.public_ip}:/etc/openvpn/client.ovpn ./${aws_instance.ovpn.id}.ovpn"
  }

  tags {
    Name = "ovpn"
  }
}

data "template_file" "deployment_shell_script" {
  template = "${file("userdata.sh")}"
}

resource "aws_key_pair" "ec2-key" {
  key_name_prefix  = "ovpn-key-"
  public_key       = "${file(var.public_key_file)}"
}
