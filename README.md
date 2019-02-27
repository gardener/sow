
# Sow - a tiny Configuration Orchestration Framework

_Sow_ is not yet another installation tool. It is
not able to handle installation steps by its own.
Instead it is used to describe and execute an
orchestration of multiple installation components
based on arbitrary installation
tools, like _terraform_, _helm_, _kubectl_, etc.

The tool itself only handles the information flow
among those installation components and controles
their execution order.

<p align="center">

<img src="doc/sow0.png" alt="Processing" width="400"/>

</p>

Each _installation component_ is described by a set of
yaml documents. This is used together with an installation
configuration and information provided by used components
to generate a deployment configuration  and a contract intended
to be used by other components.

The deployment configuration consists of a 
sequence of plugin execution requests and their configuration.

The installation plugins are shell modules or executables
delivered with the tool itself or provided by the installation content.
_sow_ finally just generates the plugin config and executes the plugins
in the appropriate order.


### Overview

A _component_ is described by a set of yaml documents.
The `component.yaml` describes the dependencies to other
components. A `deployment.yaml` describes the configuration
for the plugin executions. The component may 
(_export_) (structured yaml)
values to be used by other components (the contract), again described
by a yaml document (`export.yaml`) and keep a state in form
of a yaml document (`state.yaml`) or other files.

The information flow is described by the component dependencies
and an installation configuration.
Therefore _sow_ processes the yaml documents with the
[_spiff++_ in-domaim templating engine](https://github.com/mandelsoft/spiff/blob/master/README.md)
by providing appropriate merge stubs based on
the exports of the dependencies and the last local state.
This allows to describe the calculation of the effective document versions
in-place with `dynaml`expressions evaluated by _spiff_.

<p align="center">

![Processing](doc/sow1.png)

</p>

The dependencies are also used to determine the appropriate 
deployment and deletion order for the components of
an installation source.

An _installation source_ is a set of components bundled
in a dedcated filesytem structure. This could, for example,
be stored and versioned in source code management systems like
_git_. The installation sources might be nested, this means
an installation source may also include other installation
sources. With git, this could be done using submodules.
In any way the result is a closed filesystem structure 
containing the complete installation source.

Finally a _landscape_ describes a concrete installation
as instance of an installation source. It is again described
by a dedicated closed file system structure containing the
installation source and a yaml document containing the
configuration values for the dedicated installation.
This configuration will also be part of the template
processing of the various configuration
files provided by the installation components.

During the installation
process, this filesytsem structure will also be used to hold
the state of the installation components.
It can again be versioned using a versioning system.
With git, for example, the installation source can be
added and versioned by a git submodule.

### The Wording

_Sow_ is not meant as noun, but verb, in the sense of the
required action to till the soil. It is used to _sow_ the
seedlings of different kinds or _species_ found in
_greenhouses_ in the field, or _acre_.

The first use case is to install a garden with a
[gardener](https://github.com/gardener/gardener) on
a kubernetes cluster.

### The Filesystem Structure

```
├── acre.yaml                  # config of the concreate installation instance
├── crop                       # the installation source for the landscape
│   ├── acre.yaml
│   ├── components             # components of the root installation source
│   │   ├── comp1
│   │   │   ├── component.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── state.yaml
│   │   │   └── export.yaml
│   │   ├── nested            # components may be nested
│   │   │   └── comp2
│   │   │       ├── component.yaml
│   │   │       ├── deployment.yaml
│   │   │       ├── lib
│   │   │       │   └── action
│   │   .       ├── state.yaml
│   │   .       └── export.yaml
│   │   .
│   │
│   └── greenhouses           # recursively included installation sources
│       └── nestedproduct     # name as root of the installation source
│           └── components
│               ├── testcomp
│               │   ├── component.yaml
│               │   ├── deployment.yaml
│               │   .
│               │   .
│               │   .
│               │    
│               ├── greenhouses  # recursively included installation sources
│               │   ├── othernestedproduct
│               │   .
│               .   .
│               .   .
│               .
│
├── state                       # state that needs to be persisted
│   ├── <components>
│   .
│   .
│   .
│
├── export                      # information flow among components
│   ├── <components>
│   .
│   .
│   .
│
├── gen                         # temporary files (can be deleted at any time)
│   ├── <components>
.   .
.   .
.
```

### The control files

#### `acre.yaml`

This file may contain any configuration information in any 
structure required by the installation source.

A convention is to use a node `landscape` to hold the
configuartion information. 

Using dedicated elements has an advantage for the later mergeing process,
because it avoids undesired overrides and allows access to dedicated
kinds of information for the yaml interpolation steps.

This document is processed by spiff using an optional `acre.yaml` located 
in the root installation source as template.
Tis template can be used to provide defaults or to check and required values
in the configuration (using _spiff_ features).

The processing result is stored in `gen/config.json`. This file
is used as stub for the processing of the other control files.

#### `component.yaml`

This file indicates the root folder of a component. It is used by
_sow_ to extract control information for the component held in
the node `component`.

So far, three fields are used:
- `imports`: a list of components the actual component depends on.
   The import can be labeled by using the syntax 
   
   <p align="center">
   _<label>_`: `_<component name>_
   </p>

   If a nested component (containing a `/`), there should be a label
   to simplify the access during the interpolation process later on.

- `stubs`: a list with stub files that should be added to the merging
   processess for the other control files. Thise files typically
   contain settings or utility functions, that should be used during the
   interpolation process.
   The given file names should be relative paths. They are lookuped
   - locally to the component
   - locally to the installation source
   - locally to the _sow_ tool root

- `active`: boolean value indication whether this component is active in
  the actual landscape.


- `plugins`: plugin definitions (see [deployment.yaml](#deploymentyaml))
  called before deployment evaluation (action `prepare`) and after deletion
  steps (action `cleanup`).

This file is processed by _spiff_ using the landscape configuration
and the tool's `component.yaml` template file as stub.

#### `deployment.yaml`

This document is used to describe the used deployment plugins for a component and
their configuration settings.
It is processed by _spiff_ using some stub files.

- the actual execution environment (see below)
- the last state document (described by `state.yaml`)
- the import information (see below)
- the effective installation configuration `gen/config.json`
- additional stubs described by the `component.yaml`

The environment stub contains the node `env` with fields describing the
actual component environment:
  - `COMPONENT`: the component name
  - `GENDIR`: component specific folder for temporary files
  - `STATEDIR`: component specific folder for persistent files
  - `EXPORTDIR`: component specific folder for contract files
  - `ROOTDIR`: installtion root directory
  - `ROOTPRODUCTDIR`: installation source directory
  - `PRODUCT`: in case of nested products the product name
  - `PRODUCTDIR`: the root directory of the components product

_sow_ evaluates the dependencies and generates an additional stub file
containing the exports of all imported components.
They are stored with their _label_ below the node `imports`.

The effective deployment configuration is stored in the `gen` directory below the
component folder.

It should contain a `plugins` node listing the plugins that should be executed.
A plugin entry may take additional string arguments and a configuration.

```yaml
plugins:
  - echo: "deploying a secret"
  - kubectl:
      config: # <yaml config for kubectl plugin>
        kubeconfig: (( landscape.cluster.kubeconfig ))
        manifests:
          - apiVersion: v1
            kind: Secret
            ...
  - echo:
     - "Happy"
     - "sowing"
  - echo:    # this is the complete form for specifying a plugin
     config: 
     path: echo
     args:
       - "Happy"
       - "sowing"
```

By convention, if arguments are used andthe plugin requires a configuration
the first argument describes the path of the yaml node that
contains the configuration for the plugin call. By default a plugin
should assume its name as path. The better way is to specify the
configuration directly in the plugin node as described above.

The denoted path should then contain the actual configuration for
the plugin. This way the same plugin can be called multiple times
with different settings.

The execution order is taken from the list order and reversed for the deletion
of a component.

If a `path` is given it is used as sub folder to store information
for the actual plugin execution, to separate multiple occurrences
of a plugin in the plugin list. By default the plugin name should be
used as `dir`

If the plugin name start with a `-`, its execution is not notified
on the output. This can be used for the `echo` plugin to
echo plain multi line text.

#### `state.yaml`

This file should describe the information that should be kept
for subsequent executions

It uses the `deployment.yaml` and all the stubs used for its processing as
stub.

#### `export.yaml`

This file should describe the information intended for reuse by other
components. By convention it should be stored below an `export` node.

It uses the `deployment.yaml` and all the stubs used for its processing as
stub. As state the state of the actual execution is used.

If it contains a `files` section the listes files (structure with `path` and
`data` fields) are written to the components export folder.

#### The Generation Process

<p align="center">

![Processing Details](doc/sow2.png)

</p>

The data flow is heavily based on the processing of yaml dosuments
with _spiff++_.

Every component is processed separately.

- First, the installation configuration is processed together with a
  configuration template provided by the installation source. The result
  is an effective installation configuration stored in the `gen` folder.
- Second, the `component.yaml` is processed together with the installation
  configuration used as stub to achieve the effective component meta data.
  Here, dedicated components can be activated or deactivated, or dependencies
  might be adjusted according to the actual installation configuration.
- Third, the component meta data is evaluated to determine the effective
  component dependencies and stubs used for the further processing.
  The export information of the used components are gathered and aggregated
  into a single import file.
- Fourth, the `deployment.yaml` is processed to determine the concreate
  plugin sequence and their configuration settings.
- Fifth, the effective deploment configuration is evaluated and the plugin
  set and order is determined. Then the plugins are called in the
  appropriate order together with their dedicated configuration settings.
  The plugins might access and provide own instance specific state information.
  (For example a `terraform.thstate` file).
- Sixth, an optional additional state can be provided by processing an
  `state.yaml` that will be used as stub for subsequent exection of
  deployment actions.
- Seventh, the `export.yaml`is processed together with the latest state
  to generate the interface information for using components.

### The command

_sow_ evaluates the current working directory fo figure out
- the concrete installation folder
- the actual product 
- the actual component 

This information is then used as default for its execution.

By default _sow_ interprets its arguments as components that should be 
deployed and executes theit deploy action in the appropriate order.

The following sub commands are supported:

- `deploy`:   (default)  deploy components
- `delete`:   delete components
- `show`:     show meta data of given components
- `info`:     show info about actual position in filesystem
- `version`:  show tool version
- `generate`: generate manifests without action execution 
- `order`:    show order of components and/or their deploy or deletion order
- `add`:      create the frame for a new component
- `vi`:       lookup or edit component related files in component specific folders

The command supports the following options:
- `-a`: complete the component list
        for `info` it shows the complete component and product list
        for `deploy` and `delete` completes the dpeloy are delete
        order according to the configured component dependencies.
- `-A`: `deploy`and `delete` work on all active components
- `-m`: use given component names as patter to match against filesystem and 
        component list
- `-n`: no redeploy, just do new deployments
- `-k`: keep temporary files
- `-X` <plugin>: enables trace mode for given plugin
- `-x`: enables trace mode
- `-v`: enables verbose mode


`sow help` prints a complete list of commands with sub sub options.


If a file `.sowrc" exists in the users home directory it is sources
prior to any command execution.

### Plugins

Plugins are used to exeutes the real installation work.
There are several plugins delivered with the tool, but an installation
source or even a single component might provide own or replace existing plugins.

#### API

A plugin is just an executable or shell script. The provides plugins are all shell
scripts.

There is a combined environment and command line interface for the execution
of plusings.

In the environment environment variables are provided for a dedicated 
execution:

- `SETTINGSJSON`: The manifest the plugin execution is taken from
- `PLUGINCONFIGJSON`: The configuration configured in the plugin specification
                      in the above manifest
- `PLUGININSTANCE`: The configured plugin instance name/path

- `GENDIR`: The place to store temporary file for the component
- `STATEDIR`: The place to store persistent (state relevant) files for the component
- `EXPORTDIR`: The place to store files intended for reuse by other components.
- `SOWLIB`: Library path for shell libraries offered by _sow_.

Using a complete plugin call specification (using the config/args) field
the first variable should never be used.
If only the arguments are used in the plugin call specification and the
plugin requires further configuration, it should be taken from
the `SETTINGSJSON`

If the plugin call specification givens the `path` field it is passed in the
`PLUGININSTANCE` variable. 
This should be used as sub folder path for instance specific data stored below
`GENDIR`, `STATEDIR` or `EXPORTDIR`, to separate different usages of the same
plugin in a component.

If no config is given, but required by the plugin this value should also be used
to lookup the config in the `SETTINGSJSON`. It it is not given
a convention here is to specify the path of the configuration field
as argument, defaulted by the plugin name.

#### Shell scripts as plugins

If a plugin is implemented by a shell script, there is a library that handles
the contract described above. It can be used by

```sh
source "$SOWLIB/pluginutils"
```

It always provides the `PLUGINCONFIGJSON` and `PLUGININSTANCE` variables and feeds
their values according the actual settings and conventions. It also sets
the variables

- `dir`: GENDIR location for the execution
- `state`: STATEDIR location for the execution

and assures their existence.

Additionally it loads the standard utils library from the _sow_ tool, that
offers functios for (colored) output and json access (see [lib/utils](lib/utils)).
