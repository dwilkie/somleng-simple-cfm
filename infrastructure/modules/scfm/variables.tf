variable "ecs_cluster" {}
variable "app_identifier" {}
variable "app_environment" {}
variable "app_image" {}
variable "nginx_image" {}
variable "memory" {}
variable "cpu" {}
variable "aws_region" {}
variable "load_balancer_subnets" {}
variable "load_balancer_ssl_certificate_arn" {}
variable "container_instance_subnets" {}
variable "vpc_id" {}
variable "logs_bucket" {}
variable "codedeploy_role" {}
variable "uploads_bucket" {}
variable "audio_bucket" {}

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

variable "load_balancer_type" {
  default = "application"
}

variable "load_balancer_protocol" {
  default = "HTTPS"
}

variable "load_balancer_port" {
  default = "443"
}

variable "db_host" {
}

variable "db_port" {
}

variable "db_pool" {
  default = 48
}

variable "db_security_group" {
}

variable "db_username" {}
variable "db_password_parameter_arn" {}
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
