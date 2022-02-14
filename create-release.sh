#!/usr/bin/env sh

# Copyright (c) 2018 - 2022, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

####
# This script produces a .zip-file in accordance to the requirements for CTAN.
# For more information see https://ctan.org/help/upload-pkg.
####

# Halt on error
set -e

## -- pass getopts

usage() { echo "Usage: create-release.sh [-v version]"; }

verbose=1
batch_mode=0

while getopts ":v" opt; do
  case ${opt} in
    v ) batch_mode=1
        verbose=0
      ;;
    \? ) usage
         exit 1
      ;;
  esac
done

if [ "`echo -n`" = "-n" ]; then
  n=""
  c="\c"
else
  n="-n"
  c=""
fi

if [ "$batch_mode" = 0 ]; then
  echo $n "specify version ( e.g. v0.6 ): $c"
  read VERSION
else
  VERSION=$2
fi

RELEASE="tikz-trackschematic-$VERSION"

## -- commands

check_readme() {
  # check if $VERSION is present in README.md
  status=0
  grep -qs "Version ${VERSION:1}" README.md || status=1
  if [ $status = 0 ]; then
    if [ $verbose = 1 ]; then
      echo "Version ${VERSION:1} is present in README.md."
    fi
    return 0
  fi
  
  echo "Version ${VERSION:1} not found in README.md."
  echo "Be sure to edit README.md and specify current version!"
  exit 1
}

check_versionhistory() {
  # check if $VERSION is present in doc/versionhistory.tex
  status=0
  grep -qs "vhEntry{${VERSION:1}" doc/versionhistory.tex || status=1
  if [ $status = 0 ]; then
    if [ $verbose = 1 ]; then
      echo "Version ${VERSION:1} is present in versionhistory.tex."
    fi
    return 0
  fi
  
  echo "Version ${VERSION:1} not found in versionhistory.tex."
  echo "Be sure to edit versionhistory.tex and specify current version!"
  exit 1
}

## -- creating the release

## check if $VERSION is present in README.md and versionhistory.tex
check_readme
check_versionhistory

## extract DATE from versionhistory.tex
LINE=$(grep "vhEntry{${VERSION:1}" doc/versionhistory.tex)
DATEISO=$(echo $LINE | egrep -o '\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])')
# DATE=$(echo $DATEISO | sed -e "s|-|\\\/|g") # with escape character for sed
# DATE=$(date "+%Y\/%m\/%d") # with escape character for sed

## create backup-file und update VERSIONDATE in tikz-trackschematic.sty
sed -i '.backup' -e "s|VERSIONDATE|$DATEISO|g" src/tikz-trackschematic.sty
sed -i '' -e "/create-release/c\ " src/tikz-trackschematic.sty

## (OPTIONAL) recompile manual.tex, examples, symboly_table and snippets.tex` 


## create zip-archive
# create temporary folder
TMP=$RELEASE
mkdir -p $TMP

# copy README and .sty-file
cp README.md $TMP/README.md
cp doc/tikz-trackschematic-documentation.sty  $TMP/

# copy and rename documentation
cp doc/manual.pdf  $TMP/tikz-trackschematic.pdf
cp doc/manual.tex  $TMP/tikz-trackschematic.tex
cp doc/snippets.pdf  $TMP/tikz-trackschematic-snippets.pdf
cp doc/snippets.tex  $TMP/tikz-trackschematic-snippets.tex
cp doc/symbology-table.pdf  $TMP/tikz-trackschematic-symbology-table.pdf
cp doc/symbology-table.tex  $TMP/tikz-trackschematic-symbology-table.tex
mkdir $TMP/tikz-trackschematic-examples
mkdir $TMP/tikz-trackschematic-snippets
cp -R doc/examples/*  $TMP/tikz-trackschematic-examples/
cp -R doc/snippets/*  $TMP/tikz-trackschematic-snippets/
if [ $verbose = 1 ]; then
  echo "copied documentation"
fi

# copy src-files
for SRC in src/*; do
  EXT=${SRC##*.}
  # do not copy backup created by sed
  if [ $EXT != "backup" ]; then
    cp $SRC $TMP/
  fi
done
if [ $verbose = 1 ]; then
  echo "copied src-files"
fi

# zip package
zip -r $RELEASE.zip $TMP/*

## cleanup
# remove TMP-folder
rm -rf $TMP/*
rmdir $TMP
# undo changes to tikz-trackschematic.sty by sed
mv src/tikz-trackschematic.sty.backup src/tikz-trackschematic.sty
