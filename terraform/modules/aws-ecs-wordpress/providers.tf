terraform {
  required_providers {
	aws = {
	  source  = "hashicorp/aws"
	  version = "~> 5.6.0"
	}

	random = {
	  source  = "hashicorp/random"
	  version = "~> 3.1.0"
	}
  }
}

provider "aws" {
  region = var.region
}
