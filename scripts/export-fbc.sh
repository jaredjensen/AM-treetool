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

function save-node() {
  NODE_TYPE=$(lower $1)
  NODE_ID=$2
  NODE_FOLDER="${REALM_FOLDER}/${NODE_TYPE}/1.0/organizationconfig/default"
  NODE_PATH="${NODE_FOLDER}/$NODE_ID.json"

  SRC="${AM_POD}:/home/forgerock/openam/config/services/realm/${NODE_PATH}"
  DST="${TARGET_DIR}/${NODE_PATH}"

  echo "Fetching ${SRC}"

  mkdir -p "${TARGET_DIR}/${NODE_FOLDER}"
  kubectl cp $SRC $DST -n fr-platform -c openam
  
  # Fetch associated script, if any
  SCRIPT_ID="$(jq -r '.data.script' $DST)"
  if [[ "${SCRIPT_ID}" != 'null' ]]; then
    save-script $SCRIPT_ID
  fi

  # Determine how child nodes are serialized
  CHILD_NODES_TYPE="$(jq -r '.data.nodes | type' $DST)"
  case $CHILD_NODES_TYPE in
    'null')
      ;;

    'array')
      jq -rc '.data.nodes[]' $DST | while IFS='' read node; do
        guid=$(echo $node | cut -f1 -d:)
        nodeType=$(echo $node | cut -f2 -d:)
        save-node $nodeType $guid
      done
      ;;

    'object')
      jq -rc '.data.nodes | keys[] as $k | "\($k)=\(.[$k] | .nodeType)"' $DST | while IFS='' read node; do
        guid=$(echo $node | cut -f1 -d=)
        nodeType=$(echo $node | cut -f2 -d=)
        save-node $nodeType $guid
      done
      ;;

    *)
      echo "Unsupported child nodes format: ${CHILD_NODES_TYPE}"
      exit 1
      ;;
  esac
}

function save-script() {
  SCRIPT_ID=$1
  SCRIPT_FOLDER="${REALM_FOLDER}/scriptingservice/1.0/organizationconfig/default/scriptconfigurations"
  SCRIPT_PATH="${SCRIPT_FOLDER}/${SCRIPT_ID}.json"
  # SCRIPT_NAME="foo"
  # SCRIPT_SRC_PATH="${SCRIPT_FOLDER}/${SCRIPT_ID}.javascript"

  SRC="${AM_POD}:/home/forgerock/openam/config/services/realm/${SCRIPT_PATH}"
  DST="${TARGET_DIR}/${SCRIPT_PATH}"

  echo "Fetching ${SRC}"

  mkdir -p "${TARGET_DIR}/${SCRIPT_FOLDER}"
  kubectl cp $SRC $DST -n fr-platform -c openam
}

# Save the tree file
save-node authenticationtreesservice $(lower $TREE_NAME)