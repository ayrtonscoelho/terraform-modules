#Cria um security group específico para o serviço.
resource "aws_security_group" "this" {
  name        = "inbound-${var.service_name}-sg"
  description = "Regras inbound do servico ${var.service_name}"
  vpc_id      = var.network_settings.vpc_id

  tags = {
    Name = "inbound-${var.service_name}-sg"
  }
}

resource "aws_security_group_rule" "this" {
  count             = var.sg_rules != [] ? length(var.sg_rules) : 0
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  from_port         = var.sg_rules[count.index].port
  to_port           = var.sg_rules[count.index].port
  cidr_blocks       = var.sg_rules[count.index].origin[*]

  protocol = try(
    var.sg_rules[count.index].protocol, 
    "tcp"
  )

  description = try(
    var.sg_rules[count.index].description, 
    "Managed by ECS Fargate Terraform module - (${var.service_name})"
  )
}