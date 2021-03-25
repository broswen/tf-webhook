output "http_api_id" {
  description = "ID of the HTTP API"
  value       = aws_apigatewayv2_api.http_api.id
}

output "http_api_endpoint" {
  description = "Endpoint of the HTTP API"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "event_queue_url" {
  description = "Queue URL for the SQS event queue"
  value       = aws_sqs_queue.event_queue.id
}

output "event_queue_arn" {
  description = "Queue ARN for the SQS event queue"
  value       = aws_sqs_queue.event_queue.arn
}

output "dlq_queue_url" {
  description = "Queue URL for the SQS DLQ queue"
  value       = aws_sqs_queue.event_dlq.id
}

output "dlq_queue_arn" {
  description = "Queue ARN for the SQS DLQ queue"
  value       = aws_sqs_queue.event_dlq.arn
}

output "event_bus_name" {
  description = "Name of the custom event bus"
  value       = "${var.name}-${var.stage}-bus"
}
