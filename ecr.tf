resource "aws_ecr_repository" "limit_handler" {
  name                 = "${var.env}-limit-handler"
  image_tag_mutability = "MUTABLE" // need this so the latest image can be set as "latest", and older versions can be revised

  image_scanning_configuration {
    scan_on_push = true
  }
}


# resource "aws_ecr_repository_policy" "limit_handler" {
#   repository = aws_ecr_repository.limit_handler.name
#   policy     = data.aws_iam_policy_document.limit_handler.json
# }


# // IAM policy
# data "aws_iam_policy_document" "limit_handler" {
#   statement {
#     sid = "lh allow interactions"

#     actions = [
#       "ecr:BatchCheckLayerAvailability",
#       "ecr:BatchGetImage",
#       "ecr:CompleteLayerUpload",
#       "ecr:GetDownloadUrlForLayer",
#       "ecr:GetLifecyclePolicy",
#       "ecr:InitiateLayerUpload",
#       "ecr:PutImage",
#       "ecr:UploadLayerPart"
#     ]

#     // TODO restrict this to a specific IAM user?
#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }
#   }
# }
