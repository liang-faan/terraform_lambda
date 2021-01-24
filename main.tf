provider "aws" {
  region = var.region
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "index.js"
  output_path = "lambda_function.zip"
}


resource "aws_iam_role" "iam" {
  name = "iam_for_lambda_tf"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_iam_policy" {
  # name        = format("%s-trigger-transcoder", local.full_name)
  name        = "lambda_iam_policy"
  description = "Allow to access base resources and trigger transcoder"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SomeVeryDefaultAndOpenActions",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.iam.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

resource "aws_api_gateway_rest_api" "api" {

  name = "HelloTest"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "resource"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  # source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  # depends_on = [aws_api_gateway_integration.integration,aws_api_gateway_integration.lambda_root]
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"
}

# resource "aws_api_gateway_resource" "proxy" {
#    rest_api_id = aws_api_gateway_rest_api.api.id
#    parent_id   = aws_api_gateway_rest_api.api.root_resource_id
#    path_part   = "{proxy+}"
# }

# resource "aws_api_gateway_method" "proxy_root" {
#    rest_api_id   = aws_api_gateway_rest_api.api.id
#    resource_id   = aws_api_gateway_resource.proxy.id
#    http_method   = "ANY"
#    authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "lambda_root" {
#    rest_api_id = aws_api_gateway_rest_api.api.id
#    resource_id = aws_api_gateway_method.proxy_root.resource_id
#    http_method = aws_api_gateway_method.proxy_root.http_method

#    integration_http_method = "POST"
#    type                    = "AWS_PROXY"
#    uri                     = module.lambda.invoke_arn
# }


# resource "aws_lambda_provisioned_concurrency_config" "example" {
#   function_name                     = aws_lambda_alias.example.function_name
#   provisioned_concurrent_executions = 1
#   qualifier                         = aws_lambda_alias.example.name
# }

module "lambda" {
  source = "github.com/terraform-module/terraform-aws-lambda?ref=v2.12.4"

  function_name  = "lambda_test_index"
  filename       = data.archive_file.lambda.output_path
  description    = "description should be here"
  handler        = "index.handler"
  runtime        = "nodejs12.x"
  memory_size    = "128"
  concurrency    = "5"
  lambda_timeout = "20"
  log_retention  = "1"
  role_arn       = aws_iam_role.iam.arn

  # vpc_config = {
  #   subnet_ids         = ["sb-q53asdfasdfasdf", "sf-3asdfasdfasdf6"]
  #   security_group_ids = ["sg-3asdfadsfasdfas"]
  # }

  # environment = {
  #   Environment = "test"
  # }

  tags = {
    environment = "dev"
  }
}