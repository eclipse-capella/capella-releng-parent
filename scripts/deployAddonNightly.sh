#!/bin/bash

SERVER=genie.capella@projects-storage.eclipse.org
SERVER_BASEPATH=/home/data/httpd/download.eclipse.org/capella/addons

usage() {
    1>&2 echo "Usage: $0 -n ADDON_NAME -b BRANCH"
    1>&2 echo
    1>&2 echo "Example: $0 -n vpms -b v1.3.x will copy to d.e.org/capella/addons/vpms/updates/nightly/v1.3.x/"
}

exit_abnormal() {                              
    usage
    exit 1
}

while getopts ":n:b:" options
do
    case "${options}" in                          
	n)                                        
	    ADDON=${OPTARG}                        
	    ;;
	b)
	    BRANCH=${OPTARG}                      
	    ;;
	:)
	    1>&2 echo "Error: -${OPTARG} requires an argument."
	    exit_abnormal
	    ;;
	*)                                     
	    exit_abnormal
	    ;;
    esac
done

if [[ -z "$ADDON" || -z "$BRANCH" ]]
then
    exit_abnormal
fi

CATEGORY_FILE=$(find -path "*/target/category.xml")

if [[ -z "$CATEGORY_FILE" ]]
then
    >&2 echo "Could not find category.xml file"
    exit 1
fi

if [[ $(echo "$CATEGORY_FILE" | wc -l) -ne 1 ]]
then
    >&2 echo "Can only handle one category.xml, but found more than one:"
    >&2 echo "$CATEGORY_FILE"
    exit 1
fi

SITE_DIR=$(dirname $CATEGORY_FILE)
SITE_ZIP=$(ls -1 "$SITE_DIR"/*-site-*.zip)
DROPINS_ZIP=$(ls -1 "$SITE_DIR"/*-dropins-*.zip)

if [[ -z "$SITE_ZIP" ]]
then
    >&2 echo "Cannot locate site zip file"
    exit 1
fi
    
if [[ $(echo "$SITE_ZIP" | wc -l) -ne 1 ]]
then
    >&2 echo "Can only handle one site zip file, but found more than one:"
    >&2 echo "$SITE_ZIP"
    exit 1
fi

TIMESTAMP=$(echo "$SITE_ZIP" | perl -ne 'print $1 if /(\d+\.\d+\.\d+\.\d+).zip$/ or die')
if [[ $? -ne 0 ]]
then
    >&2 echo "Cannot extract timestamp from site archive: $SITE_ZIP"
    exit 1
fi

echo Branch name: $BRANCH
echo Addon name: $ADDON
echo Timestamp: $TIMESTAMP
echo Site dir: $SITE_DIR
echo Site zip: $SITE_ZIP

[[ -n $DROPINS_ZIP ]] && echo Dropins zip: $DROPINS_ZIP

BRANCH_DST="$SERVER_BASEPATH/$ADDON/updates/nightly/$BRANCH"
SITE_DST="$BRANCH_DST/$TIMESTAMP"
LINK_DST="$BRANCH_DST/latest"
SITE_ZIP_DST="$SERVER_BASEPATH/$ADDON/zips/nightly/$BRANCH/"
SITE_FILES="$SITE_DIR"/repository/*

set -x
ssh $SERVER mkdir -p "$SITE_DST" || exit 1
scp -pr $SITE_FILES $SERVER:"$SITE_DST" || exit 1
ssh $SERVER ln -snf "$SITE_DST" "$LINK_DST" || exit 1

ssh $SERVER mkdir -p "$SITE_ZIP_DST" || exit 1
scp "$SITE_ZIP" $SERVER:"$SITE_ZIP_DST" || exit 1


if [[ -n "$DROPINS_ZIP" ]] 
then 
	scp "$DROPINS_ZIP" $SERVER:"$SITE_ZIP_DST" || exit 1
fi

true