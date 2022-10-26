
variable "server_port" {
        description = "The port web servers will be listening to"
        type = number
        default = 8080
        }

variable "cluster_name" {
	description = "The name to use for all the cluster resources"
	type = string
	}

variable "db_remote_state_bucket" {
	description = "The name of the S3 bucket for the database's remote state"
	type = string
	}

variable "db_remote_state_key" {
	description = "The path for the database's remote state in S3"
	type = string
	}

variable "min_size" {
	description = "Minimum size of cluster"
	type = number
	}

variable "max_size" {
	description = "Maximum size of the cluster"
	type = number
	}

variable "desired_capacity" {
	description = "Desired cluster size"
	type = number
	}

