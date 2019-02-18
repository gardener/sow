
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

