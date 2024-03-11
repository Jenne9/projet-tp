resource "random_pet" "sg" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/xvdf"  # Nom du périphérique sur l'instance (peut varier selon l'OS)
  instance_id = aws_instance.opencti.id
  volume_id   = aws_ebs_volume.ebs.id
}

resource "aws_ebs_volume" "ebs" {
  availability_zone = aws_instance.opencti.availability_zone
  size              = 10  # Taille du volume en GiB
  type              = "gp2"  # Type de volume
}

resource "aws_instance" "opencti" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.large"
  vpc_security_group_ids = [aws_security_group.app-sg.id]

  tags = {
    Name = "opencti"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y software-properties-common
              sudo apt-add-repository --yes --update ppa:ansible/ansible
              sudo apt install -y ansible
              sudo apt install -y python3-pip
              sudo pip install botocore
              sudo pip install boto3
              EOF
              

}

resource "aws_security_group" "app-sg" {
  name = "${random_pet.sg.id}-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "opencti-address" {
  value = "${aws_instance.opencti.public_ip}:8080"
}
