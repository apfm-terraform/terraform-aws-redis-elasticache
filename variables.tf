variable "project" {
  default = "Unknown"
}

variable "environment" {
  default = "Unknown"
}

variable "vpc_id" {
}

variable "cache_identifier" {
}

variable "parameter_group" {
  default = "default.redis3.2"
}

variable "subnet_group" {
}

variable "maintenance_window" {
}

variable "desired_clusters" {
  default = "1"
}

variable "instance_type" {
  default = "cache.t2.micro"
}

variable "engine_version" {
  default = "3.2.4"
}

variable "automatic_failover_enabled" {
  default = false
}

variable "notification_topic_arn" {
}

variable "alarm_cpu_threshold" {
  default = "75"
}

variable "alarm_memory_threshold" {
  # 10MB
  default = "10000000"
}

variable "alarm_actions" {
  type = list(string)
}

variable "log_enable" {
  default = "both"
}

variable "log_group_prefix" {
  default = ""
}

variable "log_destination_format" {
  default = "json"
}

variable "log_group_name_slow" {
  default = ""
}

variable "log_group_name_engine" {
  default = ""
}

variable "log_destination_type_slow" {
  default = "cloudwatch"
}

variable "log_destination_type_engine" {
  default = "cloudwatch"
}

variable "log_destination_format_slow" {
  default = ""
}

variable "log_destination_format_engine" {
  default = ""
}


locals {
  enable_slow_log = var.log_enable != "both" ? var.log_enable != "slow" ? [] : ["slow"] : ["both"]
  enable_engine_log = var.log_enable != "both" ? var.log_enable != "engine" ? [] : ["engine"] : ["both"]
  log_group_prefix = var.log_group_prefix !="" ? var.log_group_prefix : "/redis/${aws_elasticache_replication_group.redis.replication_group_id}"
  log_destination_format_slow = var.log_destination_format_slow !="" ? var.log_destination_format_slow : "${var.log_destination_format}"
  log_destination_format_engine = var.log_destination_format_engine !="" ? var.log_destination_format_engine : "${var.log_destination_format}"
  log_group_name_slow = var.log_group_name_slow !="" ? var.log_group_name_slow : "${local.log_group_prefix}/slow/${var.log_destination_format}"
  log_group_name_engine = var.log_group_name_engine !="" ? var.log_group_name_engine : "${local.log_group_prefix}/engine/${var.log_destination_format}"
}
