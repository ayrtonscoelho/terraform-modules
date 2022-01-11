#Target group padrão
resource "aws_lb_target_group" "this" {
  count = var.enable_lb == true ? 1 : 0

	name     		= var.custom_tg_name == null ? "tg-${var.service_name}" : var.custom_tg_name
	port     		= var.service_port
	protocol 		= var.health_check_settings.protocol
	vpc_id      = var.network_settings.vpc_id
	target_type = var.health_check_settings.protocol == "TCP" ? "instance" : "ip"

	dynamic "health_check" {
    for_each = local.health_check_settings[*]
    content {
		  interval = local.health_check_settings.interval
		  timeout  = local.health_check_settings.timeout
		  matcher  = local.health_check_settings.matcher
		  path     = local.health_check_settings.path
		  port     = local.health_check_settings.port
		  protocol = local.health_check_settings.protocol
		  unhealthy_threshold = local.health_check_settings.unhealthy_threshold
		  healthy_threshold   = local.health_check_settings.healthy_threshold
    }
	}

  dynamic "stickiness" {
    for_each = var.health_check_settings.protocol == "TCP" ? [] : [{}]
    content {
      type    = "lb_cookie"
      enabled = false
    }
  }
}

#Condicionais para diferenciar os tipos de health check
locals {
  health_check_settings = {
    interval = var.health_check_settings.interval
    timeout  = var.health_check_settings.protocol != "TCP" ? var.health_check_settings.timeout : null
    matcher  = var.health_check_settings.protocol != "TCP" ? "200-499" : null 
    path     = var.health_check_settings.protocol != "TCP" ? var.health_check_settings.path : null 
    port     = var.health_check_settings.protocol != "TCP" ? "traffic-port" : null 
    protocol = var.health_check_settings.protocol
    healthy_threshold   = var.health_check_settings.protocol != "TCP" ? var.health_check_settings.healthy_threshold : var.health_check_settings.unhealthy_threshold
    unhealthy_threshold = var.health_check_settings.unhealthy_threshold
  }
}

#Lê informações sobre o ALB 
data "aws_lb" "this" {
  count = var.enable_lb == true ? length(var.alb_rules) : 0

  arn   = var.alb_rules[count.index].alb_arn
}

data "aws_lb_listener" "https" {
  count = var.enable_lb == true ? length(var.alb_rules) : 0

  load_balancer_arn = data.aws_lb.this[count.index].arn
  port              = 443
}

#Regras do ALB Listener
resource "aws_lb_listener_rule" "this" {
  count = (var.health_check_settings.protocol != "TCP" && var.enable_lb == true) ? length(var.alb_rules) : 0

  listener_arn = var.health_check_settings.protocol != "TCP" ? data.aws_lb_listener.https[count.index].arn : null

  dynamic "condition" {
    for_each = var.alb_rules != null ? var.alb_rules : []
    content {
      path_pattern {
        values = var.alb_rules[count.index].path[*]
      }
    }
  } 

  dynamic "condition" {
    for_each = var.alb_rules != null ? var.alb_rules : []
    content {
      host_header {
        values = var.alb_rules[count.index].host[*]
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.0.arn
  }

  depends_on = [aws_lb_target_group.this]
}

##Regras do NLB Listener
resource "aws_lb_listener" "this_tcp" {
  count             = (var.health_check_settings.protocol == "TCP" && var.enable_lb == true) ? length(var.nlb_rules) : 0

  load_balancer_arn = var.nlb_rules[count.index].nlb_arn
  port              = var.nlb_rules[count.index].listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.0.arn
  }
}