// Security group for limit handler load balancer
resource "aws_security_group" "limit_handler_web_alb" {
  name   = "${var.env}-${var.limit_handler_web_name}-lb-sg"
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
resource "aws_security_group" "limit_handler_web" {
  name   = "${var.env}-${var.limit_handler_web_name}-ecs-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 5050
    to_port         = 5050
    security_groups = [aws_security_group.limit_handler_web_alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Load balancer sits in public subnets and is accessible by anyone, forwards traffic http listener --> https listener --> target group
resource "aws_lb" "limit_handler_web" {
  name               = "${var.env}-${var.limit_handler_web_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.limit_handler_web_alb.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
}

// Target group houses servers
resource "aws_alb_target_group" "limit_handler_web" {
  name        = "${var.env}-${var.limit_handler_web_name}-lbtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path = "/server_health/check"
  }
}

// redirect http traffic to https listener
resource "aws_alb_listener" "limit_handler_web_http" {
  load_balancer_arn = aws_lb.limit_handler_web.id
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
resource "aws_alb_listener" "limit_handler_web_https" {
  load_balancer_arn = aws_lb.limit_handler_web.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cf_origin.arn

  default_action {
    target_group_arn = aws_alb_target_group.limit_handler_web.id
    type             = "forward"
  }
}

// Limit handler task definition
resource "aws_ecs_task_definition" "limit_handler_web" {
  family                   = "${var.env}-${var.limit_handler_web_name}-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.lh_task_execution_role.arn
  task_role_arn            = aws_iam_role.lh_task_role.arn

  container_definitions = jsonencode([
    {
      name    = "${var.env}-${var.limit_handler_web_name}-container"
      image   = "${aws_ecr_repository.limit_handler.repository_url}:latest"
      command = ["npm", "run", "web"]

      essential = true

      logConfiguration = {
        logDriver = "awsfirelens",
        options = {
          Name       = "datadog"
          apikey     = var.datadog_api_key
          dd_service = var.limit_handler_web_name
          dd_source  = "node"
          dd_tags    = "env:${var.env}"
          TLS        = "on"
          provider   = "ecs"
        }
      }

      environmentFiles = [{
        value = "arn:aws:s3:::lh-${var.env}-env-files/${var.limit_handler_name}.env",
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

      essential = true
      image     = "amazon/aws-for-fluent-bit:latest"
      name      = "${var.env}-${var.limit_handler_web_name}-log-router"

      firelensConfiguration = {
        type = "fluentbit",
        options = {
          enable-ecs-log-metadata = "true"
        }
      }

    }
  ])

  lifecycle {
    ignore_changes = [container_definitions]
    # ignore_changes = []
  }
}

resource "aws_ecs_service" "limit_handler_web" {
  name                               = "${var.env}-${var.limit_handler_web_name}-ecs-service"
  cluster                            = aws_ecs_cluster.limit_handler.id
  task_definition                    = aws_ecs_task_definition.limit_handler_web.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  enable_execute_command = true

  network_configuration {
    security_groups = [aws_security_group.limit_handler_web.id]
    subnets         = module.vpc.private_subnets
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.limit_handler_web.arn
    container_name   = "${var.env}-${var.limit_handler_web_name}-container"
    container_port   = 5050
  }
}
