# OpenShift Hosted GitHub Action Runners

This repository contains tools for building and deploying container images to run GitHub self-hosted runners within an OpenShift cluster.

See [`runners/base`](./runners/base) for the base Action runner.

See [`runners/buildah`](./runners/buildah) for a Dockerfile which builds on the base runner to add buildah and podman (with caveats - see [the README](./runners/buildah/README.md) under that directory).

The idea is that the base runner can be extended to build larger, more complex images that have additional capabilities.

## Helm Chart

You can install the runner into your cluster using the Helm chart in this repository.

Set `githubPat` to a GitHub Personal Access Token which must have the `repo` permission scope. This will be stored in [a Kubernetes secret](./runner-chart/templates/pat-secret.yaml).

Set the `githubOwner` and `githubRepository` to the values for the repository you want to register the runner on.

```bash
helm install runner ./runner-chart \
    --set-string githubPat=<your github PAT with repo permission> \
    --set-string githubOwner=<GitHub user/org for the repo or your org> \
    --set-string githubRepository=<repo to add runner to>
```

For other configuration options, see [`values.yaml`](./runner-chart/values.yaml).

After the helm install, run `oc get po -w` to make sure your runner pod(s) come up successfully. The runners should show up under `Settings > Actions > Self-hosted runners` shortly afterward.

When the runner pods are terminated for any reason, they should remove themselves from the repository's self-hosted runner list. See [entrypoint.sh](./runners/base/entrypoint.sh).

## Credits
This repository builds on the work done in [bbrowning/github-runner](https://github.com/bbrowning/github-runner), which is forked from [SanderKnape/github-runner](https://github.com/SanderKnape/github-runner).
