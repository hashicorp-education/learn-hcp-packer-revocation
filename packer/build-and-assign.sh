#!/bin/bash

set -eEo pipefail

# Usage check
if [[ -z "$HCP_CLIENT_ID" || -z "$HCP_CLIENT_SECRET" || -z "$HCP_ORGANIZATION_ID" || -z "$HCP_PROJECT_ID" ]]; then
  cat <<EOF
This script requires the following environment variables to be set:
 - HCP_CLIENT_ID
 - HCP_CLIENT_SECRET
 - HCP_ORGANIZATION_ID
 - HCP_PROJECT_ID
EOF
  exit 1
fi

update_channel() {
  bucket_slug=$1
  channel_name=$2
  base_url="https://api.cloud.hashicorp.com/packer/2021-04-30/organizations/$HCP_ORGANIZATION_ID/projects/$HCP_PROJECT_ID"

  response=$(curl --request GET --silent \
    --url "$base_url/images/$bucket_slug/iterations" \
    --header "authorization: Bearer $bearer")
  api_error=$(echo "$response" | jq -r '.message')
  if [ "$api_error" != null ]; then
    # Failed to list iterations
    echo "Failed to list iterations: $api_error"
    exit 1
  else
    iteration_id=$(echo "$response" | jq -r '.iterations[0].id')
  fi

  response=$(curl --request GET --silent \
    --url "$base_url/images/$bucket_slug/channels/$channel_name" \
    --header "authorization: Bearer $bearer")
  api_error=$(echo "$response" | jq -r '.message')
  if [ "$api_error" != null ]; then
    # Channel likely doesn't exist, create it
    api_error=$(curl --request POST --silent \
      --url "$base_url/images/$bucket_slug/channels" \
      --data-raw '{"slug":"'"$channel_name"'"}' \
      --header "authorization: Bearer $bearer" | jq -r '.error')
    if [ "$api_error" != null ]; then
      echo "Error creating channel: $api_error"
      exit 1
    fi
  fi

  # Update channel to point to iteration
  api_error=$(curl --request PATCH --silent \
    --url "$base_url/images/$bucket_slug/channels/$channel_name" \
    --data-raw '{"iteration_id":"'"$iteration_id"'"}' \
    --header "authorization: Bearer $bearer" | jq -r '.message')
  if [ "$api_error" != null ]; then
      echo "Error updating channel: $api_error"
      exit 1
  fi
}


# Authenticate and get bearer token for subsequent API calls
response=$(curl --request POST --silent \
  --url 'https://auth.hashicorp.com/oauth/token' \
  --data grant_type=client_credentials \
  --data client_id="$HCP_CLIENT_ID" \
  --data client_secret="$HCP_CLIENT_SECRET" \
  --data audience="https://api.hashicorp.cloud")
api_error=$(echo "$response" | jq -r '.error')
if [ "$api_error" != null ]; then
  echo "Failed to get access token: $api_error"
  exit 1
fi
bearer=$(echo "$response" | jq -r '.access_token')


packer init parent-east.pkr.hcl

echo "Building parent images"
export HCP_PACKER_BUILD_FINGERPRINT=$(date +%s)
packer build parent-east.pkr.hcl &
packer build parent-west.pkr.hcl &
wait


echo "SETTING US-EAST-2 PARENT CHANNEL"
bucket_slug="learn-revocation-parent-us-east-2"
update_channel $bucket_slug production

echo "SETTING US-WEST-2 PARENT CHANNEL"
bucket_slug="learn-revocation-parent-us-west-2"
update_channel $bucket_slug production

echo "BUILDING CHILD IMAGE"
export HCP_PACKER_BUILD_FINGERPRINT=$(date +%s)
packer build child.pkr.hcl
echo "SETTING CHILD CHANNEL"
bucket_slug="learn-revocation-child"
update_channel $bucket_slug production

echo "DONE"
