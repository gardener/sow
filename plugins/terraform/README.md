
## terraform plugin

This plugin executes a terraform project as part of the deployment actions for a component.

The config uses the following fields:

| field | type | meaning |
| ----- | ---- | ------- |
| `source` | path | source path of the terraform project. This might be a relative path into the component folder. |
| `main` | map | directly given terraform main module spec which is used as terraform project. A potential `modules` folder in the sources will be mapped to the generated project root and appropriate module calls can be done as for a regular terraform project. If multiple terraform plugins are used in a component, the lookup of the modules folder will be done taking the plugin instance key into account. |
| `values` | map (required) | input values for the terraform project |

Only one, `main` or `source` can be specified.


