# What
This project demonstrates two things:

## Modules can be invoked with apparently circular dependencies, but continue to work
The 'working' directory contains a `main.tf` that invokes two modules. Each module is passed a parameter that gets its value from the output of the other module. This seems to be a circular dependency until we look at the modules themselves: 
- Each module accepts two parameters:
  - One is given a hard-coded string
  - The other parameter is given the output of the other module
- Each module has a single output, derived from the hard-coded input parameter

As long as Terraform does not treat a module as a single atomic unit, but instead considers the individual resources within them, then it can resolve dependencies.

## Modules can be invoked without error suddenly fail when invoked with a `for_each`
The 'notworking' directory contains a copy of the workking `main.tf`, but each module is called with `for_each`, iterating over a single item. Aside from having to modify the references to module outputs (replacing `module.test1.output` with `module.test1["item"].output`) the logic should be the same. We should not expect this change to introduce a cycle error, but it does!
