#!/bin/bash
build_dir=.cmake
bin_dir=bin
set -e
if [ ! -d $build_dir ]; then
    mkdir $build_dir
fi
cd $build_dir
rm -f *.txt
cmake -G Ninja "${cmake_opts[@]}" ..
cmake --build .
