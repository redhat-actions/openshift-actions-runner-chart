# OpenShift GitHub Actions Runner Chart

[![Helm Lint](https://github.com/boris-ning-usds/openshift-actions-runner-chart/workflows/Helm%20Lint/badge.svg)](https://github.com/boris-ning-usds/openshift-actions-runner-chart/actions)
[![Link checker](https://github.com/boris-ning-usds/openshift-actions-runner-chart/workflows/Link%20checker/badge.svg)](https://github.com/boris-ning-usds/openshift-actions-runner-chart/actions)
[![Publish chart to Pages](https://github.com/boris-ning-usds/openshift-actions-runner-chart/workflows/Publish%20chart%20to%20Pages/badge.svg)](https://github.com/boris-ning-usds/openshift-actions-runner-chart/actions)

[![Tag](https://img.shields.io/github/v/tag/boris-ning-usds/openshift-actions-runner-chart)](https://github.com/redhat-actions/openshift-actions-runner-chart/tags)
[![Quay org](https://img.shields.io/badge/quay-redhat--github--actions-red)](https://quay.io/organization/redhat-github-actions)

This repository contains a [forked Helm chart](https://github.com/redhat-actions/openshift-actions-runner-chart) for deploying one or more self-hosted <!-- markdown-link-check-disable --> [GitHub Actions Runners](<(https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)>) <!-- markdown-link-check-enable -->
into a Kubernetes cluster. By default, the container image used is the [**OpenShift Actions Runner**](https://github.com/redhat-actions/openshift-actions-runner).

You can deploy runners automatically in an Actions workflow using the [**OpenShift Actions Runner Installer**](https://github.com/redhat-actions/openshift-actions-runner-installer).

While this chart and the images are developed for and tested on OpenShift, they do not contain any OpenShift specific code and should be compatible with any Kubernetes platform.

## Deploying New Version

Deploying a new [chart version](https://boris-ning-usds.github.io/openshift-actions-runner-chart) involves manually creating a new tag.

- `git tag` - view all outstanding tags
- `git tag v1.0.x` - to create a tag for v1.0.x
- `git push --tags` - to push the new tag for deployment

## Forked Modifications

- Removed CPU limits from [values.yaml](./values.yaml) and [deployment.yaml](./templates/deployment.yaml) to allow burstable usage of Github action runners.
- Updated Github actions to use the latest actions.

## Prerequisites

You must have access to a Kubernetes cluster. Visit [openshift.com/try](https://www.openshift.com/try) or sign up for our [Developer Sandbox](https://developers.redhat.com/developer-sandbox).

You must have Helm 3 installed.

You do **not** need cluster administrator privileges to deploy the runners and run workloads. However, some images or tools may require special permissions.

## Helm repository

This GitHub repository serves a Helm repository through GitHub Pages.

The repository can be added with:

```
helm repo add openshift-actions-runner https://boris-ning-usds.github.io/openshift-actions-runner-chart
```

The packaged charts can be browsed [here](https://github.com/boris-ning-usds/openshift-actions-runner-chart/tree/release-chart/packages).

## Installing runners

You can install runners into your cluster using the Helm chart in this repository.

1. Runners can be scoped to an **organization** or a **repository**. Decide what the scope of your runner will be.
   - User-scoped runners are not supported by GitHub.
2. Determine how you will authorize the runner creation in GitHub. Choose one of the following:

   a. Create a GitHub Personal Access Token as per the PAT instructions in the [runner image README](https://github.com/redhat-actions/openshift-actions-runner#pat-guidelines).

   b. Create a GitHub App and install into your org or user account as per the app instructions in the [runner image README](https://github.com/redhat-actions/openshift-actions-runners/blob/main/docs/github-app-authentication.md).

- Note that the default `secrets.GITHUB_TOKEN` **does not** have permission to manage self-hosted runners. See [Permissions for the GITHUB_TOKEN](https://docs.github.com/en/actions/reference/authentication-in-a-workflow#permissions-for-the-github_token).

3. Add this repository as a Helm repository.

```bash
helm repo add openshift-actions-runner \
    https://boris-ning-usds.github.io/openshift-actions-runner-chart \
&& helm repo update
```

You can also clone this repository and reference the chart's directory. This allows you to modify the chart if necessary.

4. Install the helm chart, which creates a deployment and a secret. Leave out `githubRepository` if you want an organization-scoped runner.
   - Add the `--namespace` argument to all `helm` and `kubectl/oc` commands if you want to use a namespace other than your current context's namespace.

```bash
# Authorization from Step 2:
# Either GITHUB_PAT, OR all 3 of GITHUB_APP_*
export GITHUB_PAT=c0ffeeface1234567890
# OR, GitHub App information:
export GITHUB_APP_ID=123456
export GITHUB_APP_INSTALL_ID=7890123
export GITHUB_APP_PEM='----------BEGIN RSA PRIVATE KEY...'

# For an org runner, this is the org.
# For a repo runner, this is the repo owner (org or user).
export GITHUB_OWNER=redhat-actions
# For an org runner, omit this argument.
# For a repo runner, the repo name.
export GITHUB_REPO=openshift-actions-runner-chart
# Helm release name to use.
export RELEASE_NAME=actions-runner

# If you cloned the repository (eg. to edit the chart)
# replace openshift-actions-runner/actions-runner below with the directory containing Chart.yaml.

# Installing using PAT Auth
helm install $RELEASE_NAME openshift-actions-runner/actions-runner \
    --set-string githubPat=$GITHUB_PAT \
    --set-string githubOwner=$GITHUB_OWNER \
    --set-string githubRepository=$GITHUB_REPO \
&& echo "---------------------------------------" \
&& helm get manifest $RELEASE_NAME | kubectl get -f -

# OR, Installing using App Auth
helm install $RELEASE_NAME openshift-actions-runner/actions-runner \
    --set-string githubAppId=$GITHUB_APP_ID \
    --set-string githubAppInstallId=$GITHUB_APP_INSTALL_ID \
    --set-string githubAppPem="$GITHUB_APP_PEM" \
    --set-string githubOwner=$GITHUB_OWNER \
    --set-string githubRepository=$GITHUB_REPO \
&& echo "---------------------------------------" \
&& helm get manifest $RELEASE_NAME | kubectl get -f -
```

5. You can re-run step 4 if you want to add runners with different images, labels, etc. You can leave out the `githubPat` or `githubApp*` strings on subsequent runs, since the chart will re-use an existing secret.

The runners should show up under `Settings > Actions > Self-hosted runners` shortly afterward.

## Values

You can override the default values such as resource limits and replica counts or inject environment variables by passing `--set` or `--set-string` to the `helm install` command.

Refer to the [`values.yaml`](./values.yaml) for values that can be overridden.

## Using your own runner image

Refer to [Building your own runner image](https://github.com/redhat-actions/openshift-actions-runner/tree/main/base#own-image).

## GitHub Enterprise Support

Use `--set githubDomain=github.mycompany.com`.

Refer to the [OpenShift Actions Runner README](https://github.com/redhat-actions/openshift-actions-runner#enterprise-support).

## Managing PATs

See [the wiki](https://github.com/redhat-actions/openshift-actions-runner-chart/wiki/Managing-PATs) for a note on managing mulitple PATs, if you want to add a new PAT or replace an existing one.

## Troubleshooting

You can view the resources created by Helm using `helm get manifest $RELEASE_NAME`, and then inspect those resources using `kubectl get`.

The resources are also labeled with `app.kubernetes.io/instance={{ .Release.Name }}`, so you can view all the resources with:

```sh
kubectl get all,secret -l=app.kubernetes.io/instance=$RELEASE_NAME
```

If the pods are created but stuck in a crash loop, view the logs with `kubectl logs <podname>` to see the problem. Refer to the [runner container troubleshooting](https://github.com/redhat-actions/openshift-actions-runner#troubleshooting) to resolve any issues.
