
#!/bin/sh
# source: https://github.com/bbrowning/github-runner/blob/master/entrypoint.sh

set -eE -o pipefail

./uid.sh

# https://docs.github.com/en/free-pro-team@latest/rest/reference/actions#self-hosted-runners

registration_url="https://github.com/${GITHUB_OWNER}"
if [ -z "${RUNNER_TOKEN:-}" ]; then
    if [ -z "${GITHUB_REPOSITORY}" ]; then
        token_url="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token"
    else
        token_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
        registration_url="${registration_url}/${GITHUB_REPOSITORY}"
    fi
    echo "Requesting token at '${token_url}'"

    payload=$(curl -sSfLX POST -H "Authorization: token ${GITHUB_PAT}" ${token_url})
    export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)
    echo "Obtained token"
else
    echo "Using RUNNER_TOKEN from environment"
fi

./config.sh \
    --name $(hostname) \
    --token ${RUNNER_TOKEN} \
    --url ${registration_url} \
    --work ${RUNNER_WORKDIR} \
    --labels ${RUNNER_LABELS} \
    --unattended \
    --replace

remove() {
    payload=$(curl -sSfLX POST -H "Authorization: token ${GITHUB_PAT}" ${token_url%/registration-token}/remove-token)
    export REMOVE_TOKEN=$(echo $payload | jq .token --raw-output)

    ./config.sh remove --unattended --token "${REMOVE_TOKEN}"
}

trap 'remove; exit 130' INT
trap 'remove; exit 143' TERM

./bin/runsvc.sh "$*" &

wait $!
