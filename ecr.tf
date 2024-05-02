resource "aws_ecr_repository" "limit_handler" {
  name                 = "${var.env}-${var.limit_handler_name}"
  image_tag_mutability = "MUTABLE" // need this so the latest image can be set as "latest", and older versions can be revised

  image_scanning_configuration {
    scan_on_push = true
  }
}
