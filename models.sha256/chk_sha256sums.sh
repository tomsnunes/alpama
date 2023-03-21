#!/bin/bash

FNAME="checklist.sha256"

if ! [ -x "$(command -v sha256sum)" ]; then
    echo 'Error: sha256sum is not installed.' >&2
    exit 1
fi

CURR_DIR=${PWD##*/}
if [ "$CURR_DIR" != "models.sha256" ]; then
    echo "Please run $0 in the dir ./models.sha256"
    exit 2
fi

cd ..
BASE_DIR=$PWD
if ! [ -d models -o -L models ]; then
    echo "Error: please move or symlink models into $BASE_DIR/models dir before running this script."
    exit 3
fi

cd models
for D in *B; do
    if ! [ -d $D ]; then
        echo "Warning: $D is not a dir. Skipping."
    else
        cd $D
        echo "Computing sha256sums for model: $D (Please be patient. This can take a lot of llamas to run..)"
        sha256sum *.pth *.bin* *.json > $FNAME
        diff -s $FNAME $BASE_DIR/models.sha256/$D/$FNAME
        cd ..
    fi
done
