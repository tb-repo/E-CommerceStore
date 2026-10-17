output "ec2_public_ip" {
  description = "Public IP of the EC2 Instance"
  value       = aws_instance.ecommerce.public_ip
}

output "frontend_url_port_80" {
  description = "Frontend URL (Port 80)"
  value       = "http://${aws_instance.ecommerce.public_ip}"
}

output "frontend_url_port_3000" {
  description = "Frontend URL (Port 3000)"
  value       = "http://${aws_instance.ecommerce.public_ip}:3000"
}

output "user_service_health" {
  description = "User Service Health Check"
  value       = "http://${aws_instance.ecommerce.public_ip}:3001/health"
}

output "product_service_health" {
  description = "Product Service Health Check"
  value       = "http://${aws_instance.ecommerce.public_ip}:3002/health"
}

output "cart_service_health" {
  description = "Cart Service Health Check"
  value       = "http://${aws_instance.ecommerce.public_ip}:3003/health"
}

output "order_service_health" {
  description = "Order Service Health Check"
  value       = "http://${aws_instance.ecommerce.public_ip}:3004/health"
}