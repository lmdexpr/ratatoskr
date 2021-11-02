#!/bin/bash

working_directory=${RATATOSKR_PATH}/workspace

TMP_DIR=/tmp/ratatoskr
mkdir -p $TMP_DIR

for z in $working_directory/*.zip; do
  name=${z%.*}
  dirname=$TMP_DIR/$name

  mkdir -p $dirname
  mv $z $dirname
  cd $dirname 

  unzip -j $z "*.flac"

  count=0
  input=""
  for f in *.flac; do
    input+="-i $f ";
    let count++;
  done

  if test $count -gt 1; then
    cmd="ffmpeg $input -filter_complex amix=inputs=$count:duration=longest -ab 32k -acodec libmp3lame -f mp3 ${RATATOSKR_PATH}/output/$name.mp3";
    eval $cmd;
  fi
done


rm -rf $TMP_DIR/*
