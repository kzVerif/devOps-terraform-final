provider "aws" {
  region = var.aws_region
}

# สร้าง Key Pair ใหม่และบันทึก Private Key ลงไฟล์ (เฉพาะถ้ายังไม่มี)
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
 
  # ป้องกันการแทนที่ Key Pair เดิมถ้ามีอยู่แล้วใน AWS หรือ State
  lifecycle {
    ignore_changes = [public_key]
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.example.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
 
  # ป้องกันการสร้างไฟล์ใหม่หากมีอยู่แล้ว (ในระดับ Logic ของ Terraform คือถ้า Content เปลี่ยนถึงจะแก้)
  # แต่ tls_private_key ปกติจะเสถียรใน State file
}

resource "aws_security_group" "app_sg" {
  name_prefix = "app_sg"
  description = "Security Group for App and DB"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port   = 3000
    to_port     = 3000
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


resource "aws_instance" "nodejs_server" {
  ami                    = "ami-0e7ff22101b84bcff" # Ensure this is Ubuntu 22.04 or 24.04
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              # Log everything to user-data.log
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              
              export DEBIAN_FRONTEND=noninteractive

              # 1. Update & Install Tools
              apt-get update -y
              apt-get install -y curl git

              # 2. Install Node.js 20 & PM2
              curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
              apt-get install -y nodejs
              npm install -g pm2

              # 3. Get Public IP (Required for NextAuth)
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

              # 4. Setup Application
              cd /home/ubuntu
              git clone https://github.com/kzVerif/ksrv-version1.git
              cd ksrv-version1

              # 5. Create .env file
              cat <<EOT > .env
              SECRET_KEY_SLIP2GO=xxx
              NEXTAUTH_SECRET=xxx
              DATABASE_URL=xxx
              NEXTAUTH_URL=http://$PUBLIC_IP:3000
              EOT

              # 6. Build and Start App
              chown -R ubuntu:ubuntu /home/ubuntu/ksrv-version1
              sudo -u ubuntu npm install
              sudo -u ubuntu npx prisma generate
              sudo -u ubuntu npm run build

              # 7. Start with PM2 to keep it running
              sudo -u ubuntu pm2 start npm --name "next-app" -- start
              sudo -u ubuntu pm2 save
              
              echo "Deployment Finished"
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "NodeJS-App-Server"
  }
}