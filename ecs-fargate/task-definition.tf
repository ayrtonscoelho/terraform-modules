data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

locals {
  
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = var.network_mode
  cpu                      = var.service_cpu
  memory                   = var.service_memory
  execution_role_arn       = var.iam_role
  task_role_arn            = var.iam_role

  container_definitions = templatefile("${path.module}/documents/task-definitions/default_task_definition.json", {
    SERVICE_NAME        = var.service_name
    SERVICE_MEMORY      = var.service_memory
    SERVICE_CPU         = var.service_cpu
    SERVICE_MOUNTPOINTS = jsonencode(var.service_mountpoints)
    SERVICE_ULIMITS     = jsonencode(var.service_ulimits)
    SERVICE_ENTRYPOINTS = jsonencode(var.service_entrypoint)
    SERVICE_COMMAND     = jsonencode(var.service_command)
    SERVICE_ENVIRONMENT = jsonencode(var.service_environment)
    SERVICE_SECRETS     = jsonencode(var.service_secrets)

    #REVER
    HEALTHCHECK_COMMAND  = local.service_health_check.command
    HEALTHCHECK_TIMEOUT  = local.service_health_check.timeout
    HEALTHCHECK_INTERVAL = local.service_health_check.interval
    HEALTHCHECK_RETRIES  = local.service_health_check.retries
    HEALTHCHECK_START    = local.service_health_check.start


    AWS_REGION    = data.aws_region.this.name
    ECR_URL       = local.ecr_url
    NETWORK_MODE  = var.network_mode
    PORT_MAP      = replace(jsonencode(local.port_mappings), "/\"([0-9]+\\.?[0-9]*)\"/", "$1",)
  })



#   container_definitions = <<CONTAINER
#   [
#     {
#       "name": "${var.service_name}",
#       "image": "${var.ecr_url == null ? aws_ecr_repository.this[0].repository_url : var.ecr_url}",
#       "networkMode": "${var.network_mode}",
#       "portMappings": ${replace(
#         jsonencode(local.port_mappings),
#         "/\"([0-9]+\\.?[0-9]*)\"/",
#         "$1",
#       )},
#       "memory": ${var.service_memory},
#       "cpu": ${var.service_cpu},
#       "memoryReservation": ${var.service_memory},
#       "essential": true,
#       "mountPoints": ${jsonencode(var.container_mountpoints)},
#       "ulimits": ${jsonencode(var.container_ulimits)},
#       "entryPoint": ${jsonencode(var.container_entrypoint)},
#       "command": ${jsonencode(var.container_command)},
#       "environment": ${jsonencode(var.container_environment)},
#       "healthCheck": {
#         "command": [
#           "CMD-SHELL",
#           "${var.healthcheck_cmd}"
#         ],
#         "timeout": ${var.healthcheck_task_timeout != null ? var.healthcheck_task_timeout : var.healthcheck_timeout},
#         "interval": ${var.healthcheck_interval},
#         "retries": ${var.healthcheck_retries},
#         "startPeriod": ${var.healthcheck_start_period}
#       },
#       "logConfiguration": {
#         "logDriver": "awslogs",
#         "options": {
#           "awslogs-group": "/ecs/${var.service_name}",
#           "awslogs-region": "${var.region != null ? var.region : data.aws_region.this.name}",
#           "awslogs-stream-prefix": "${var.service_name}"
#         }
#       },
#       "secrets": ${jsonencode(var.container_secrets)}
#     }
#   ]
# CONTAINER

  depends_on = [aws_lb_target_group.this]
}

data "aws_ecs_task_definition" "this" {
  task_definition = aws_ecs_task_definition.this.family
  depends_on      = [aws_ecs_task_definition.this, aws_ecr_repository.this]
}


locals {
  #Condicionais para healthcheck interno da task.
  service_health_check = {
    command  = var.service_health_check.command
    start    = var.service_health_check.start
    timeout  = var.healthcheck_task_timeout != null ? var.healthcheck_task_timeout : local.service_health_check.timeout
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
