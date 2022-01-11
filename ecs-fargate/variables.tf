##REVER
variable "deregistration_delay" { default = 300 }

##SERVICE VARS

#Required
variable "service_name" {}

variable "service_port" {}

variable "cluster_name" {}

variable "network_settings" {
  type = object({
    security_groups = list(string)
    subnet_ids      = list(string)
    vpc_id          = string
    public_ip       = bool
  })
}

#Optional
variable "desired_count" { default = 1 }

variable "platform_version" { default = "1.4.0" }

variable "tg_protocol" { default = "TCP" }

variable "enable_lb" { default = true }

variable "enable_sd" { default = true }

variable "healthcheck_grace_period" { default = 60 }

variable "deployment_settings" {
  type = object({
    maximum_percent = number
    minimum_percent = number
  })

  default = {
    maximum_percent = 200
    minimum_percent = 100
  }
}

variable "custom_tgs" {
  type = list(object({
    target_arn     = string
    container_name = string
    container_port = string
  }))

  default = []
}

variable "capacity_provider" {
  type = list(object({
    type     = string
    weight   = number
    base     = number
  }))

  default = [
    {
      type   = "FARGATE",
      weight = 2,
      base   = 1
    },
    {
      type   = "FARGATE_SPOT",
      weight = 1,
      base   = 0
    }
  ]
}



##TARGET GROUP VARS

#Required
variable "health_check_settings" {
  type = object({
    interval            = number
    healthy_threshold   = number
    unhealthy_threshold = number
    timeout             = number
    path                = string
    protocol            = string
  })
}

#Optional
variable "custom_tg_name" { default = null }
variable "custom_tg_port" { default = null }



##ALB VARS

#Optional
variable "alb_rules" {
  type = list(object({
    alb_arn = string
    path    = string
    host    = string
  }))

  default = null
}



##NLB VARS

#Optional
variable "nlb_rules" {
  type = list(object({
    nlb_arn       = string
    listener_port = number
  }))

  default = null
}



##ECR VARS

#Optional
variable "ecr_url" { default = null }



##CLOUDWATCH VARS

#Optional
variable "log_retention" { default = 7 }



##AUTOSCALING VARS

#Optional
variable "autoscaling_settings" {
  type = list(object({
    min_tasks   = number
    max_tasks   = number
    target      = number
    metric_type = string
  }))

  default = []
}

variable "metric_types" {
  default = {
    CPU = "ECSServiceAverageCPUUtilization"
    RAM = "ECSServiceAverageMemoryUtilization"
  }
}



##NAMESPACE VARS

#Optional
variable "namespace_settings" {
  type = object({
    namespace_id   = string
    dns_ttl        = number
  })

  default = null
}



##TASK DEFINITION VARS

#Required
variable "service_memory" {}
variable "service_cpu" {}
variable "iam_role" {}

#Optional
variable "network_mode" { default = "awsvpc" }

variable "service_mountpoints" {
  type        = list(any)
  default     = []
}

variable "service_ulimits" {
  type        = list(any)
  default     = []
}

variable "service_entrypoint" {
  type        = list(string)
  default     = []
}

variable "service_command" {
  type        = list(string)
  default     = []
}

variable "service_environment" {
  type        = list(any)
  default     = []
}

variable "service_extra_ports" {
  type        = list(any)
  default  = []
}

variable "service_secrets" {
  type        = list(any)
  default     = []
}

variable "healthcheck_task_timeout" { default = null }

variable "region" { default = null }

variable "service_health_check" {
  type = object({
    command  = string
    timeout  = number
    start    = number
    interval = number
    retries  = number
  })

  default = {
    command  = "exit 0"
    start    = 30
    timeout  = 60
    interval = 61
    retries  = 3
  }
}