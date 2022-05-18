module "one" {
  source = "../modules/test"
  input1 = module.two.output
  input2 = "one"
}

module "two" {
  source = "../modules/test"
  input1 = module.one.output
  input2 = "two"
}

output "one" {
  value = module.one.output
}

output "two" {
  value = module.two.output
}
