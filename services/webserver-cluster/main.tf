

#Get db server address and port from remote terraform outputs

data "terraform_remote_state" "db" {
	backend = "s3"
	config = {
		bucket = var.db_remote_state_bucket
		key = var.db_remote_state_key
		region = "ap-southeast-2"
		}
	}


data "aws_vpc" "default" {
	default = true
	}

data "aws_subnets" "default"{
	filter {	
		name = "vpc-id"
		values = [data.aws_vpc.default.id]
		}
	}

locals {
	http_port = 80
	any_port = 0
	any_protocol = -1
	tcp_protocol = "tcp"
	all_ips = ["0.0.0.0/0"]
	}
	
resource "aws_launch_configuration" "instance_1" {
        image_id = "ami-09a5c873bc79530d9"
	instance_type = "t2.micro"
	security_groups = [aws_security_group.instance_1.id]
	#user_data = <<-EOF
	#		#!/bin/bash
	#		echo "Hello Boni" > index.html
	#		nohup busybox httpd -f -p ${var.server_port} &
	#		EOF
	
	user_data = templatefile("${path.module}/user-data.sh",{
		server_port = var.server_port
		db_address = data.terraform_remote_state.db.outputs.address
		db_port = data.terraform_remote_state.db.outputs.port
		})

	lifecycle {
		create_before_destroy = true
		}

	}

resource "aws_security_group" "instance_1" {
	name = "${var.cluster_name}-sg"
	ingress {
		from_port = var.server_port
		to_port = var.server_port
		protocol = local.tcp_protocol
		cidr_blocks = local.all_ips
		}
	}	

resource "aws_autoscaling_group" "instance_1" {
	launch_configuration = "${aws_launch_configuration.instance_1.name}"
	vpc_zone_identifier = data.aws_subnets.default.ids
	target_group_arns = [aws_lb_target_group.asg.arn]
	health_check_type = "ELB"
	min_size = var.min_size
	max_size = var.max_size
	depends_on = [data.aws_vpc.default]
	desired_capacity = var.desired_capacity
	tag     {
		key = "name"
		value = "${var.cluster_name}-asg"
		propagate_at_launch = true
		}
	}

resource "aws_lb" "sample" {
	name = "${var.cluster_name}-lb"
	load_balancer_type = "application"
	subnets = data.aws_subnets.default.ids
	security_groups = [aws_security_group.alb.id]
	}		


resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.sample.arn
	port = local.http_port
	protocol = "HTTP"
	# Retun a simple 404 page by default
	default_action {
		type = "fixed-response"
		fixed_response {
			content_type = "text/plain"
			message_body = "404: page not found"
			status_code = 404
			}	
		}
	}
# Security Group resource for LB

resource "aws_security_group" "alb" {
	name = "${var.cluster_name}-alb-sg"
	# allow inbound http requests
	# ingress {
	#	from_port = local.http_port
	#	to_port = local.http_port
	#	protocol = local.tcp_protocol
	#	cidr_blocks = local.all_ips
	#	}
	# Allow all outbound requests
	# egress {
	#	from_port = local.any_port
	#	to_port = local.any_port
	#	protocol = local.any_protocol
	#	cidr_blocks = local.all_ips
	#	}
	}

resource "aws_security_group_rule" "allow_http_inbound" {
	type = "ingress"
	security_group_id = aws_security_group.alb.id
	from_port = local.http_port
	to_port = local.http_port
	protocol = local.tcp_protocol
	cidr_blocks = local.all_ips
	}

resource "aws_security_group_rule" "allow_all_outbound" {
	type = "egress"
	security_group_id =aws_security_group.alb.id
	from_port = local.any_port
	to_port = local.any_port
	protocol = local.any_protocol
	cidr_blocks = local.all_ips
	}


# Load blancer target group

resource "aws_lb_target_group" "asg" {
	name = "${var.cluster_name}-tg"
	port = var.server_port
	protocol = "HTTP"
	vpc_id = data.aws_vpc.default.id
	health_check {
		path = "/"
		protocol = "HTTP"
		matcher = "200"
		interval = 15
		timeout = 3
		healthy_threshold = 2
		unhealthy_threshold = 2
		}
	}

resource "aws_lb_listener_rule" "asg" {
	listener_arn = aws_lb_listener.http.arn
	priority = 100
	condition {
		path_pattern {
			values = ["*"]
			}
		}
	action {
		type = "forward"
		target_group_arn = aws_lb_target_group.asg.arn
		}
	}



