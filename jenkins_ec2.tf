resource "aws_instance" "jenkins_server" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jn_tf.id]
  key_name               = "jenkins-key"

user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y fontconfig openjdk-17-jre 
              
              sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update
              sudo apt-get install -y jenkins
              sudo systemctl enable jenkins
              sudo systemctl start jenkins

              sudo apt install -y nginx
              sudo systemctl enable nginx
              sudo systemctl start jenkins
              EOF

  tags = {
    Name = "jenkins-ubuntu-server"
  }

}

output "jenkins_server_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

#Create's local file key pair for SSH
resource "aws_key_pair" "jenkins-key" {
  key_name   = "jenkins-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "jenkins-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "jenkins_key"
}

# Jenkins ec2 security group for SSH,HTTP,HTTPS,port 8080
resource "aws_security_group" "jn_tf" {
  name        = "jenkins-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = "<your_vpc_id>"


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<desired_ip_range>/32"]
  }

ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["<desired_ip_range>/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["<desired_ip_range>/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["<desired_ip_range>/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "jenkins_server_sg"
  }
}