terraform {
  backend "local" {
    path = "output/terraform.tfstate"
  }
}