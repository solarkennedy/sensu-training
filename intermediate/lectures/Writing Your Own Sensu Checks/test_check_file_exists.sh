#!/bin/bash

function assert {
  if [[ $1 -eq $2 ]]; then
    echo "Pass"
  else
    echo "Fail. Expected $2 but got $1"
  fi
}


touch test_file
./check_file_exists test_file
assert $? 0

rm -f test_file
./check_file_exists test_file
assert $? 2

## Inverse Test Cases
touch test_file
./check_file_exists --inverse test_file
assert $? 2

rm -f test_file
./check_file_exists --inverse test_file
assert $? 0
