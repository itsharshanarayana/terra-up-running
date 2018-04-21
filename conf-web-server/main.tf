# Provider to use.
provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "test_instance" {
    ami = "ami-6dfe5010"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.test_instance_sg.id}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF

    tags {
        Name = "My Test Instance"
    }
}

resource "aws_security_group" "test_instance_sg" {
    name = "Test Instance Security Group"

    ingress {
        from_port = "${var.server_port}"
        to_port = "${var.server_port}"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "Test Instance Security Group"
    }
}

# Variable to specify the server port.
variable "server_port" {
    description = "Port on which the server listens"
    default = "8080"
}


output "server_public_ip" {
    value = "${aws_instance.test_instance.public_ip}"
}