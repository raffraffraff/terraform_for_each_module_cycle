locals {
  iterable = toset(["item"])
}

module "one" {
  for_each = local.iterable
  source = "../modules/test"
  input1 = module.two["item"].output
  input2 = "one"
}

module "two" {
  for_each = local.iterable
  source = "../modules/test"
  input1 = module.one["item"].output
  input2 = "two"
}

output "one" {
  value = module.one["item"].output
}

output "two" {
  value = module.two["item"].output
}
