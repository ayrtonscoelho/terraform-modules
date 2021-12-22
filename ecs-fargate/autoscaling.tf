resource "aws_appautoscaling_target" "this" {
  count              = length(var.autoscaling_settings) 
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.autoscaling_settings[count.index].min_tasks
  max_capacity       = var.autoscaling_settings[count.index].max_tasks

  depends_on = [aws_ecs_service.this]
}


resource "aws_appautoscaling_policy" "this" {
  count = length(var.autoscaling_settings) 
  name  = "ECS_${var.autoscaling_settings[count.index].target}"

  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.this[count.index].resource_id
  service_namespace  = aws_appautoscaling_target.this[count.index].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[count.index].scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.metric_types[var.autoscaling_settings[count.index].metric_type]
    }

    target_value       = var.autoscaling_settings[count.index].target
    scale_in_cooldown  = try(var.autoscaling_settings[count.index].scale_in_cooldown, 120)
    scale_out_cooldown = try(var.autoscaling_settings[count.index].scale_out_cooldown, 300)
    disable_scale_in   = try(var.autoscaling_settings[count.index].disable_scale_in, false)
  }

  depends_on = [aws_appautoscaling_target.this]
}