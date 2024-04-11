// Security group for limit handler load balancer
resource "aws_security_group" "limit_handler_alb" {
  name   = "${var.env}-${var.limit-handler-name}-lb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// LH api server security group, only takes in traffic from infra under the ALB security group
resource "aws_security_group" "limit_handler" {
  name   = "${var.env}-${var.limit-handler-name}-ecs-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 5050
    to_port         = 5050
    security_groups = [aws_security_group.limit_handler_alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Load balancer sits in public subnets and is accessible by anyone, forwards traffic http listener --> https listener --> target group
resource "aws_lb" "limit_handler" {
  name               = "${var.env}-${var.limit-handler-name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.limit_handler_alb.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
}

// Target group houses servers
resource "aws_alb_target_group" "service" {
  name        = "${var.env}-${var.limit-handler-name}-lbtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path = "/server_health/check"
  }
}

// redirect http traffic to https listener
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.limit_handler.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

// redirect https traffic to target group
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.limit_handler.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cf_origin.arn

  default_action {
    target_group_arn = aws_alb_target_group.service.id
    type             = "forward"
  }
}

// Limit handler task definition
resource "aws_ecs_task_definition" "limit_handler" {
  family                   = "${var.env}-${var.limit-handler-name}-ecs-task"
  network_mode             = "vpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = module.iam.lh_task_execution_role
  task_role_arn            = module.iam.lh_task_role

  container_definitions = jsonencode([{
    name    = "${var.env}-${var.limit-handler-name}-container"
    image   = "${module.ecr["${var.env}-limit-handler"].repository_url}:latest"
    command = ["node", "app.js"]

    essential = true

    logConfiguration = {
      logDriver = "awsfirelens",
      options = {
        # https://docs.datadoghq.com/integrations/fluentbit/#configuration-parameters
        Name           = "datadog"
        Host           = "http-intake.logs.us5.datadoghq.com"
        compress       = "gzip"
        TLS            = "on"
        apikey         = var.datadog_api_key
        dd_service     = "limit-handler"
        dd_source      = "limit-handler"
        dd_message_key = "log"
        dd_tags        = "env:${var.env}"
        provider       = "ecs"
      }
    }

    environmentFiles = [{
      value = "arn:aws:s3:::lh-${var.env}-env-files/${var.limit-handler-name}.env",
      type  = "s3"
    }]

    linuxParameters = {
      initProcessEnabled = true
    }

    portMappings = [{
      protocol      = "tcp"
      containerPort = 5050
    }]
    }, {
    image     = "amazon/aws-for-fluent-bit:stable"
    name      = "${var.env}-${var.limit-handler-name}-log-router"
    essential = true

    memoryReservation = 50

    firelensConfiguration = {
      type = "fluentbit",
      options = {
        enable-ecs-log-metadata = "true"
      }
    }
    }, {
    name      = "${var.env}-${var.limit-handler-name}-container-datadog"
    image     = "public.ecr.aws/datadog/agent:latest"
    essential = true

    environment = [
      { name = DD_TAGS, value = "env:${var.env}" }
    ]

    portMappings = [{
      protocol      = "udp",
      containerPort = 8125
    }]
  }])

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_cluster" "limit_handler" {
  name = "${var.env}-${var.limit-handler-name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "limit_handler" {
  name                               = "${var.env}-${var.limit-handler-name}-ecs-service"
  cluster                            = aws_ecs_cluster.limit_handler.id
  task_definition                    = aws_ecs_task_definition.limit_handler.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  # Enable ECS Exec
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html
  enable_execute_command = true

  network_configuration {
    security_groups = [aws_security_group.limit_handler.id]
    subnets         = module.vpc.private_subnets
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.service.arn
    container_name   = "${var.env}-${var.limit-handler-name}-container"
    container_port   = 5050
  }
}
