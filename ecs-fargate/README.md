# **AWS ECS Fargate Terraform module**

Módulo Terraform para criar serviços no [ECS Fargate](https://docs.aws.amazon.com/pt_br/AmazonECS/latest/developerguide/AWS_Fargate.html) na AWS.

&nbsp;



#### Features

---

Este módulo visa implementar as combinações de recursos da AWS necessários para executar um serviço ECS Fargate com êxito.

- ECS Service✅
- ECR✅
- Task Definition✅
- CloudWatch Logs✅
- Autoscaling✅
- Target Group✅
- Security Group✅
- Service Discovery(CloudMap)✅

&nbsp;



#### Requirements

---
Para o desenvolvimento do módulo foi utilizado a versão 1.0.7.


| Name        | Version |
| ----------- | ----------- |
| [Terraform](https://www.terraform.io/) | >= 0.13 |
| [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)   | >= 3.0 | 



&nbsp;



#### Uso

---

O bloco de código abaixo é um exemplo completo atendendo todos as *features* do módulo, para saber quais são obrigatórias e opcionais consulte o tópico de ***inputs***.

```
module "demo_service" {
  source = "github.com/ayrtonscoelho/terraform-modules//ecs-fargate"

  #Service settings
  service_name   = "demo-service"
  service_port   = 3000
  service_cpu    = 512
  service_memory = 1024
  cluster_name   = module.ecs_cluster.name
  iam_role       = aws_iam_role.ecs_service.arn

  network_settings = {
    vpc_id          = module.main_vpc.vpc_id
    subnet_ids      = module.main_vpc.private_subnets
    security_groups = module.sg_services.id[*]
    public_ip       = false
  }

  health_check_settings = {
    path      = "/health_check"
    protocol  = "HTTP"
    timeout   = 60
    interval  = 65
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  service_environment = [
    {
      name  = "NEW_RELIC_APP_NAME"
      value = "demo-service"
    }
  ]

  service_secrets = [
    {
      name      = "NEW_RELIC_LICENSE_KEY"
      valueFrom = module.parameter_nr_license.arn
    }
  ]

  namespace_settings = {
    namespace_id = module.service_discovery_namespace.id
    dns_ttl      = 10
  }

  alb_rules = [
    {
      path    = "/*"
      host    = "demo.${local.workspace.domain_fqn}"
      alb_arn = module.external_alb.arn
    }
  ]

  autoscaling_settings = {
    min_tasks   = 1
    max_tasks   = 5

    rules = [
      {
        target = 70
        metric_type = "CPU"
      },
      {
        target = 70
        metric_type = "RAM"
      }
    ]
  }
}
```

&nbsp;



#### Resources and Datas

---

| Name        | Type |
| :-----------: | :-----------: |
| aws_ecs_service.this | Resource|
| aws_ecs_task_definition.this | Resource|
| aws_lb_target_group.this | Resource|
| aws_lb_listener_rule.this | Resource|
| aws_lb_listener.this_tcp | Resource|
| aws_service_discovery_service.this | Resource|
| aws_security_group.this | Resource|
| aws_security_group_rule.this | Resource|
| aws_ecr_repository.this | Resource|
| aws_cloudwatch_log_group.this | Resource|
| aws_appautoscaling_target.this | Resource|
| aws_appautoscaling_policy.this | Resource|
| aws_caller_identity.this | Data|
| aws_region.this | Data|
| template_file.this | Data|
| aws_ecs_task_definition.this | Data|

&nbsp;



#### Inputs

---

| Name    | Description | Type  | Required/Optional | Default |
| :---:        |    :----:   |          :---: |          :---: | :--- |
| service_name | Nome do serviço ECS       | string    | Required  | null |
| service_port | Porta HTTP em que o serviço ECS executará       | number    | Required  | null |
| cluster_name | Cluster ECS no qual o serviço será criado       | string    | Required  | null |
| network_settings | Configurações de rede necessárias para o funcionamento  | object({}) | Required  | null |
| desired_count | Quantidade desejada de tasks executando | number| Optional  | 1|
| platform_version | Versão da plataforma ECS Fargate | string| Optional  | 1.4.0|
| enable_lb | Habilita/Desabilita a criação de recursos relacionados a ALB | bool| Optional  | true |
| enable_sd | Habilita/Desabilita a criação de registros no Service Discovery/Cloudmap | bool| Optional  | true |
| healthcheck_grace_period | Tempo em segundos para que o processo de *health check* se inicie | number| Optional  | 60 |
| deployment_settings | Estratégia de Rolling Update | object({}) | Optional  | ```   default = { maximum_percent = 200 minimum_percent = 100 } ``` |
| custom_tgs | Atacha target group extras ao serviço | list(object({}))| Optional  | [] |
| capacity_provider | Regras do provedor de capacidade | list(object({}))| Optional  | ```   default = { type = "FARGATE" weight = 2 base =  1}, { type = "FARGATE_SPOT", weight = 1, base =  0 } ```  |
| health_check_settings | Configurações de *health check* | object({})    | Required  | null|
| alb_rules | Lista de regras para o listener do ALB | list(object({}))    | Optional  | null |
| nlb_rules | Lista de regras para o listener do NLB | list(object({}))    | Optional  | null |
| ecr_url | Caso queira usar uma imagem já existente no ECR e não criar um específico para o serviço | string    | Optional  | null |
| log_retention | Tempo em dias que os logs são retidos no CloudWatch | number    | Optional  | 30 |
| autoscaling_settings | Regras de scaling por métricas CPU e RAM | object({number, list(object({}))})    | Optional  | null |
| namespace_settings | Configurações do Service Discovery/CloudMap | object({})    | Optional  | null |
| service_memory| Quantidade de memória RAM em megabytes para o serviço ECS | number | Required  | null |
| service_cpu | Quantidade de CPU para o serviço ECS | number | Required  | null |
| iam_role | IAM Role que concede as permissões necessárias na cloud que o seu serviço precisar | string | Required  | null |
| network_mode | Modo de rede em que o ECS Fargate executará | string | Optional  | awsvpc |
| service_mountpoints | Configuração de pontos de montagem para task definition | list(object({})) | Optional  | [] |
| service_ulimits | Configuração de ulimits para o serviço | list(object({})) | Optional  | [] |
| service_entrypoint | Configuração de entrypoint para a task definition | list(string)) | Optional  | [] |
| service_command | Configuração de comando inicial para a task definition | list(string)) | Optional  | [] |
| service_environment | Configuração variáveis de ambiente para o serviço | list(object({}))) | Optional  | [] |
| service_secrets | Configuração segredos para o serviço | list(object({}))) | Optional  | [] |
| healthcheck_task_timeout | Timeout específico do *health check* da task definition |number | Optional  | null |
| service_health_check | Configurações de *health check* do target group |object({}) | Optional  | ```   default = { command = "exit 0" start = 30 timeout  = 60 interval = 61 retries  = 3} ``` |
| sg_rules | Regras para o security group específico do serviço | list(any) | Optional  | [] |

&nbsp;



#### Outputs

---

| Name        | Description |
| ----------- | ----------- |
| service_name | Nome do serviço ECS|
| service_arn | ARN do serviço ECS|
| service_cluster | Cluster ECS em que o serviço está contido|
| service_iam | ARN da IAM Role do serviço ECS|
| task_arn | ARN da task definition do serviço ECS|
| task_revision | Revisão da task definition do serviço ECS|
| ecr_arn | ARN do repositório ECR que contém a imagem que o serviço ECS executa |
| ecr_id | ID do repositório ECR que contém a imagem que o serviço ECS executa |
| ecr_uri | URI do repositório ECR que contém a imagem que o serviço ECS executa |
| target_group_arn | ARN do target group associado ao serviço ECS |
| target_group_arn_suffix | ARN Suffix do target group associado ao serviço ECS |
| target_group_name | Nome do target group associado ao serviço ECS |
| log_arn | ARN do log group do serviço ECS |