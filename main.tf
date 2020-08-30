provider "aws" {
  region = "eu-central-1"
}

module "network" {
  source = "./network"
}

module "sample-app" {
  source = "./sample-app"

  vpc_id = module.network.vpc_id
  min_count = var.min_count
  max_count = var.max_count
}
