#!/usr/bin/env bash

TREE_NAME=$1
TARGET_DIR=${2:-../fbc}
REALM_FOLDER=${3:-root}

if [ -z $TREE_NAME ]; then
  echo 'No tree name was specified.'
  exit 1
fi

AM_POD=$(kubectl get pods -n fr-platform | grep am- | sed 's/\(am[^ ]*\).*/\1/' | head -n 1)
echo "Saving tree ${TREE_NAME} to ${TARGET_DIR} using AM pod ${AM_POD}"

function lower() {
  echo $1 | awk '{print tolower($0)}'
}

function fetch() {
  local src=$1
  local dst=$2
  echo "Fetching ${src}"
  mkdir -p $(dirname $dst)
  kubectl cp $src $dst -n fr-platform -c openam
}

function save-node() {
  local nodeType=$(lower $1)
  local nodeId=$2
  local nodeFolder="${REALM_FOLDER}/${nodeType}/1.0/organizationconfig/default"
  local nodePath="${nodeFolder}/$nodeId.json"

  local src="${AM_POD}:/home/forgerock/openam/config/services/realm/${nodePath}"
  local dst="${TARGET_DIR}/${nodePath}"
  fetch $src $dst
  
  # Fetch associated script, if any
  local scriptId="$(jq -r '.data.script' $dst)"
  if [[ "${scriptId}" != 'null' ]]; then
    save-script $scriptId
  fi

  # Determine how child nodes are serialized
  local childNodesType="$(jq -r '.data.nodes | type' $dst)"
  case $childNodesType in
    'null')
      ;;

    'array')
      jq -rc '.data.nodes[]' $dst | while IFS='' read node; do
        local guid=$(echo $node | cut -f1 -d:)
        local nodeType=$(echo $node | cut -f2 -d:)
        save-node $nodeType $guid
      done
      ;;

    'object')
      jq -rc '.data.nodes | keys[] as $k | "\($k)=\(.[$k] | .nodeType)"' $dst | while IFS='' read node; do
        local guid=$(echo $node | cut -f1 -d=)
        local nodeType=$(echo $node | cut -f2 -d=)
        save-node $nodeType $guid
      done
      ;;

    *)
      echo "Unsupported child nodes format: '${childNodesType}'"
      exit 1
      ;;
  esac
}

function save-script() {
  local scriptId=$1
  local scriptFolder="${REALM_FOLDER}/scriptingservice/1.0/organizationconfig/default/scriptconfigurations"
  local scriptPath="${scriptFolder}/${scriptId}.json"

  local src="${AM_POD}:/home/forgerock/openam/config/services/realm/${scriptPath}"
  local dst="${TARGET_DIR}/${scriptPath}"
  fetch $src $dst

  local scriptType="$(jq -r '.data.script | type' $dst)"
  local scriptName=$(jq -r '.data.name' $dst)
  case $scriptType in
    'string')
      # Convert inline script to external
      local scriptFilename="$(lower $scriptName).javascript"
      scriptPath="${scriptFolder}/${scriptFilename}"
      local js="${TARGET_DIR}/${scriptPath}"
      jq -r '.data.script' $dst | base64 --decode > $js
      # Update the node to reference the external script
      jq --arg filename $scriptFilename '.data.script = { "$base64:encode": { "$inline": $filename } }' $dst > "${dst}.tmp" && mv "${dst}.tmp" $dst
      ;;

    'object')
      # Fetch the external script
      local scriptFilename=$(jq -r '.data.script["$base64:encode"]["$inline"]' $dst)
      scriptPath="${scriptFolder}/${scriptFilename}"
      src="${AM_POD}:/home/forgerock/openam/config/services/realm/${scriptPath}"
      dst="${TARGET_DIR}/${scriptPath}"
      fetch $src $dst
      ;;

    *)
      echo "Unsupported script format: '${scriptType}'"
      exit 1
      ;;
  esac  
}

# Save the tree file
save-node authenticationtreesservice $(lower $TREE_NAME)