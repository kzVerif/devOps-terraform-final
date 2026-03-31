output "app_public_url" {
  description = "Copy URL นี้ไปเปิดใน Browser เพื่อดูหน้าเว็บ Node.js"
  value       = "http://${aws_instance.nodejs_server.public_ip}:3000"
}

# แถม: เอาไว้เช็ค Public IP เผื่อใช้ SSH เข้าไปตรวจสอบ
output "instance_public_ip" {
  description = "Public IP ของ Server"
  value       = aws_instance.nodejs_server.public_ip
}