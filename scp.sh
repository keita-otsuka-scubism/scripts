#!/bin/bash

USER="root"
HOST="192.168.1.1"
DIR="/tmp"
KEY="${HOME}/.ssh/hoge.key"

if [ $# -ne 1 ] ; then
  echo "invalid arguments"
  exit 1
fi

if [ -f $1 ] ; then
  IPA_FILE=$1
else
  echo "not such file $1"
  exit 2
fi

scp -i ${KEY} ${IPA_FILE} ${USER}@${HOST}:${DIR}
#echo "scp -i ${KEY} ${IPA_FILE} ${USER}@${HOST}:${DIR}"
