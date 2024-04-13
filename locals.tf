locals {
  datadog_environment = {
    DD_API_KEY = var.datadog_api_key
    DD_SITE    = var.datadog_site

    DD_APM_ENABLED                 = "true"
    DD_DOGSTATSD_NON_LOCAL_TRAFFIC = "true"
    DD_APM_NON_LOCAL_TRAFFIC       = "true"
    DD_PROCESS_AGENT_ENABLED       = "true"
    DD_LOGS_ENABLED                = "true"

    DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL = "true"

    ECS_FARGATE = "true"
  }
}