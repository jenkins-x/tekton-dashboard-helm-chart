# tekton dashboard helm chart

## Setup
First add the Jenkins X chart repository

```sh
helm repo add jxtkn https://jenkins-x.github.io/tekton-dashboard-helm-chart/
```
If it already exists be sure to update the local cache
```
helm repo update
```

## Basic install
```
helm upgrade --install tekton-dashboard jxtkn/tekton-dashboard
```