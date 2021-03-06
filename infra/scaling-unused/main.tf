provider "aws" {
  profile = "qq"
  region  = "ap-southeast-2"
}

locals {
  region = "ap-southeast-2"
}

terraform {
  backend "s3" {
    bucket  = "dave-dockerzon-ecs-tfstate"
    key     = "dockerzon-ecs-scaling-terraform.tfstate"
    region  = "ap-southeast-2"
    # alternatively create an IAM user and attach required permissions to him. The resulting policy can then be added
    # to ACL
    profile = "qq"
  }
}

# Remove 50% of container instances in asg when -Infinity < CPUUtilization <= 25
resource "aws_autoscaling_policy" "dockerzon-cluster-scale-in-policy" {
  name                   = "dockerzon-cluster-scale-in-policy"
  adjustment_type        = "PercentChangeInCapacity"
  autoscaling_group_name = data.terraform_remote_state.ecs-state.outputs.asg-name

  policy_type             = "StepScaling"
  metric_aggregation_type = "Average"

  step_adjustment {
    metric_interval_lower_bound = ""
    metric_interval_upper_bound = 0
    scaling_adjustment          = -50
  }
}

# Add 100% of container instances in asg when 90 <= CPUUtilization < +Infinity
resource "aws_autoscaling_policy" "dockerzon-cluster-scale-out-policy" {
  name                   = "dockerzon-cluster-scale-out-policy"
  adjustment_type        = "PercentChangeInCapacity"
  autoscaling_group_name = data.terraform_remote_state.ecs-state.outputs.asg-name

  policy_type             = "StepScaling"
  metric_aggregation_type = "Average"

  step_adjustment {
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = ""
    scaling_adjustment          = 100
  }
}

# target is ecs task in the service
resource "aws_appautoscaling_target" "ecs-service-auto-scaling-target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${var.cluster}/${var.service}"
  role_arn           = aws_iam_service_linked_role.ecs-app-auto-scaling-role.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Add 100% of tasks when 75 < CPUUtilization < +Infinity
resource "aws_appautoscaling_policy" "ecs-scaling-out-policy" {
  name               = "DockerzonServiceScaleOutPolicy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs-service-auto-scaling-target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-service-auto-scaling-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs-service-auto-scaling-target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type          = "PercentChangeInCapacity"
    cooldown                 = 300
    metric_aggregation_type  = "Average"
    min_adjustment_magnitude = 1

    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = ""
      scaling_adjustment          = 100
    }
  }
}

# Remove 50% of tasks when -Infinity < CPUUtilization <= 25
resource "aws_appautoscaling_policy" "ecs-scaling-in-policy" {
  name               = "DockerzonServiceScaleInPolicy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs-service-auto-scaling-target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs-service-auto-scaling-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs-service-auto-scaling-target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type          = "PercentChangeInCapacity"
    cooldown                 = 300
    metric_aggregation_type  = "Average"
    min_adjustment_magnitude = 1

    step_adjustment {
      metric_interval_lower_bound = ""
      metric_interval_upper_bound = 0
      scaling_adjustment          = -50
    }
  }
}
