#!/bin/sh

search_dir=.
for entry in "$search_dir"/*
do
    if [ $entry != "./site" -a $entry != "./sh" -a $entry != "./Makefile" ]
    then
        rm -rf $entry
    fi
done

# put files in ./site into root and delete original
cp -rf site/* .

rm -rf site