terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}
provider "aws" {
    region = "us-west-2"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = [ "sts.amazonaws.com" ]
    thumbprint_list = ["15e29108718111e59b3dad31954647e3c344a231"]
}

resource "aws_iam_role" "github_actions_role" {
  name = "github_actions_role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_policy_doc.json
  #managed_policy_arns = [ aws_iam_policy.example.arn ]
}

resource "aws_iam_policy" "example" {
    name = "example"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action   = ["s3:*"]
            Effect   = "Allow"
            Resource = "*"
        }]
    })
}

# JSON role policy
data "aws_iam_policy_document" "github_actions_policy_doc" {
    statement {
        sid = "temp"
        effect = "Allow"
        actions = [
            "sts:AssumeRoleWithWebIdentity"
        ]
        #resources = [ "*" ]
        principals {
          type = "Federated"
          identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
        }
        condition {
            test = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values = [
                "repo:dacbd/actions-oidc-poc:*"
            ]
        }
    }
}