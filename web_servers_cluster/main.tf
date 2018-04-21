# Provider to use
provider "aws" {
    region = "us-east-1"
}

# Launch configuration resource
resource "aws_launch_configuration" "test_launch_conf" {
    image_id = "ami-6dfe5010"
    instance_type = "t2.micro"
    security_groups = ["${aws_security_group.test_sg.id}"]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group" "test_sg" {
    name = "tf_test_sg"

    ingress {
        from_port = "${var.server_port}"
        to_port = "${var.server_port}"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
        create_before_destroy = true
    }

    tags {
        Name = "Test Security Group"
    }
}

# Creating ASG configuration.
resource "aws_autoscaling_group" "test_asg" {
    launch_configuration = "${aws_launch_configuration.test_launch_conf.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    load_balancers = ["${aws_elb.test_elb.name}"]
    health_check_type = "ELB"
    min_size = 2
    max_size = 4

    tag {
        key = "Name"
        value = "Test ASG Instance"

        propagate_at_launch = true
    }
}

resource "aws_elb" "test_elb" {
    name = "Terraform-ELB"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    security_groups = ["${aws_security_group.test_elb_security_group.id}"]
    
    listener {
        lb_port = 80
        lb_protocol = "http"
        instance_port = "${var.server_port}"
        instance_protocol = "http"
    }
    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        interval = 30
        target = "HTTP:${var.server_port}/"
    }
} 

resource "aws_security_group" "test_elb_security_group" {
    name = "Test ELB Security Group"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_availability_zones" "all" {}

variable "server_port" {
    description = "Port on which server listens"
    default = "8080"
}

output "elb_dns_name" {
    value = "${aws_elb.test_elb.dns_name}"
}


