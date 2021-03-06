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

module "discovery" {
  source = "./discovery"

  asg_arn = module.sample-app.asg_arn
  asg_id = module.sample-app.asg_id
  domain = var.domain
  subdomain = var.subdomain
}
