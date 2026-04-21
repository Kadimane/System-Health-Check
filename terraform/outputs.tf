output "alb_dns_name" {
  description = "Public DNS of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint (private)"
  value       = module.rds.endpoint
}
