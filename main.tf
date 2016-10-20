data "aws_availability_zones" "available" {}

resource "aws_ecs_task_definition" "jenkins" {
  family = "jenkins"
  container_definitions = "${file("jenkins.json")}"
}

resource "aws_iam_role_policy" "jenkins" {
    name = "jenkins-ci-role-policy"
    role = "${aws_iam_role.jenkins.name}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:CreateService",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecs:StartTask"
      ],
      "Resource": "*"
    },
    {
       "Effect": "Allow",
       "Action": [
         "ecr:BatchCheckLayerAvailability",
         "ecr:BatchGetImage",
         "ecr:GetDownloadUrlForLayer",
         "ecr:GetAuthorizationToken"
       ],
       "Resource": "*"
     },
     {
       "Effect": "Allow",
       "Action": [
         "elasticloadbalancing:Describe*",
         "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
         "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
       ],
       "Resource": "*"
     }
  ]
}
EOF
}

resource "aws_iam_role" "jenkins" {
    name = "jenkins-ci-role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_ecs_service" "jenkins" {
  name = "jenkins"
  cluster = "${aws_ecs_cluster.ci.id}"
  task_definition = "${aws_ecs_task_definition.jenkins.arn}"
  desired_count = 1
  iam_role = "${aws_iam_role.jenkins.arn}"
  depends_on = ["aws_iam_role_policy.jenkins", "aws_elb.jenkins"]

  load_balancer {
    elb_name = "${aws_elb.jenkins.id}"
    container_name = "jenkins"
    container_port = "${var.server_port}"
  }
}

resource "aws_security_group" "jenkins" {
  name = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "jenkins" {
  name = "jenkins-elb"
  subnets = ["${split(",", join(",", aws_subnet.public.*.id))}"]

  listener {
    instance_port = "${var.server_port}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8080/"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  security_groups = ["${aws_security_group.jenkins.id}"]

  tags {
    Name = "jenkins-elb"
  }
}

output "lb_address" {
  value = "${aws_elb.jenkins.dns_name}"
}

