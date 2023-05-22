# tekton-dashboard-helm-chart

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Helm chart for [Tekton Dashboard](https://github.com/tektoncd/pipeline).

## Usage

## Prerequisites

The following tools need to be installed locally:

- [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
- [yq](https://github.com/mikefarah/yq/#install)

### Jenkins X

If you are creating a template to be used in Jenkins X version, you can run the following command:

```bash
make fetch
```

This will fetch the latest version.
To fetch a specific version (say 0.32.0), use CHART_VERSION

```bash
make CHART_VERSION=0.32.0 fetch
```

Also, remember to change the `version` in `charts/tekton-dashboard/Chart.yaml`.
The `app_version` will be set to the `CHART_VERSION` automatically by the makefile if a `CHART_VERSION` is specified.
For latest set `app_version` to the latest tekton version from the [tekton release page](https://github.com/tektoncd/dashboard/releases) and not `latest`.

### Other use cases

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```bash
helm repo add jxgh https://jenkins-x.github.io/tekton-dashboard-helm-chart/
```

you can then do

```bash
helm search repo tekton
```

The chart installs resources into the `tekton-pipelines` namespace

## Configuration

See chart [readme](charts/tekton-dashboard/README.md) and [values.yaml](charts/tekton-dashboard/values.yaml) for install and config options.
