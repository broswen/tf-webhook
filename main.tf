resource "aws_sqs_queue" "event_queue" {
  name                       = "${var.name}-${var.stage}-events"
  message_retention_seconds  = var.retention_period
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq_queue.arn,
    maxReceiveCount     = 1
  })

}

resource "aws_sqs_queue_policy" "event_queue_policy" {
  queue_url = aws_sqs_queue.event_queue.id
  policy    = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "sqs:SendMessage",
            "Resource": "${aws_sqs_queue.event_queue.arn}"
        }
    ]
}
POLICY
}

resource "aws_sqs_queue" "dlq_queue" {
  name                      = "${var.name}-${var.stage}-dlq"
  message_retention_seconds = var.retention_period
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.name}-${var.stage}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "http_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "${var.method} ${var.path}"

  target = "integrations/${aws_apigatewayv2_integration.http_integration.id}"
}

resource "aws_apigatewayv2_integration" "http_integration" {
  api_id              = aws_apigatewayv2_api.http_api.id
  integration_type    = "AWS_PROXY"
  integration_subtype = "EventBridge-PutEvents"
  credentials_arn     = aws_iam_role.http_integration_role.arn


  request_parameters = {
    "Source"       = "${var.name}-${var.stage}"
    "DetailType"   = "webhook"
    "Detail"       = "$request.body"
    "EventBusName" = "${var.name}-${var.stage}-bus"
  }

  payload_format_version = "1.0"
  timeout_milliseconds   = 5000
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id = aws_apigatewayv2_api.http_api.id
  name   = var.stage
}

resource "aws_apigatewayv2_deployment" "api_deployment" {
  depends_on = [
    aws_apigatewayv2_route.http_route
  ]

  api_id = aws_apigatewayv2_api.http_api.id

  triggers = {
    redeployment = sha1(join(",", list(
      jsonencode(aws_apigatewayv2_integration.http_integration),
      jsonencode(aws_apigatewayv2_route.http_route)
    )))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_cloudwatch_event_bus" "event_bus" {
  name = "${var.name}-${var.stage}-bus"
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  depends_on = [
    aws_cloudwatch_event_bus.event_bus
  ]
  name           = "${var.name}-${var.stage}-rule"
  event_bus_name = "${var.name}-${var.stage}-bus"

  event_pattern = <<EOF
  {
      "source": [
          "${var.name}-${var.stage}"
      ],
      "detail-type": [
          "webhook"
      ]
  }
EOF
}

resource "aws_cloudwatch_event_target" "event_target" {
  depends_on = [
    aws_cloudwatch_event_bus.event_bus
  ]
  target_id      = "${var.name}-${var.stage}-target"
  event_bus_name = "${var.name}-${var.stage}-bus"
  rule           = aws_cloudwatch_event_rule.event_rule.name
  arn            = aws_sqs_queue.event_queue.arn
}

resource "aws_iam_role" "http_integration_role" {
  name               = "${var.name}-${var.stage}-http-integration-role"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "apigateway.amazonaws.com"
            }
        }
    ]
}
POLICY

  inline_policy {
    name   = "inline"
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "events:*",
            "Resource": "${aws_cloudwatch_event_bus.event_bus.arn}"
        }
    ]
}
POLICY

  }

}
