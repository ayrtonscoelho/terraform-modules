data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

data "template_file" "this" {
  template = file("${path.module}/documents/task-definitions/default_task_definition.json")

  vars = {
    #Configurações do serviço.
    SERVICE_NAME        = var.service_name
    SERVICE_MEMORY      = var.service_memory
    SERVICE_PORT        = var.service_port
    SERVICE_CPU         = var.service_cpu
    SERVICE_MOUNTPOINTS = jsonencode(var.service_mountpoints)
    SERVICE_ULIMITS     = jsonencode(var.service_ulimits)
    SERVICE_ENTRYPOINT  = jsonencode(var.service_entrypoint)
    SERVICE_COMMAND     = jsonencode(var.service_command)
    SERVICE_ENVIRONMENT = jsonencode(var.service_environment)
    SERVICE_SECRETS     = jsonencode(var.service_secrets)
    ECR_URL             = local.ecr_url

    #Configurações de health check do serviço.
    HEALTHCHECK_COMMAND  = local.service_health_check.command
    HEALTHCHECK_TIMEOUT  = local.service_health_check.timeout
    HEALTHCHECK_INTERVAL = local.service_health_check.interval
    HEALTHCHECK_RETRIES  = local.service_health_check.retries
    HEALTHCHECK_START    = local.service_health_check.start

    #Configurações de rede do serviço.
    AWS_REGION   = data.aws_region.this.name
    NETWORK_MODE = var.network_mode
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = var.network_mode
  cpu                      = var.service_cpu
  memory                   = var.service_memory
  execution_role_arn       = var.iam_role
  task_role_arn            = var.iam_role
  container_definitions    = data.template_file.this.rendered
}

data "aws_ecs_task_definition" "this" {
  task_definition = aws_ecs_task_definition.this.family

  depends_on = [
    aws_ecs_task_definition.this, 
  ]
}


locals {
  #Condicionais para healthcheck interno da task.
  service_health_check = {
    command  = var.service_health_check.command
    start    = var.service_health_check.start
    timeout  = var.healthcheck_task_timeout != null ? var.healthcheck_task_timeout : var.service_health_check.timeout
    interval = var.service_health_check.interval
    retries  = var.service_health_check.retries
  }

  #Verifica qual imagem o serviço deve utilizar.
  ecr_url = var.ecr_url == null ? aws_ecr_repository.this[0].repository_url : var.ecr_url
}