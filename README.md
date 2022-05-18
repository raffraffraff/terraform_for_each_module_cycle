# What is this?
This project demonstrates strange Terraform behavior when iterating over data with `for_each` to call modules. The behavior is an unexpected gotcha that gets in the way of data-driven Terraform usage.

# What do we wish to demonstrate?
## Modules with apparently circular dependencies can work
We create a simple module and call it twice. Each call passes an input parameter that references the _other instance_ of the module. Example:

```
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
```

We appear to have a circular dependency, yet this code can work if the test module's output depends on the hard-coded string input. In other words, Terraform does not seem to treat a module as a single atomic unit while working out the dependency graph. Instead it appears to evaluate module components and then work out the dependency graph with them.

## Using `for_each` to iterate over a list still works, _if we hard-code the reference to the other module instance output_
If we create a simple list that contains 1 item, and iterate over the list when deploying the modules, there is essentially no change. Terraform expands the list and figures out how many copies of each module it needs to create. We can still refer to the output of the  _other instance_ of the module, but only if we refer to it using a hard-coded reference, ie "item". Example

```
module "one" {
  for_each = toset(["item"])
  source = "../modules/test"
  input1 = module.two["item"].output
  input2 = "one"
}

module "two" {
  for_each = toset(["item"])
  source = "../modules/test"
  input1 = module.one["item"].output
  input2 = "two"
}
```

## Referring to the output of the other module using `each.key` causes a cycle error
If we subtly change the previous example and replace the hard-coded module output references with `each.key` (which resolves to "item"!), then suddenly we get a cycle error. Example:

```
module "one" {
  for_each = toset(["item"])
  source = "../modules/test"
  input1 = module.two[each.key].output
  input2 = "one"
}

module "two" {
  for_each = toset(["item"])
  source = "../modules/test"
  input1 = module.one[each.key].output
  input2 = "two"
}
```

This causes the following error:
```
Error: Cycle: module.two.var.input1 (expand), module.two (close), module.one.var.input1 (expand), module.one (close)
```

