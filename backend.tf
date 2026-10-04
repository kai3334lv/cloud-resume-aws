# 1. DynamoDB Table
resource "aws_dynamodb_table" "visitor_table" {
  name         = "cloud-resume-challenge-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project   = "CloudResumeChallenge"
    ManagedBy = "Terraform"
  }
}

# 2. IAM Role & Policy for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "resume_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda_dynamodb_policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["dynamodb:UpdateItem", "dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.visitor_table.arn
      },
      {
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 3. Package and Create the Lambda Function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "visitor_counter" {
  filename         = "lambda_function.zip"
  function_name    = "ResumeVisitorCounter"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# 4. API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "ResumeCounterAPI"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"] 
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.visitor_counter.invoke_arn
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true
}

# 5. Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# 6. Output the API URL to the console
output "api_url" {
  description = "Copy this URL into your counter.js file"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/prod/count"
}