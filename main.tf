resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
			 {
      "Action": "dynamodb:*",
			"Resource": "${aws_dynamodb_table.main.arn}",
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": "kms:*",
			"Resource": "${aws_kms_key.ddb.arn}",
      "Effect": "Allow",
      "Sid": ""
    },
		 {
      "Action": "logs:*",
			"Resource": "*",
      "Effect": "Allow",
      "Sid": ""
    }
    ]
  }
  EOF
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.test_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "output/lambda.zip"
  function_name = "Denis_lambda"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "lambda_handler.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("output/lambda.zip")}"

  runtime = "python3.7"

  environment {
    variables = {
      DB_NAME = "${aws_dynamodb_table.main.name}"
    }
  }
}

resource "aws_kms_key" "ddb" {
  description             = "KMS for encrypting DDB for DOA exercise"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "a" {
  name          = "alias/ddb-devopsacademy-serverless01"
  target_key_id = "${aws_kms_key.ddb.key_id}"
}

resource "aws_dynamodb_table" "main" {
  name           = "Customers"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "firstname"

  server_side_encryption {
    enabled = true
    kms_key_arn = "${aws_kms_key.ddb.arn}"
  }

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "firstname"
    type = "S"
  }

}

resource "aws_apigatewayv2_api" "main" {
  name                       = "doa-customers-api"
  protocol_type              = "HTTP"
}

resource "aws_apigatewayv2_integration" "example" {
  api_id           = "${aws_apigatewayv2_api.main.id}"
  integration_type = "AWS_PROXY"

  connection_type           = "INTERNET"
  description               = "Lambda example"
  integration_method        = "POST"
  integration_uri           = "${aws_lambda_function.test_lambda.invoke_arn}"
}

resource "aws_apigatewayv2_route" "main" {
  api_id    = "${aws_apigatewayv2_api.main.id}"
  route_key = "POST /customers"
	operation_name = "create_customer"
	target = "integrations/${aws_apigatewayv2_integration.example.id}"
}

resource "aws_apigatewayv2_stage" "main" {
  api_id = "${aws_apigatewayv2_api.main.id}"
  name   = "default"
	auto_deploy = true


  lifecycle {
    ignore_changes = [
      default_route_settings,
    ]
  }
}