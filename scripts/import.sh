source .env

FILE_NAME=$1
TREE_NAME=$2
REALM=$3

if [ -z $FILE_NAME ]; then
  echo 'No file was specified.'
  exit 1
fi

if [ -z $TREE_NAME ]; then
  echo 'No tree name was specified.'
  exit 1
fi

if [ -z $REALM ]; then
  REALM=/
fi

../amtree.sh -h $AM_URL -u amadmin -p $AM_PASSWORD -i -t $TREE_NAME -r $REALM -f $FILE_NAME