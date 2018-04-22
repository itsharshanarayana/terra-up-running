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

    tags {
        Name = "Test Security Group"
    }

    lifecycle {
        create_before_destroy = true
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
    min_size = 2
    max_size = 4

    tag {
        key                 = "Name"
        value               = "Test-Autoscaling-group"
        propagate_at_launch = true
    }
}

# Variable declarations
variable "server_port" {
    description = "Port on which server listens"
    default     = 8080
}