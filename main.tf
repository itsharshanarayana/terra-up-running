provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "example" {
    ami           = "ami-6dfe5010"
    instance_type = "t2.micro"

    tags {
        Name = "Terraform-example"
    }
}