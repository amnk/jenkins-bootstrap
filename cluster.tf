provider "aws" {
  region = "${var.region}"
}

resource "aws_ecs_cluster" "ci" {
  name = "jenkins-ci"
}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags {
    Name = "${var.vpc}-vpc"
  }
}

resource "aws_autoscaling_group" "cluster" {
  name = "jenkins-auto-scaling-group"
  max_size = "3"
  min_size = "1"
  desired_capacity = "2"
  launch_configuration = "${aws_launch_configuration.cluster.name}"
  vpc_zone_identifier = ["${split(",", join(",", aws_subnet.public.*.id))}"]
  load_balancers = ["${aws_elb.jenkins.name}"]
  tag {
    key = "Name"
    value = "jenkins-cluster-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
    name = "ci-instance-profile"
    roles = ["${aws_iam_role.jenkins.name}"]
}

resource "aws_launch_configuration" "cluster" {
    name_prefix = "jenkins-cluster"
    image_id = "${var.ami}"
    instance_type = "t2.micro"
    iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
    security_groups = ["${aws_security_group.cluster.id}"]
    user_data = <<-EOF
                #!/bin/bash
                echo ECS_CLUSTER="${aws_ecs_cluster.ci.name}" >> /etc/ecs/ecs.config
                EOF
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_security_group" "cluster" {
  name = "cloud-ci-cluster-security-group"
  description = "security group used by clustered instances"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = "${var.server_port}"
      to_port = "${var.server_port}"
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "ci-cluster"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "${var.vpc}-internet-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags {
    Name = "${var.vpc}-public"
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id = "${aws_vpc.vpc.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "public" {
  count = "${length(split(",", var.availability-zones))}"
  availability_zone = "${element(split(",", var.availability-zones), count.index)}"
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.vpc_cidr}"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.vpc}-${element(split(",", var.availability-zones), count.index)}"
  }
}
