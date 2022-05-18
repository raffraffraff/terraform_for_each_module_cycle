# What
This project demonstrates strange or unexpected behavior when using modules with `for_each`

## Modules with apparently circular dependencies can work
We create a simple module and call it twice. Each call passes an input parameter that references the other instance of the module. Example:

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

We appear to have a circular dependency, yet this code can work if the test module's output depends on the hard-coded string input. In other words, Terraform does not seem to treat a module as a single atomic unit, instead it appears to evaluate its components and figure out if there is a cycle error at that level.

## Using `for_each` to iterate over a list still works, as long as we hard-code the reference to the other instance's output
If we create a simple list that contains 1 item, and iterate over the list when deploying the modules, there is essentially no change. Terraform expands the list and figures out how many copies of each module it needs to create. We can still refer to the output of _the other module_, but it only works if we refer to it directly using a hard-coded iterable key. Example

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

This shows that nothing fundamentally changes in the dependency graph when we use `for_each`. 

## Referring to the output of the other module using `each.key` causes a cycle error
If we subtly change the previous example and replace the hard-coded module output references with `each.key` references (which should resolve to the same thing), suddenly we get a cycle error. Example:

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

# Why is this a bug?
The behavior is an unexpected gotcha that gets in the way of data-driven Terraform usage
