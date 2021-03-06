variable "ecs_cluster" {}
variable "app_identifier" {}
variable "app_environment" {}
variable "app_image" {}
variable "nginx_image" {}
variable "memory" {}
variable "cpu" {}
variable "aws_region" {}
variable "container_instance_subnets" {}
variable "vpc_id" {}
variable "vpc_cidr_block" {}
variable "logs_bucket" {}
variable "codedeploy_role" {}
variable "uploads_bucket" {}
variable "audio_bucket" {}
variable "load_balancer_arn" {}
variable "listener_arn" {}

variable "webserver_container_name" {
  default = "nginx"
}
variable "webserver_container_port" {
  default = 80
}

variable "app_port" {
  default = 3000
}
variable "network_mode" {
  default = "awsvpc"
}
variable "launch_type" {
  default = "FARGATE"
}

variable "db_pool" {
  default = 48
}

variable "database_subnets" {}
variable "db_username" {
  default = "somleng"
}
variable "enable_dashboard" {
  default = false
}
variable "ecs_appserver_autoscale_max_instances" {
  default = 4
}
variable "ecs_appserver_autoscale_min_instances" {
  default = 1
}
variable "ecs_worker_autoscale_max_instances" {
  default = 4
}
variable "ecs_worker_autoscale_min_instances" {
  default = 1
}
# If the average CPU utilization over a minute drops to this threshold,
# the number of containers will be reduced (but not below ecs_autoscale_min_instances).
variable "ecs_as_cpu_low_threshold_per" {
  default = "20"
}

# If the average CPU utilization over a minute rises to this threshold,
# the number of containers will be increased (but not above ecs_autoscale_max_instances).
variable "ecs_as_cpu_high_threshold_per" {
  default = "80"
}

variable "scheduler_schedule" {
  default = "cron(* * * * ? *)"
}
