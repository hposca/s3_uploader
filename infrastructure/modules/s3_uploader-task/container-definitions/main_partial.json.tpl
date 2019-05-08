{
  "cpu": ${MAIN_CPU},
  "image": "${MAIN_IMAGE_REPO}:${MAIN_IMAGE_TAG}",
  "memory": ${MAIN_MEMORY},
  "name": "${TASK_NAME}",
  "networkMode": "awsvpc",
  "portMappings": [
    {
      "hostPort": ${HOST_PORT},
      "protocol": "tcp",
      "containerPort": ${CONTAINER_PORT}
    }
  ],
  "environment" : [
    { "name": "AWS_REGION",     "value": "${AWS_REGION     }" },
    { "name": "APP_SETTINGS",   "value": "${APP_SETTINGS   }" },
    { "name": "LOG_IDENTIFIER", "value": "${LOG_IDENTIFIER }" },
    { "name": "S3_BUCKET",      "value": "${S3_BUCKET      }" }
  ],
  "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${CLOUDWATCH_LOG_GROUP}",
        "awslogs-region": "${AWS_REGION}",
        "awslogs-stream-prefix": "ecs"
      }
  },
  "mountPoints": [
    { "sourceVolume": "${LOG_VOLUME}", "containerPath": "${LOGS_DIRECTORY}" }
  ]
}
