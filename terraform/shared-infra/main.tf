module "network" {
  source             = "./network/"
  availability_zones = var.availability_zones
  project            = var.project
}

module "ecs" {
  source  = "./ecs/"
  project = var.project
}

module "ecr_hello_world" {
  source   = "./ecr/"
  project  = var.project
  app_name = "hello-world"
}
