# Provider to use for infrastructure creation.
provider "aws" {
    region = "us-east-1"
}

# Security group resource configuration.
resource "aws_security_group" "test_sg" {
    name = "Test_Security_Group"

    ingress {
        from_port   = "${var.server_port}"
        to_port     = "${var.server_port}"
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "Test Security Group"
    }

    lifecycle {
        create_before_destroy = true
    }
}
# Security group for ELB
resource "aws_security_group" "test_sg_elb" {
    name = "Test-SG-ELB"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Launch configuration resource. 
resource "aws_launch_configuration" "test_launch_conf" {
    image_id        = "ami-6dfe5010"
    instance_type   = "t2.micro"
    security_groups = ["${aws_security_group.test_sg.id}"]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World!" > index.html
                nohup busybox httpd -f -d "${var.server_port}" &
                EOF
    lifecycle {
        create_before_destroy = true
    }
}

# Auto scaling group resource.
resource "aws_autoscaling_group" "test_asg" {
    launch_configuration = "${aws_launch_configuration.test_launch_conf.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    min_size = 2
    max_size = 4

    load_balancers = ["${aws_elb.test_load_balancer.name}"]
    health_check_type = "ELB"
    tag {
        key                 = "Name"
        value               = "Test-Autoscaling-group"
        propagate_at_launch = true
    }
}

resource "aws_elb" "test_load_balancer" {
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    security_groups = ["${aws_security_group.test_sg_elb.id}"]
    listener {
        lb_port = 80
        lb_protocol = "http"
        instance_port = "${var.server_port}"
        instance_protocol = "http"
    }
    health_check {
        healthy_threshold = 3
        unhealthy_threshold = 3
        timeout = 3
        interval = 30
        target = "HTTP:${var.server_port}/"
    }
}

data "aws_availability_zones" "all" {}

# Variable declarations
variable "server_port" {
    description = "Port on which server listens"
    default     = 8080
}

output "public_dns_name" {
    value = "${aws_elb.test_load_balancer.dns_name}"
}