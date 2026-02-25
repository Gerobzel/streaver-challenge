terraform {
  required_version = "~> 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.33"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "streaver-ch-tfstate"
    key            = "app-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "streaver-ch-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
