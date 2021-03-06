locals {
  asg_stack_name = "DockerzonClusterASG"
}

resource "aws_cloudformation_stack" "dockerzon-cluster-asg" {
  name = local.asg_stack_name

  parameters = {
    VPCZoneIdentifier    = join(",", data.aws_subnet_ids.dockerzon-public-subnets.ids)
    LaunchTemplateId     = aws_launch_template.dockerzon-asg.id
    MinSize              = var.min_size_asg
    MaxSize              = var.max_size_asg
    DesiredCapacity      = var.desired_capacity_asg
    ServiceLinkedRoleARN = data.terraform_remote_state.prerequisites-state.outputs.autoscaling-service-linked-role-arn
    TemplateVersion      = aws_launch_template.dockerzon-asg.latest_version
    ResourceSignalCount  = var.desired_capacity_asg
  }

  template_body = file("${path.module}/configs/asg_template.yml")

  # create a new one before destroy old one when a resource must be re-created upon a requested change
  lifecycle {
    create_before_destroy = true
  }
}

# launch template
resource "aws_launch_template" "dockerzon-asg" {
  name = "${var.app_name}-asg-launch-template"

  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 30
      delete_on_termination = true
      volume_type           = "gp2"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    description                 = "dockerzon ECS instance ENI"
    device_index                = 0
    security_groups             = data.aws_security_groups.app-sg.ids
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.instance-profile.name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Origin = "Lauched by Dockerzon ASG launch template"
      Name   = "${var.app_name}-asg"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name   = "dockerzon-vol"
    }
  }

  user_data = base64encode(templatefile("configs/user-data.sh",
    { cluster   = var.cluster,
      attribute = var.instance_attributes,
      stack     = local.asg_stack_name,
      resource  = "ASG"
  }))
}
