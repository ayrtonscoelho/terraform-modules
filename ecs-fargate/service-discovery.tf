resource "aws_service_discovery_service" "this" {
  count = var.namespace_settings != null ? 1 : 0
  name  = var.service_name

  dns_config {
    namespace_id   = var.namespace_settings.namespace_id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = var.namespace_settings.dns_ttl
      type = "A"
    }

    dns_records {
      ttl  = var.namespace_settings.dns_ttl
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = var.health_check_settings.unhealthy_threshold
  }
}

