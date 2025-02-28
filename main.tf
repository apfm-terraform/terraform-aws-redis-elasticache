#
# Security group resources
#
resource "aws_security_group" "redis" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "sgCacheCluster"
    Project     = var.project
    Environment = var.environment
  }
}

#
# ElastiCache resources
#
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = lower(var.cache_identifier)
  description                   = "Replication group for Redis"
  automatic_failover_enabled    = var.automatic_failover_enabled
  number_cache_clusters         = var.desired_clusters
  node_type                     = var.instance_type
  engine_version                = var.engine_version
  parameter_group_name          = var.parameter_group
  subnet_group_name             = var.subnet_group
  security_group_ids            = [aws_security_group.redis.id]
  maintenance_window            = var.maintenance_window
  notification_topic_arn        = var.notification_topic_arn
  apply_immediately             = var.apply_immediately
  port                          = "6379"
  at_rest_encryption_enabled    = var.rest_encrypt
  kms_key_id                    = var.rest_kms_key_id
  transit_encryption_enabled    = var.trans_encrypt
  auth_token                    = var.trans_encrypt ? random_password.auth_token[0].result : ""

  dynamic log_delivery_configuration {
    for_each = regexall(".*6\\.[x0-9]$", var.engine_version) == 0 ? [] : local.enable_slow_log
    content {
      destination      = local.log_group_name_slow
      destination_type = "${local.log_destination_type_slow}-logs"
      log_format       = local.log_destination_format_slow
      log_type         = "slow-log"
    }
  }

  dynamic log_delivery_configuration {
    for_each = regexall(".*6\\.[2-9]$", var.engine_version) == 0 ? [] : local.enable_engine_log
    content {
      destination      = local.log_group_name_engine
      destination_type = "${local.log_destination_type_engine}-logs"
      log_format       = local.log_destination_format_engine
      log_type         = "engine-log"
    }
  }

  tags = {
    Name        = "CacheReplicationGroup"
    Project     = var.project
    Environment = var.environment
  }
}

#
# CloudWatch resources
#
resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  count = var.desired_clusters

  alarm_name          = "alarm${var.environment}CacheCluster00${count.index + 1}CPUUtilization"
  alarm_description   = "Redis cluster CPU utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"

  threshold = var.alarm_cpu_threshold

  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}-00${count.index + 1}"
  }

  alarm_actions = var.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "cache_memory" {
  count = var.desired_clusters

  alarm_name          = "alarm${var.environment}CacheCluster00${count.index + 1}FreeableMemory"
  alarm_description   = "Redis cluster freeable memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  statistic           = "Average"

  threshold = var.alarm_memory_threshold

  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}-00${count.index + 1}"
  }

  alarm_actions = var.alarm_actions
}

resource "random_password" "auth_token" {
  count     = var.trans_encrypt ? 1 : 0
  length    = 32
  special   = true
}
