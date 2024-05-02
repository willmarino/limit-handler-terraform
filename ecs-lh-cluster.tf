resource "aws_ecs_cluster" "limit_handler" {
  name = "${var.env}-${var.limit_handler_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
