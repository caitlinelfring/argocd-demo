#!/bin/bash

test -r .env && source .env

echo "WARNING: This will delete all existing webhooks in your repo!"
echo

if [ -z "${GITHUB_ACCESS_TOKEN}" ]; then echo "GITHUB_ACCESS_TOKEN env var required!"; exit 1; fi
if [ -z "${GITHUB_REPO}" ]; then echo "GITHUB_REPO env var required! (ie caitlin615/argocd-repo)"; exit 1; fi

HOOK_HOST=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
if [ -z "${HOOK_HOST}" ]; then
    echo "ngrok not started. Start with 'ngrok http 8080'"
    exit 1
fi

function createHook {
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

    curl -s -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -X POST \
        -d "${HOOK_BODY}" \
        "https://api.github.com/repos/${GITHUB_REPO}/hooks"
}

function deleteHooks {
    # https://developer.github.com/v3/repos/hooks/#delete-a-hook
    for i in $(curl -s -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${GITHUB_REPO}/hooks" | jq -r '.[].id' ); do

        curl -s -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            -X DELETE \
            "https://api.github.com/repos/${GITHUB_REPO}/hooks/$i"
    done
}

if [ "${1}" == "delete" ]; then
    deleteHooks
else
    deleteHooks
    createHook
fi
