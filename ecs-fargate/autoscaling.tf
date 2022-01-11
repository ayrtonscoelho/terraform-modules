resource "aws_appautoscaling_target" "this" {
  count              = var.autoscaling_settings != null ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.autoscaling_settings.min_tasks
  max_capacity       = var.autoscaling_settings.max_tasks

  depends_on = [aws_ecs_service.this]
}

resource "aws_appautoscaling_policy" "this" {
  count = length(var.autoscaling_settings.rules) 
  name  = "ECS_${var.autoscaling_settings.rules[count.index].metric_type}_${var.autoscaling_settings.rules[count.index].target}"

  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.this.0.resource_id
  service_namespace  = aws_appautoscaling_target.this.0.service_namespace
  scalable_dimension = aws_appautoscaling_target.this.0.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.metric_types[var.autoscaling_settings.rules[count.index].metric_type]
    }

    target_value       = var.autoscaling_settings.rules[count.index].target
    scale_in_cooldown  = try(var.autoscaling_settings.rules[count.index].scale_in_cooldown, 120)
    scale_out_cooldown = try(var.autoscaling_settings.rules[count.index].scale_out_cooldown, 300)
    disable_scale_in   = try(var.autoscaling_settings.rules[count.index].disable_scale_in, false)
  }

  depends_on = [aws_appautoscaling_target.this]
}