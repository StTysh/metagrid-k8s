# metagrid-k8s

`metagrid-k8s` packages the Metagrid platform as a Helm chart for Kubernetes deployment. The repository includes chart templates, local development tooling, and release automation for publishing chart updates.

## What is deployed

The chart coordinates a multi-service deployment that includes:

- frontend service
- backend service
- node status service
- ingress configuration
- PostgreSQL HA dependency
- monitoring-related configuration files

## Stack and tooling

- Kubernetes
- Helm
- Helmfile
- GitHub Actions
- GitLab CI
- Bitnami PostgreSQL HA chart

## Repository structure

```text
chart/                 Helm chart source
chart/templates/       Kubernetes templates for frontend, backend, node status, and ingress
chart/files/           Supporting configuration files
.github/workflows/     GitHub release automation
.gitlab-ci.yml         Legacy / alternate CI configuration
cr.yaml                Chart releaser configuration
```

## Local development

### Requirements

- Kubernetes cluster for testing
- `helm`
- `helmfile`
- `minikube` for local workflows

### Install chart

```bash
helm install <name> oci://ghcr.io/esgf2-us/metagrid --version v1.3.5
```

### Local test workflow

Start a local Kubernetes cluster:

```bash
minikube start
minikube status
```

Apply the local Helmfile deployment:

```bash
helmfile apply
```

Expose services locally:

```bash
minikube tunnel
```

The application can then be accessed at `https://localhost/search`.

### Test pull-request images

```bash
helmfile apply --set frontend.image.tag=pr-<number> --set backend.image.tag=pr-<number>
```

## Release automation

The repository includes a GitHub Actions workflow that:

- runs on changes to `chart/**` on `main`
- installs Helm
- adds chart dependencies
- publishes releases through `helm/chart-releaser-action`

## Configuration

Most chart configuration lives in:

- `chart/values.yaml`
- `chart/helmfile.yaml`
- templates under `chart/templates/`

The chart-level README under `chart/README.md` documents the value schema in more detail.

## Notes

- This repository is primarily deployment and release infrastructure rather than application code.
- It is useful when you want reproducible packaging, local validation, and operational delivery for the Metagrid platform.
