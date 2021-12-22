/*========================
    **    ECS Service - Fargate  **
          ======================*/

resource "aws_ecs_service" "this" {
  name             = var.service_name
  cluster          = var.cluster_name
  desired_count    = var.desired_count
  platform_version = var.platform_version

  health_check_grace_period_seconds  = var.enable_lb == true ? var.healthcheck_grace_period : null
  deployment_maximum_percent         = var.deployment_settings.maximum_percent
  deployment_minimum_healthy_percent = var.deployment_settings.minimum_percent

  task_definition = "${aws_ecs_task_definition.this.family}:${
    max(
      aws_ecs_task_definition.this.revision, 
      data.aws_ecs_task_definition.this.revision
    )
  }"

  #Configuração necessária de rede para o serviço
  dynamic "network_configuration" {
    for_each = (var.health_check_settings.protocol != "TCP") ? [{}] : [] 
    content {
      security_groups  = var.network_settings.security_groups[*]
      subnets          = var.network_settings.subnet_ids
      assign_public_ip = try(
        var.network_settings.public_ip, 
        false
      )
    }
  }

  #Associção dos principais Load balancer e target group 
  dynamic "load_balancer" {
    for_each = var.enable_lb == true ? [{}] : []
    content{
      target_group_arn = aws_lb_target_group.this.0.arn
      container_name   = var.service_name
      container_port   = var.service_port
    }
  }

  #Associação dinâmica para target groups extras
  dynamic "load_balancer" {
    for_each = var.custom_tgs != [] ? var.custom_tgs : []
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  #Associação dinâmica do CloudMap
  dynamic "service_registries" {
    for_each = (var.health_check_settings.protocol != "TCP" || var.enable_sd == true) ? [{}] : [] 
    content {
      registry_arn = aws_service_discovery_service.this.0.arn
      port 				 = var.service_port
    }
  }

  #Estratégia para Fargate (FARGATE ou FARGATE_SPOT)
  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider
    content {
      capacity_provider = capacity_provider_strategy.value.type 
      weight = capacity_provider_strategy.value.weight
      base   = capacity_provider_strategy.value.base
    }
  }

  depends_on = [
    aws_ecr_repository.this,
    aws_lb_target_group.this
  ]
}