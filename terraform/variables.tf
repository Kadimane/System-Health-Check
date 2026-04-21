variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "health-system"
}

variable "container_image" {
  description = "Docker image URI (e.g. dockerhub-user/health-system-api:abc1234)"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS on the ALB"
  type        = string
}
