# Provider to be used to create resources.
provider "aws" {
    region = "us-east-1"
}

# AWS instance resource to be created with name "example".
resource "aws_instance" "example" {

    ami = "ami-6dfe5010"
    instance_type = "t2.micro"

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF

    # Security group configuration for EC2 instance.         
    vpc_security_group_ids = ["${aws_security_group.my_sg.id}"]

    # Tags for the EC2 instance.
    tags {
        Name = "Terraform-Example"
    }

}

# AWS security group to be created with name "my_sg".
resource "aws_security_group" "my_sg" {
    name = "terraform-example-instance1"

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "Terraform-Security-Group"
    }
}

