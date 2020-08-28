provider "aws" {
  region = "eu-central-1"
}

module "sample-app" {
  source = "./sample-app"
}
