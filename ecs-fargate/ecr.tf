resource "aws_ecr_repository" "this" {
  count = var.ecr_url == null ? 1 : 0
  
  name  = var.service_name

  image_scanning_configuration {
    scan_on_push = true
  }
}