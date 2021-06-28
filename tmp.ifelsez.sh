#!/bin/bash


a=1
b=''

if [[ -z $a ]]
then
  echo 'a is null'
else
  echo 'a is not null'
fi

if [[ -z $b ]]
then
  echo 'b is null'
else
  echo 'b is not null'
fi
