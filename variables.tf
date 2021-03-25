variable "name" {
  type        = string
  description = "Name of the webhook"
}

variable "stage" {
  type        = string
  description = "The stage of the webhook"
  default     = "dev"
}

variable "path" {
  type        = string
  description = "Path of the webook, must start with / and be a valid path"
  validation {
    condition     = can(regex("^/\\w*", var.path))
    error_message = "Does the path start with / and is a path?"
  }
}

variable "method" {
  type        = string
  description = "The method to use for the webhook"
  default     = "POST"
  validation {
    condition     = can(regex("^(GET|PUT|POST|DELETE)$", var.method))
    error_message = "Is the method GET, PUT, POST, or DELETE ?"
  }
}

variable "retention_period" {
  type        = number
  description = "Number of seconds to retain events in the SQS Queue"
  default     = 345600
  validation {
    condition     = var.retention_period > 60 && var.retention_period < 1209600
    error_message = "Is the retention period between 60 and 1209600?"
  }
}
