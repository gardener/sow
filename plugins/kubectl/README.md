

## Kubectl Plugin

The _kubectl_ plugin can be used to deploy manifests into a kubernetes cluster

### Configuration

The configuration section for the kubectl plugin may come in different flavors

Basically it should be a list of cluster deployments. Instead of a list
themight be a single entry used configuration.

Each entry may have the following entries:

- `kubeconfig`: a file containing the kubeconfig or the kubeconfig yaml.
- `retry`:
   - `attempts`: number of possible retries
   - `wait`:     seconds to wait between two retries
- `equivalences`: list of api group / kind equivalance for auto migrating objects
  Each entry is again a list equivalent `apiGroup`/`kind` pairs (as map enries)
- `manifests`: a list of manifests to be deployed using the above kubeconfig
- `files`: instead of a manifest list a list of files can be specified
- `command`: the kubectl plugin allows for command execution specified as list, the follwoing commands are supported yet.
  - `echo`: the arguments are prompted
  - `forget`: forget a formerly deployed object

### Controlling the deployment/deletion

By default the deployment of a manifest is handled by simply calling kubectl.
If dedicated resources require a more complex handling for deployment or
deletion the kubectl plugin again supports handlers for dedicated resources.

Handlers are just shell scripts located in the `handlers` folder of the 
plugin or a `lib/kubectl` folder below the actual component or product.

such a script may define two functions:

- `action_deploy_`_Kind_`_`_ApiGroup_: handler for deployment
- `action_delete_`_Kind_`_`_ApiGroup_: handler for deletion

The dots (`.`) in the api group are replaced by underscores (`_`).

These functions are called with 4 arguments:

- the object name
- the namespace of the object
- the kubeconfig file to use
- the manifest to deploy/delete

For deletion a fake manifest might be given.

A handler may also define commands usable with the command property
of an entry. A command here is a shell fuction starting with `cmd_` followed
by the command name. Its first argument is the actual action (for example 
`deploy` or `delete`) and the arguments specified by the command property.


### Migration Support

The kubectl plugin offeres some support for migrating objects.
Basically updating an object is automatically handled, but if 
resources or objects are moved there might occur errors during an 
update.

#### Migrating apiVersions or kinds

To support the migration of resource groups/versions it is possible
to specify equivalence classes using the `equivalences` property
of a deployment entry.

It is a list of possible equivalences. Every list entry is again
a list of apiGroup/kind pairs that are equivalent to each other.

This information is used to decide whether a dedicated formerly 
object deployment must be deleted or not, if it does not
occur in the actual list of manifests anymore.

If for a formerly deployed object a new equivalent one exists it is
silently deleted from the state if the apiGroup/kind has changed.

By default all versions inside an API Group are considered to be equivalent.
Only equivalences among different api groups have to explicitly declared

An alternative more global way to declare equivalences are `.equiv` files
in the plugins lib search path (above the `handlers` folder used to lookup
deployment handlers for dedicated resources). Those files
must be YAML files containing the `equivalences` property.

In all scenarios the `equivalences` property is a list of equivalence lists.
An entry in this second level lst supports the following fields:

- `kind`:       the resource kind
- `apiGroup`:   the api group of the resource. Alternatively it may contain
- `apiVersion`: an api version for the group. The version part is ignored.

The api group for core resources is `core`.

The `.equiv` files are also processed by _spiff_, so it is possible
to generate the `equivalences` property usng spiff templating.

#### Manipulation of old deployment state

For the state manipulation some commands are provided:

- `forget`: this command can be used to remove a formerly deployed
  object from the deloyment state.
  This command requires a configured `kubeconfig` property.
  The following arguments are required:

  - name
  - namespace
  - kind
  - apiVersion
