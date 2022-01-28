#Service outputs
output "service_name" {
  value = aws_ecs_service.this.name
}

output "service_arn" {
  value = aws_ecs_service.this.id
}

output "service_cluster" {
  value = aws_ecs_service.this.cluster
}

output "service_iam" {
  value = aws_ecs_service.this.iam_role
}


#Task definition outputs
output "task_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "task_revision" {
  value = aws_ecs_task_definition.this.revision
}


#ECR outputs
output "ecr_arn" {
  value = var.ecr_url == null ? aws_ecr_repository.this.arn : null
}

output "ecr_id" {
  value = var.ecr_url == null ? aws_ecr_repository.this.registry_id : null
}

output "ecr_uri" {
  value = var.ecr_url == null ? aws_ecr_repository.this.repository_url : var.ecr_url
}


#Target group outputs
output "target_group_arn" {
  value = var.enable_lb == true ? aws_lb_target_group.this.arn : null
}

output "target_group_arn_suffix" {
  value = var.enable_lb == true ? aws_lb_target_group.this.arn_suffix : null
}

output "target_group_name" {
  value = var.enable_lb == true ? aws_lb_target_group.this.name  : null
}



#CloudWatch Logs outputs
output "log_arn" {
  value = aws_cloudwatch_log_group.this.arn
}