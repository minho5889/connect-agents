# Tool backend: a Lambda that an AgentCore Gateway target exposes as MCP tools.
# Uses hashicorp/aws (well-established resources).

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/.build/tool_backend.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-tool-backend"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "tools" {
  function_name    = "${var.name_prefix}-wealth-tools"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 25 # stay under the 30s MCP tool timeout
  memory_size      = 256
}
