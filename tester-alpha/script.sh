#!/bin/bash

# Automated script to compile&test deal.II

# Mounts:
# writable log dir: /home/bob/log/
# deal.II source repo: /home/bob/source/ (writeable) or /source (can be read-only)

# settings from ENV variables:
# BUILDS:
#  (gcc|clang)[petsc]
# QUIET=1 (default, not) -- only print summary
#
# TESTREGEX - string to pass to ctest -R, default "multigrid/step" (don't ask why)

# example usage:
# 1) mount readonly, just keep logs:
#      mkdir log
#                -e BUILDS=gcc
#      docker run --rm -v "$(pwd):/source:ro" -v "$(pwd)/log/:/home/bob/log/"  tjhei/dealii-tester-alpha
#
#
# 2) mount readonly, you need to copy results out:
#      docker run -it --rm -v "$(pwd):/source:ro" tjhei/aspect-tester-8.4.1 /bin/bash
#      BUILDS="gcc" ./script.sh
#      docker cp CONTAINER:/home/bob/log/changes-BUILD.diff . # from outside
# 3) mount writeable, this will modify your files outside the container
#      docker run -it --rm -v "$(pwd):/home/bob/source" tjhei/aspect-tester-8.4.1 /bin/bash
#      BUILDS="clang" ./script.sh
# 4) mount writeable, run and exit 
#      docker run -e BUILDS=gcc -v "$(pwd):/home/bob/source" tjhei/aspect-tester-8.4.1

if [ -z "$TESTREGEX" ]; then
  TESTREGEX="multigrid/step"
fi

if [ -z "$BUILDS" ]; then
#  echo 'Please specify list of builds to do in the ENV variable $BUILDS.'
#  echo "Separate build with spaces. Valid options: gcc gccpetsc clang clangpetsc"
#  exit 0
   BUILDS=clang
fi

mkdir -p ~/log

if [ -s ~/source/CMakeLists.txt ]; then
  touch ~/source/VERSION 2>/dev/null # || { echo "~/source needs to be mounted R/W, aborting."; exit 1; }
else
  if [ -s /source/CMakeLists.txt ]; then
    cp -r /source ~/source
    rm -rf ~/source/CMakeCache.txt
  else
    echo "ERROR, no ASPECT mounted under ~/source/ or /source/"
    exit 1
  fi
fi


submit="OFF"

run()
{
build=$1
desc=$2
submit=$3
petsc="OFF"
if [[ $build =~ .*petsc.* ]];
then
  petsc="ON"
fi
compiler=""

CC=clang CXX=clang++ cmake -G "Ninja" -D CMAKE_BUILD_TYPE=Debug -DDEAL_II_WITH_MPI=ON ~/source || { echo "configure FAILED"; return; }
nice ninja || { echo "build FAILED"; return; }
nice ninja setup_tests || { echo "setup_tests FAILED"; return; }
nice ctest -R "$TESTREGEX" --output-on-failure -DDESCRIPTION="$desc" -j 10 || { echo "test FAILED"; }
}


summary=~/log/summary
indexhtml=~/log/index.html

main()
{
#clean contents:
> $summary

echo "-- $hash $name $BUILDS"

for build in $BUILDS;
do
  echo "BUILD $build:" |tee -a $summary
  logfile=~/log/log-$build
  mkdir -p build-$build
  cd build-$build
  eval run $build $build$name $submit 2>&1 | tee $logfile
  if [ -s changes.diff ]; then
    cp changes.diff ~/log/changes-$build.diff
    echo "DIFFS: changes-$build.diff" | tee -a $logfile
  fi
  cd ..

  grep "FAILED" $logfile | grep -v "FAILED: /" | grep -v "The following tests FAILED" | grep -v "FAILED: cd /" | tee -a $summary

  grep "tests passed," $logfile | tee -a $summary
done

sed -i 's/[[:space:]]*0 Compiler errors/ok/' $summary
sed -i 's/\([0-9]*\)% tests passed, 0 tests failed out of \([0-9]*\)/tests: \2 passed/' $summary 

sed -i 's/\([0-9]*\)% tests passed, \([0-9]*\) tests failed out of \([0-9]*\)/tests: \2 \/ \3 FAILED/' $summary 

cp $summary $indexhtml

grep -h "DIFFS: changes-" ~/log/log-* | tee -a $indexhtml
sed -i 's#$# <br/>#' $indexhtml
sed -i 's#^BUILD \(.*\):#<a href="log-\1">BUILD \1:</a>#' $indexhtml
sed -i 's#^DIFFS: \(.*diff\)#DIFFS: <a href="\1">\1</a>#' $indexhtml
}

if [ "$QUIET" == "1" ];
then
  main >/dev/null
  cat $summary
else
  main
fi

