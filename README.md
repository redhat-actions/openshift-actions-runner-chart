# OpenShift GitHub Actions Runner Chart

[![Helm Lint](https://github.com/redhat-actions/openshift-actions-runner-chart/workflows/Helm%20Lint/badge.svg)](https://github.com/redhat-actions/openshift-actions-runner-chart/actions)

[![Tag](https://img.shields.io/github/v/tag/redhat-actions/openshift-actions-runner-chart)](https://github.com/redhat-actions/openshift-actions-runner-chart/tags)
[![Quay org](https://img.shields.io/badge/quay-redhat--github--actions-red)](https://quay.io/organization/redhat-github-actions)

This repository contains a Helm chart for deploying one or more [**OpenShift Actions Runners**](https://github.com/redhat-actions/openshift-actions-runner) that act as [self-hosted GitHub Action runners](https://docs.github.com/en/free-pro-team@latest/actions/hosting-your-own-runners/about-self-hosted-runners).

## Prerequisites
You must have access to an OpenShift cluster. Visit [openshift.com/try](https://www.openshift.com/try) or sign up for our [Developer Sandbox](https://developers.redhat.com/developer-sandbox).

You do **not** need cluster administrator privileges to deploy the runners and run workloads, though some images or tools may require special permissions.

## Installing runners

You can install runners into your cluster using the Helm chart in this repository.

1. Runners can be scoped to an organization or a repository. Decide what the scope of your runner will be.
2. [Create a GitHub Personal Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) (PAT) which has the `repo` permission scope.
    - The user who created the token must have administrator permission on the repository/organization the runner will be added to.
    - If the runner will be for the **organization**, the token must also have the `admin:org` permission scope.
3. Clone this repository and `cd` into it:
```bash
git clone git@github.com:redhat-actions/openshift-actions-runner-chart.git \
&& cd openshift-actions-runner-chart
```
4. Install the helm chart, which creates a deployment and a secret. Leave out `githubRepository` if you want an organization-scoped runner.

```bash
# PAT from step 2. Be careful about exporting this into your shell and history.
export GITHUB_PAT=c0ffeeface1234567890
# For an org runner, this is the org.
# For a repo runner, this is the repo owner.
export GITHUB_OWNER=redhat-actions
# For an org runner, omit this argument (or leave it blank).
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

## Creating your own runner image
See the [OpenShift Actions Runner README](https://github.com/redhat-actions/openshift-action-runners#README.md).

## Managing PATs
See [the wiki](https://github.com/redhat-actions/openshift-actions-runner-chart/wiki/Managing-PATs) for a note on managing mulitple PATs, if you want to add a new PAT or replace an existing one.
