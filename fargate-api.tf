// load balander for limit handler api
resource "aws_lb" "limit_handler_api" {
  name               = "${var.env}-limit-handler-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = module.vpc.public_subnets
}

// security group for load balancer for limit handler api
// allows ingress on http and https ports
resource "aws_security_group" "limit_handler_lb" {
  name   = "${var.env}-limit-handler-lb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


// target group for load balancer for limit handler api
resource "aws_alb_target_group" "limit_handler_lb_tg" {
  name        = "${var.env}-limit-handler-lbtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}


// port 80 http listener for target group, redirects traffic to https listener
resource "aws_alb_listener" "lb_http" {
  load_balancer_arn = aws_lb.limit_handler_api.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.limit_handler_lb_tg.id
    type             = "forward"
  }

}


// security group for limit handler api ecs service
resource "aws_security_group" "limit_handler_ecs_service" {
  name   = "${var.env}-limit-handler-ecs-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 5050 // express app port
    to_port         = 5050
    security_groups = [aws_security_group.load_balancer.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


// ecs cluster
resource "aws_ecs_cluster" "limit_handler" {
  name = "${var.env}-limit-handler-ecs-cluster"
}

