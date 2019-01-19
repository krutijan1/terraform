variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "ssh_port" {}

# variable "key_name" {
#   default = "testing"
# }

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "eu-west-1"
}

resource "aws_instance" "nginx" {
  ami           = "ami-047bb4163c506cd98"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_security_group.http.id}"]
  key_name      = "testing"

  connection {
    user        = "ec2-user"
    private_key = "${file("${path.module}/${var.private_key_path}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install nginx -y",
      "sudo service nginx start",
    ]
  }
}

resource "aws_security_group" "ssh" {

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "${var.ssh_port}"
    to_port   = "${var.ssh_port}"
    protocol  = "tcp"

    # To keep this example simple, we allow incoming SSH requests from any IP. In real-world usage, you should only
    # allow SSH requests from trusted servers, such as a bastion host or VPN server.
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "http" {

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_eip" "ip" {
  instance = "${aws_instance.nginx.id}"
}

output "aws_instance_public_dns" {
  value = "${aws_instance.nginx.public_dns}"
}
