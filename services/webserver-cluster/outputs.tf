output "alb_dns_name" {
        value = aws_lb.sample.dns_name
        description = "The domain name of the load balancer"
        }

output "asg_name" {
	value = aws_autoscaling_group.instance_1.name
	description = "The name of autoscaling group"
	}


output "alb_security_group_id" {
	value = aws_security_group.alb.id
	description = "The ID of the security group attached to ALB"
	}


