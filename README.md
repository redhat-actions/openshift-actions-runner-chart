# OpenShift GitHub Actions Runner Chart

[![Helm Lint](https://github.com/redhat-actions/openshift-actions-runner-chart/workflows/Helm%20Lint/badge.svg)](https://github.com/redhat-actions/openshift-actions-runner-chart/actions)

[![Tag](https://img.shields.io/github/v/tag/redhat-actions/openshift-actions-runner-chart)](https://github.com/redhat-actions/openshift-actions-runner-chart/tags)
[![Quay org](https://img.shields.io/badge/quay-redhat--github--actions-red)](https://quay.io/organization/redhat-github-actions)

This repository contains a Helm chart for deploying one or more self-hosted [GitHub Actions Runners]((https://docs.github.com/en/free-pro-team@latest/actions/hosting-your-own-runners/about-self-hosted-runners)) into a Kubernetes cluster. By default, the container image used is the [**OpenShift Actions Runner**](https://github.com/redhat-actions/openshift-actions-runner).

You can deploy runners automatically using the [**Self Hosted Runner Installer Action**](https://github.com/redhat-actions/self-hosted-runner-installer).

## Prerequisites
You must have access to a Kubernetes cluster. Visit [openshift.com/try](https://www.openshift.com/try) or sign up for our [Developer Sandbox](https://developers.redhat.com/developer-sandbox).

You do **not** need cluster administrator privileges to deploy the runners and run workloads, though some images or tools may require special permissions.

## Installing runners

You can install runners into your cluster using the Helm chart in this repository.

1. Runners can be scoped to an **organization** or a **repository**. Decide what the scope of your runner will be.
    - User-scoped runners are not supported by GitHub.
2. Create a GitHub Personal Access Token as per the instructions in the [runner image README](https://github.com/redhat-actions/openshift-actions-runner#pat-guidelines).
    - The default `secrets.GITHUB_TOKEN` **does not** have permission to manage self-hosted runners. See [Permissions for the GITHUB_TOKEN](https://docs.github.com/en/actions/reference/authentication-in-a-workflow#permissions-for-the-github_token).
3. Clone this repository and `cd` into it:
```bash
git clone git@github.com:redhat-actions/openshift-actions-runner-chart.git \
&& cd openshift-actions-runner-chart
```
4. Install the helm chart, which creates a deployment and a secret. Leave out `githubRepository` if you want an organization-scoped runner.
    - Add the `--namespace` argument to all `helm` and `kubectl/oc` commands if you want to use a namespace other than your current context's namespace.

```bash
# PAT from step 2.
export GITHUB_PAT=c0ffeeface1234567890
# For an org runner, this is the org.
# For a repo runner, this is the repo owner (org or user).
export GITHUB_OWNER=redhat-actions
# For an org runner, omit this argument.
# For a repo runner, the repo name.
export GITHUB_REPO=openshift-actions-runner-chart
# Helm release name to use.
export RELEASE_NAME=actions-runner

helm install $RELEASE_NAME ./actions-runner/ \
    --set-string githubPat=$GITHUB_PAT \
    --set-string githubOwner=$GITHUB_OWNER \
    --set-string githubRepository=$GITHUB_REPO \
&& echo "---------------------------------------" \
&& helm get manifest $RELEASE_NAME | kubectl get -f -
```

5. You can re-run step 4 if you want to add runners with different images, labels, etc. You can leave out the `githubPat` on subsequent runs, since the secret will be left out if it exists already.

For other configuration options such as resource limits and replica counts, see [`values.yaml`](./actions-runner/values.yaml).

The runners should show up under `Settings > Actions > Self-hosted runners` shortly afterward.

## Using your own runner image
See the [OpenShift Actions Runner README](https://github.com/redhat-actions/openshift-action-runners#README.md).

## Managing PATs
See [the wiki](https://github.com/redhat-actions/openshift-actions-runner-chart/wiki/Managing-PATs) for a note on managing mulitple PATs, if you want to add a new PAT or replace an existing one.

## Troubleshooting
You can view the resources created by Helm using `helm get manifest $RELEASE_NAME`, and then inspect those resources using `kubectl get`.

The resources are also labeled with `app.kubernetes.io/instance={{ .Release.Name }}`, so you can view all the resources with:

```sh
kubectl get all,secret -l=app.kubernetes.io/instance=$RELEASE_NAME
```

If the pods are created but stuck in a crash loop, view the logs with `kubectl logs <podname>` to see the problem. Refer to the [runner container troubleshooting](https://github.com/redhat-actions/openshift-actions-runner#troubleshooting) to resolve any issues.
