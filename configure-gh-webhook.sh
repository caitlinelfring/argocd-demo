#!/bin/bash

test -r .env && source .env

if [ -z "${GITHUB_ACCESS_TOKEN}" ]; then echo "GITHUB_ACCESS_TOKEN env var required!"; exit 1; fi
if [ -z "${GITHUB_REPOS}" ]; then echo "GITHUB_REPOS env var required! should be space-separated list (ie 'caitlin615/argocd-repo caitlin615/argocd-apps')"; exit 1; fi

echo "WARNING: This will delete all existing 'ngrok.io/api/webhook' webhooks in github repos: ${GITHUB_REPOS}!"
echo

GITHUB_REPOS_ARRAY=(${GITHUB_REPOS})

function createHook {
    HOOK_HOST=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
    if [ -z "${HOOK_HOST}" ]; then
        echo "ngrok not started. Start with 'ngrok http 8080'"
        exit 1
    fi
    # https://developer.github.com/v3/repos/hooks/#create-a-hook
    HOOK_URL="${HOOK_HOST}/api/webhook"

    HOOK_BODY=$(echo '{
    "name": "web",
    "active": true,
    "events": ["push"],
    "config": {
        "url": "'"${HOOK_URL}"'",
        "content_type": "json",
        "insecure_ssl": "0"
    }
    }' | jq -cr .)

    for REPO in "${GITHUB_REPOS_ARRAY[@]}"; do
        curl -s -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            -X POST \
            -d "${HOOK_BODY}" \
            "https://api.github.com/repos/${REPO}/hooks"
    done
}

function deleteHooks {
    for REPO in "${GITHUB_REPOS_ARRAY[@]}"; do
        # https://developer.github.com/v3/repos/hooks/#delete-a-hook
        for hook in $(curl -s -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${REPO}/hooks" | \
            jq -r '.[] | select(.config.url | endswith(".ngrok.io/api/webhook")) | .id' ); do

            curl -s -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
                -H "Accept: application/vnd.github.v3+json" \
                -X DELETE \
                "https://api.github.com/repos/${REPO}/hooks/$hook"
        done
    done
}

if [ "${1}" == "delete" ]; then
    deleteHooks
else
    deleteHooks
    createHook
fi
