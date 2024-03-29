resource "aws_iam_user" "gh_actions" {
  name = "gh_actions"
}

resource "aws_iam_access_key" "gh_actions" {
  user = aws_iam_user.gh_actions.name
}

resource "aws_iam_user_policy" "gh_actions" {
  name = "gh_actions_policy"
  user = aws_iam_user.gh_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:GetAuthorizationToken"
        ],
        Effect = "Allow",
        # Resource = "${aws_ecr_repository.limit_handler.arn}"
        Resource = "*"
      }
    ]
  })

}


resource "aws_iam_role" "lh_task_role" {
  name = "limit_handler_ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "limit_handler_ecs_task_inline_policy"

    policy = jsonencode({
      Version : "2012-10-17",
      Statement : [
        {
          Effect : "Allow",
          Action : [
            "ssmmessages:OpenDataChannel",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel"
          ],
          Resource : "*"
        }
      ]
    })
  }


}


