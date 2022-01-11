data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

data "template_file" "this" {
  template = file("${path.module}/documents/task-definitions/default_task_definition.json")

  vars = {
    #Configurações do serviço.
    SERVICE_NAME        = var.service_name
    SERVICE_MEMORY      = var.service_memory
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
    PORT_MAP     = replace(jsonencode(local.port_mappings), "/\"([0-9]+\\.?[0-9]*)\"/", "$1",)
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

  container_definitions = data.template_file.this.rendered

  depends_on = [aws_lb_target_group.this]
}

data "aws_ecs_task_definition" "this" {
  task_definition = aws_ecs_task_definition.this.family

  depends_on = [
    aws_ecs_task_definition.this, 
    aws_ecr_repository.this
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

  #Merge de portas que o serviço responde.
  port_mappings = [
    {
      containerPort = element(
        compact(concat(
        var.service_extra_ports, [var.service_port]
      )), 0 )

      hostPort = var.health_check_settings.protocol == "TCP" ? 0 : element(
        compact(concat(
        var.service_extra_ports, [var.service_port]
      )), 0 )

      protocol = "tcp"
    }
  ]

  #Verifica qual imagem o serviço deve utilizar.
  ecr_url = var.ecr_url == null ? aws_ecr_repository.this[0].repository_url : var.ecr_url
}