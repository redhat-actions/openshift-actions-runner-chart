# OpenShift GitHub Action Runners

[![Update Runner Images](https://github.com/redhat-actions/openshift-self-hosted-runner/workflows/Update%20Runner%20Images/badge.svg)](https://github.com/redhat-actions/openshift-self-hosted-runner/actions)
[![Helm Lint](https://github.com/redhat-actions/openshift-self-hosted-runner/workflows/Helm%20Lint/badge.svg)](https://github.com/redhat-actions/openshift-self-hosted-runner/actions)

[![Tag](https://img.shields.io/github/v/tag/redhat-actions/openshift-self-hosted-runner)](https://github.com/redhat-actions/openshift-self-hosted-runner/tags)
[![Quay org](https://img.shields.io/badge/quay-redhat--github--actions-red)](https://quay.io/organization/redhat-github-actions)

This repository contains tools for building and deploying containers in an OpenShift cluster that act as [self-hosted GitHub Action runners](https://docs.github.com/en/free-pro-team@latest/actions/hosting-your-own-runners/about-self-hosted-runners).

See [`runners/base`](./runners/base) for the base runner.

See [`runners/buildah`](./runners/buildah) for a Dockerfile which builds on the base runner to add buildah and podman - [with caveats](./runners/buildah/README.md).

The idea is that the base runner [can be extended](#creating-your-own-runner-image) to build larger, more complex images that have additional capabilities.

The images are hosted at [quay.io/redhat-github-actions](https://quay.io/redhat-github-actions/).

## Prerequisites
You must have access to an OpenShift cluster. Visit [openshift.com/try](https://www.openshift.com/try) or sign up for our [Developer Sandbox](https://developers.redhat.com/developer-sandbox).

You do **not** need cluster administrator privileges to deploy the base runner and run workloads.

## Installing runners

You can install runners into your cluster using the Helm chart in [actions-runner](./actions-runner).

1. Runners can be scoped to an organization or a repository. Decide what the scope of your runner will be.
2. [Create a GitHub Personal Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) (PAT) which has the `repo` permission scope.
    - The user who created the token must have administrator permission on the repository/organization the runner will be added to.
    - If the runner will be for the **organization**, the token must also have the `admin:org` permission scope.
3. Clone this repository and `cd` into it:
```bash
git clone git@github.com:redhat-actions/openshift-self-hosted-runner.git \
&& cd openshift-self-hosted-runner
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
export GITHUB_REPO=openshift-self-hosted-runner
# Helm release name to use.
export RELEASE_NAME=actions-runner

helm install $RELEASE_NAME ./actions-runner/ \
    --set-string githubPat=$GITHUB_PAT \
    --set-string githubOwner=$GITHUB_OWNER \
    --set-string githubRepository=$GITHUB_REPO \
&& echo "---------------------------------------" \
&& helm get manifest $RELEASE_NAME | kubectl get -f -
```

5. You can re-run step 4 if you want to add runners with different images, labels, etc. You can leave out the `githubPat` on subsequent runs, since the secret will be left out if it exists already. See [Managing PATs](#managing-pats) if you want to add or update PATs.

For other configuration options such as resource limits and replica counts, see [`values.yaml`](./actions-runner/values.yaml). The [`Dockerfile`](./runners/base/Dockerfile) also lists some environment variables you can override through the Helm values.

The runners should show up under `Settings > Actions > Self-hosted runners` shortly afterward.

When the runner pods are terminated for any reason, they should remove themselves from the repository's self-hosted runner list. See [entrypoint.sh](./runners/base/entrypoint.sh).

## Creating your own runner image

You can create your own runner image based on this one, and install any runtimes and tools your workflows need.

1. Create your own Dockerfile, with `FROM quay.io/redhat-github-actions/runner:<tag>`.
2. Edit the Dockerfile to install and set up your tools, environment, etc. Do not override the `ENTRYPOINT`.
3. Build and push your new runner image.
4. Run the `helm install` as above, but set the value `runnerImage` to your image, and `runnerTag` to your tag.

## Managing PATs

### Adding a PAT to an existing secret

You can add more PATs to the secret without having to create a new one.

First, base64 encode the new PAT.
```sh
echo -n "$GITHUB_PAT" | base64
```

Then, patch the new PAT into the existing secret. Give it a different key name than any secret key that is already in use, or you will overwrite the existing value.

Here, our secret is named `github-pat`, and we want to name the new PAT `new-pat`.

```sh
oc patch secret github-pat -p '{ "data": { "new-pat": "<base64 encoded PAT>" } }'
```

Then, when you re-run step 4, `--set secretKey="new-pat"` so the new PAT is used for the new runner.

### Changing an existing PAT

The procedure above for adding a PAT also works for changing existing PATs to new ones - eg, to replace a revoked PAT with a working one.

Instead of selecting a new secret key name to patch in, just patch the existing secret key that you want to modify. This is determined by the `secretKey` value.

Note that existing pods will have to be terminated to be re-created with the new PAT.

## Credits
This repository builds on the work done in [bbrowning/github-runner](https://github.com/bbrowning/github-runner), which is forked from [SanderKnape/github-runner](https://github.com/SanderKnape/github-runner).
