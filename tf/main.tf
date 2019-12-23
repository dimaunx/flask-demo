module "flask-demo-deployment" {
  source           = "./flask-demo"
  kube_config_path = var.kube_config_path
  docker_image     = var.docker_image
  project_name     = var.project_name
}