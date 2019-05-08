provider "aws" {
  region = "${var.aws_region}"
}

module "s3_uploader_repositories" {
  source             = "modules/ecr/"
  repositories_names = ["s3_uploader"]
}

module "s3_uploader_cluster" {
  source       = "modules/ecs-cluster/"
  cluster_name = "s3_uploader"
}

resource "aws_s3_bucket" "target_bucket" {
  bucket = "s3-uploader-bucket"
  acl    = "private"

  tags = {
    Name        = "S3 Uploader Bucket"
    Environment = "testing"
  }
}

module "s3_uploader_service1" {
  source              = "modules/ecs-service/"
  cluster_id          = "${module.s3_uploader_cluster.cluster_id}"
  cluster_name        = "${module.s3_uploader_cluster.cluster_name}"
  service_name        = "s3uploader-service1"
  task_definition_arn = "${module.s3_uploader_task1.task_definition_arn}"

  vpc_id          = "${module.vpc.vpc_id}"
  public_subnets  = "${module.vpc.public_subnets}"
  private_subnets = "${module.vpc.private_subnets}"

  # The name of the project this application is part of.
  project = "s3_uploader"

  enable_autoscaling = true

  # Scale-out refers to when we want to increase the number of jobs. So,
  # here we can set the time in which we will increase the number of jobs
  # running. All times are in UTC.
  autoscaling_scale_out_cron = "cron(45 23 * * ? *)"

  # Scale-in refers to when we want to decrease the number of jobs. So,
  # here we can set the time in which we will decrease the number of jobs
  # running. All times are in UTC.
  autoscaling_scale_in_cron = "cron(00 20 * * ? *)"

  # This will set, at the same time, the desired number of tasks to
  # run now and the maximum number of tasks that will be executed
  # when the automatic autoscaling scales up
  desired_tasks_number = 3

  # To keep some tasks running when it scales down automatically, change the
  # 'autoscaling_min_tasks' value. If it is set to 1, one task will always be
  # running:
  autoscaling_min_tasks = 1
}

module "s3_uploader_task1" {
  source = "modules/s3_uploader-task"

  aws_region     = "${var.aws_region}"
  cluster_name   = "${module.s3_uploader_cluster.cluster_name}"
  task_name      = "s3_uploader-task1"
  log_identifier = "s3_uploader-task1"
  bucket_name    = "${aws_s3_bucket.target_bucket.id}"
  bucket_arn     = "${aws_s3_bucket.target_bucket.arn}"

  max_cpu    = 256
  max_memory = 512

  # This is the number of containers that we want to have running at the same
  # time in a single task. Terraform will automatically split the CPU and
  # memory between all the containers.
  # Due to the current architecture please leave this as 1.
  containers_per_task = 1

  main_image_repo = "${module.s3_uploader_repositories.repositories_urls["s3_uploader"]}"
  main_image_tag  = "master-latest"

  # Ports defined by the application
  host_port      = 5000
  container_port = 5000
}
