# OpenShift Hosted GitHub Action Runners

This repository contains tools for building and deploying containers in an OpenShift cluster that act as [self-hosted GitHub Action runners](https://docs.github.com/en/free-pro-team@latest/actions/hosting-your-own-runners/about-self-hosted-runners).

See [`runners/base`](./runners/base) for the base runner.

See [`runners/buildah`](./runners/buildah) for a Dockerfile which builds on the base runner to add buildah and podman - [with caveats](./runners/buildah/README.md).

The idea is that the base runner [can be extended](#creating-your-own-runner-image) to build larger, more complex images that have additional capabilities.

The images are hosted at [quay.io/redhat-github-actions](https://quay.io/redhat-github-actions/).

## Prerequisites
You must have access to an OpenShift cluster. Visit [openshift.com/try](https://www.openshift.com/try) or sign up for our [Developer Sandbox](https://developers.redhat.com/developer-sandbox).

You do **not** need cluster administrator privileges to deploy the base runner and run workloads.

## Installing runners using Helm

You can install the runner into your cluster using the Helm chart in this repository.

1. Runners can be scoped to an organization or a repository. Decide what the scope of your runner will be.
2. [Create a GitHub Personal Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) (PAT) which has the `repo` permission scope.
    - The user who created the token must have administrator permission on the repository/organization the runner will be added to.
    - If the runner will be organization-scoped, the token must also have the `admin:org` scope.
    - This will be stored in [a Kubernetes secret](./runner-charts/pat-secret).
    - Make sure the cluster or namespace you are installing into is sufficiently secure, since anyone who can describe the secret or shell into the container can read your token.
3. Clone this repository and `cd` into it:
```bash
git clone git@github.com:redhat-actions/openshift-hosted-runner.git && \
    cd openshift-hosted-runner
```
4. Create the PAT secret.
```bash
helm install runner-pat ./runner-charts/pat-secret \
    --set-string githubPat=<PAT from step 2>
```
5. Install the deployment helm chart. Leave out `githubRepository` if you want an organization-scoped runner.

```bash
helm install runner ./runner-charts/deployment \
    --set-string githubOwner=<GitHub user or org> \
    --set-string githubRepository=<repo to add runner to>
```

6. You can re-run step 5 if you want to add runners with different images, labels, etc.

For other configuration options, see [`values.yaml`](./runner-charts/deployment/values.yaml). The [`Dockerfile`](./runners/base/Dockerfile) also lists some environment variables you can override through the Helm values.

After the helm install, run `oc get po -w` to make sure your runner pod(s) come up successfully. The runners should show up under `Settings > Actions > Self-hosted runners` shortly afterward.

When the runner pods are terminated for any reason, they should remove themselves from the repository's self-hosted runner list. See [entrypoint.sh](./runners/base/entrypoint.sh).

## Creating your own runner image

You can create your own runner image based on this one, and install any runtimes and tools your workflows need.

1. Create your own Dockerfile, with `FROM quay.io/redhat-github-actions/redhat-actions-runner:<tag>`.
2. Edit the Dockerfile to install and set up your tools, environment, etc. Do not override the `ENTRYPOINT`.
3. Build and push your new runner image.
4. Run the `helm install` as above, but set `runnerImage` to your image, and `runnerTag` to your tag.

## Credits
This repository builds on the work done in [bbrowning/github-runner](https://github.com/bbrowning/github-runner), which is forked from [SanderKnape/github-runner](https://github.com/SanderKnape/github-runner).
