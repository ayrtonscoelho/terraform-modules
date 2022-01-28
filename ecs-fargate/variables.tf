##SERVICE VARS

#Required
variable "service_name" {
  type = string
  validation {
    condition     = can(regex("[[:alpha:]]", var.service_name)) == true
    error_message = "[ERROR]::: A variável 'service_name' deve ser do tipo String."
  }
}

variable "service_port" {
  type = number
  validation {
    condition     = can(regex("[[:digit:]]", var.service_port)) == true
    error_message = "[ERROR]::: A variável 'service_port' deve ser do tipo Number."
  }
}

variable "cluster_name" {
  type = string
  validation {
    condition     = can(regex("[[:alpha:]]", var.cluster_name)) == true
    error_message = "[ERROR]::: A variável 'cluster_name' deve ser do tipo String."
  }
}

variable "network_settings" {
  type = object({
    security_groups = list(string)
    subnet_ids      = list(string)
    vpc_id          = string
    public_ip       = bool
  })
}

#Optional
variable "desired_count" { 
  default = 1 
  validation {
    condition     = can(regex("[[:digit:]]", var.desired_count)) == true
    error_message = "[ERROR]::: A variável 'desired_count' deve ser do tipo Number."
  }
}

variable "platform_version" { 
  default = "1.4.0"
  validation {
    condition     = var.platform_version == "1.4.0" || var.platform_version == "1.3.0"
    error_message = "[ERROR]::: O valor inserido para 'platform_version' não é válido, deve ser '1.4.0'."
  }
}

variable "enable_lb" {
  default = true 
  validation {
    condition     = can(tobool(var.enable_lb)) == true
    error_message = "[ERROR]::: A variável 'enable_lb' deve ser do tipo Boolean(true or false)."
  }

}

variable "enable_sd" { 
  default = true 
  validation {
    condition     = can(tobool(var.enable_sd)) == true
    error_message = "[ERROR]::: A variável 'enable_sd' deve ser do tipo Boolean(true or false)."
  }

}

variable "healthcheck_grace_period" { 
  default = 60
  validation {
    condition     = can(regex("[[:digit:]]", var.healthcheck_grace_period)) == true
    error_message = "[ERROR]::: A variável 'healthcheck_grace_period' deve ser do tipo Number."
  }
}

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
variable "custom_tg_name" { 
  default = null 
  validation {
    condition     = var.custom_tg_name == null || can(regex("[[:alpha:]]", var.custom_tg_name)) == true
    error_message = "[ERROR]::: A variável 'custom_tg_name' deve ser do tipo String."
  }
}

variable "custom_tg_port" { 
  default = null 
  validation {
    condition     = var.custom_tg_port == null || can(regex("[[:digit:]]", var.custom_tg_port)) == true
    error_message = "[ERROR]::: A variável 'custom_tg_port' deve ser do tipo Number."
  }
 }



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
variable "ecr_url" { 
  default = null 
  validation {
    condition     = var.ecr_url == null || can(regex("([0-9]{12}).dkr.ecr.((us|sa|af|ap|ca|eu|me|)-east-(1|2|3)).amazonaws.com/([a-z,A-Z,_,-,0-9]{1,256})", var.ecr_url))
    error_message = "[ERROR]::: A variável 'ecr_url' deve ser do tipo String."
  }
}



##CLOUDWATCH VARS

#Optional
variable "log_retention" { 
  default = 30
  validation {
    condition     = can(regex("[[:digit:]]", var.log_retention)) == true
    error_message = "[ERROR]::: A variável 'log_retention' deve ser do tipo Number."
  }
}



##AUTOSCALING VARS

#Optional
variable "autoscaling_settings" {
  type = object({
    min_tasks   = number
    max_tasks   = number
    rules = list(object({
      target      = number
      metric_type = string
    }))
  })

  default = null
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
variable "service_memory" {
  validation {
    condition     = can(regex("[[:digit:]]", var.service_memory)) == true
    error_message = "[ERROR]::: A variável 'service_memory' deve ser do tipo Number."
  }
}
variable "service_cpu" {
  validation {
    condition     = can(regex("[[:digit:]]", var.service_cpu)) == true
    error_message = "[ERROR]::: A variável 'service_cpu' deve ser do tipo Number."
  }
}

variable "iam_role" {
  validation {
    condition     = var.iam_role == null || can(regex("arn:aws:iam::([0-9]{12}):role/([a-z,A-Z,_,-,0-9]{1,256})", var.iam_role))
    error_message = "O valor da variável 'iam_role' precisar ser um ARN válido. Exemplo: 'arn:aws:iam:<account-id>:role/<role-name>'."
  }
}

#Optional
variable "network_mode" { 
  default = "awsvpc"
  validation {
    condition     = var.network_mode == "awsvpc" || var.network_mode == "bridge"
    error_message = "[ERROR]::: O valor da variável 'network_mode' deve ser 'awsvpc' ou 'bridge'."
  }
}

variable "service_mountpoints" {
  type = list(object({
    containerPath = string
    sourceVolume  = string
  }))

  default     = []
}

variable "service_ulimits" {
  type = list(object({
    name      = string
    softLimit = number
    hardLimit = number
  }))

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
  type = list(object({
    name  = string
    value = string
  }))

  default = []
}

variable "service_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))

  default = []
}

variable "healthcheck_task_timeout" { 
  default = null
  validation {
    condition     = var.healthcheck_task_timeout == null || can(regex("[[:digit:]]", var.healthcheck_task_timeout)) == true
    error_message = "[ERROR]::: A variável 'healthcheck_task_timeout' deve ser do tipo Number."
  }
}

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



##SECURITY GROUP VARS
variable "sg_rules" {
  type    = list(any)
  default = []
}