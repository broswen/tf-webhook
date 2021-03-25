### Durable Webhook
Durable webhook Terraform module using AWS


#### Usage
```
module "webhook" {
  source = "github.com/broswen/tf-webhook"
  name   = "pidgin"
  path   = "/pidgin"
  stage  = "dev"
  method = "POST"
}
```
