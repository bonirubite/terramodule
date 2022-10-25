

terraform {
        backend "s3" {
        bucket = "bonis-terraform-up-and-running"
        key = "modules/services/webserver-cluster/terraform.tfstate"
        region = "ap-southeast-2"
        dynamodb_table = "boni-terraform-up-and-running-locks"
        encrypt = "true"
          }
        }
