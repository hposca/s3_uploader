variable "aws_region" {
  description = "AWS Region where the cluster and services will be created"
}

variable "product_name" {
  description = "The name of the product"
  default     = "s3_uploader"
}

variable "default_tags" {
  description = "Tags to be applied on all resources"

  default = {
    Terraform = "true"
  }
}
