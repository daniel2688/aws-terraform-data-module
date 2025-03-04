provider "aws" {
  region = var.tags["region"]

  default_tags {
    tags = {
      Environment = var.tags["environment"]
      Project     = var.tags["project"]
      Owner       = var.tags["owner"]
      ManagedBy   = "Terraform"
    }
  }
}
