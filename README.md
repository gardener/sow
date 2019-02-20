
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

Each _installation component_ is described by
a yaml document (`deployment.yaml`) containing
the configuration settings for a dedicated set of
installation plugins and a yaml document (`component.yaml`)
describing the used components.

The installation plugins are shell modules delivered
with the tool itself or provided by the installation content.

After installation a component may offer (_export_) (structured yaml)
values to be used by other components, again described
by a yaml document (`export.yaml`) and keep a state in form
of a yaml document (`state.yaml`) or other files.

The information flow is described by the component dependencies.
Therefore _Sow_ processes the yaml documents with the
[_spiff++_ in-domaim templating engine](https://github.com/mandelsoft/spiff/blob/master/README.md)
by providing appropriate merge stubs based on
the exports of the dependencies and the last local state.

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

### The filesystem structure

```
├── acre.yaml                  # config of the concreate installation instance
├── garden                     # the installation source for the landscape
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
│   └── greenhouses           # recursively included instellation sources
│       └── nestedproduct     # name as root of the installation source
│           └── components
│               ├── testcomp
│               │   ├── component.yaml
│               │   ├── deployment.yaml
│               │   .
│               │   .
│               │   .
│               │    
│               ├── greenhouses  # recursively included instellation sources
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

This file may contain any configuration informatio in any 
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

- `stubs`: alist with stub files that should be added to the merging
   processess for the other control files. Thise files typically
   contain settings or utility functions, that should be used during the
   interpolation process.
   The given file names should be relative paths. They are lookuped
   - locally to the component
   - locally to the installation source
   - locally to the _sow_ tool root

- `active`: boolean value indication whether this component is active in
  the actual landscape.

This file is processed by _spiff_ using the landscape configuration
and the tool's `component.yaml` template file as stub.

#### `deployment.yaml`

This document is used to describe the used plugins for a component and
their configuration settings.
It is processed by spiff using some stub files.

- the last state document (described by `state.yaml`)
- the effective installstion configuration `gen/config.json`
- the import information (see below)
- addtional stubs described by the `component.yaml`

_sow_ evaluates the dependencies and generates an additional stub file
containing the exports of all imported components.
They are stored with their _label_ below the node `imports`.

The effective deployment configuration is stored in the `gen` below the
component folder.

It should contain a `plugins` node listing the plugins that should be executed.
A plugin entry may take additional string arguments.

By convention, the first argument describes the path of the yaml node that
contains the configuration for the plugin call. By default a plugin
should assume its name as path.

The denoted path should then contain the actual configuration for
the plugin. This way the same plugin can be called multiple times
with different settings.

The execution order is taken from the list order and reversed for the deletion
of a component.

#### `state.yaml`

This file should describe the information that should be kept
for subsequent executions

It uses the `deployment.yaml`and all the stubs used for its processing as
stub.

#### `export.yaml`

This file should describe the information intended for reuse by other
components. By convention it should be stored below an `export` node.

It uses the `deployment.yaml` and all the stubs used for its processing as
stub. As state the state of the actual execution is used.


### The command

_sow_ evaluates the current working directory fo figure out
- the concrete installation folder
- the actual product 
- the actual component 

This information is then used as default for its execution.

By default _sow_ interprets its arguments as components that should be 
deployed and executes theit deploy action in the appropriate order.

The following sub commands are supported:

- `deploy`:  (default)  deploy components
- `delete`:  delete components
- `show`: show meta data of given components
- `info`: show info about actual position in filesystem
- `version`: show tool version
- `order`: show order of components and/or their deploy or deletion order

The command supports the following options:
- `-a`: complete the component list
        for `info` it shows the complete component and product list
        for `deploy` and `delete` completes the dpeloy are delete
        order according to the configured component dependencies.
- `-A`: `deploy`and `delete` work on all active components
- `-x`: enables trace mode
- `-v`: enables verbose mode
