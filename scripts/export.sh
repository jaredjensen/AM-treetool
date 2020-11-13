source .env

TREE_NAME=$1
REALM=$2

if [ -z $TREE_NAME ]; then
  echo 'No tree name was specified.'
  exit 1
fi

if [ -z $REALM ]; then
  REALM=/
fi

TARGET_DIR=../trees
mkdir -p $TARGET_DIR

../amtree.sh -h $AM_URL -u amadmin -p $AM_PASSWORD -e -t $TREE_NAME -r $REALM -f "$TARGET_DIR/$TREE_NAME.json"