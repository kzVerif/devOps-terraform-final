# 1. กำหนดภูมิภาคที่ต้องการ Deploy
variable "aws_region" {
  description = "Region ของ AWS ที่ต้องการสร้าง Resource"
  type        = string
  default     = "ap-southeast-1"
}

# 2. ชื่อกุญแจ SSH (ที่เราสร้างไว้ในข้อ 7.2)
variable "key_name" {
  description = "ชื่อของ Key Pair ใน AWS ที่ใช้สำหรับ SSH เข้าเครื่อง EC2"
  type        = string
  default     = "DevOps-Keys-Pairs"
}

# 3. ขนาดของ Server (Instance Type)
variable "instance_type" {
  description = "ขนาดของ EC2 Instance"
  type        = string
  # แก้ไข Default เป็น t3.micro เพราะ ap-southeast-7 ไม่รองรับ t2
  default     = "m7i-flex.large"
}

# 7. พอร์ตที่แอปพลิเคชันจะรัน
variable "app_port" {
  description = "พอร์ตที่แอปพลิเคชันจะรัน"
  type        = string
  default     = "3000"
}