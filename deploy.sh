#!/bin/bash

PWD_DIR=`pwd`
DATETIME=`date +%Y%m%d_%H%M%S`

TARGET_DIR="/var/www/hoge"
DEPLOY_ROOT="/var/www/hoges"
DEPLOY_DIR="${DEPLOY_ROOT}/${DATETIME}"
ORIGINAL_DIR="${DEPLOY_ROOT}/original"

FILES="`basename $0` exclude.list hoge.tar.gz"

archive() {
  if [ ! -d ${TARGET_DIR} ] ; then
     echo "${TARGET_DIR} is not found"
     exit 2
  fi

  # archive
  (cd ${TARGET_DIR} && tar -cvzf ${PWD_DIR}/hoge.tar.gz . -X ${PWD_DIR}/exclude.list --backup)
}

initial() {
  if [ ! -d ${TARGET_DIR} ] ; then
     echo "${TARGET_DIR} is not found"
     exit 2
  fi
  if [ -L ${TARGET_DIR} ] ; then
     echo "${TARGET_DIR} is symblic link"
     exit 3
  fi
  # httpd resatart
  sudo service httpd stop

  sudo mv ${TARGET_DIR} ${ORIGINAL_DIR}
    
  # httpd resatart
  sudo service httpd start
}

deploy() {
  # make deploy directory
  if [ -d ${DEPLOY_DIR} ] ; then
     echo "${DEPLOY_DIR} is already exist"
     exit 4
  fi
  if [ ! -d ${ORIGINAL_DIR} ] ; then
     echo "${ORIGINAL_DIR} is not found. please make original hoge dir for ${ORIGINAL_DIR}"
     exit 5
  fi
  sudo mkdir -p ${DEPLOY_DIR} 

  # deploy
  sudo tar -xzvf ${PWD_DIR}/hoge.tar.gz -C ${DEPLOY_DIR}

  # set permission
  sudo chown apache:apache ${DEPLOY_DIR} 
  sudo chmod 755 ${DEPLOY_DIR}

  # copy file
  sudo cp -ip ${ORIGINAL_DIR}/data/install.php ${DEPLOY_DIR}/data/

  # symbolic link
  IFS=$'\n'
  EXCLUDES=(`cat exclude.list`)
  for dir in "${EXCLUDES[@]}" ; do
    if [ -d ${ORIGINAL_DIR}/${dir} ] ; then
      sudo ln -s ${ORIGINAL_DIR}/${dir} ${DEPLOY_DIR}/${dir}
    fi
  done

  switch `basename ${DEPLOY_DIR}`
}

switch(){

  # switching symbolic link
  SYMLINK="${DEPLOY_ROOT}/$1"

  if [ ! -d "${SYMLINK}" ] ; then
     echo "${SYMLINK} directory is not found"
     exit 6
  fi
   
  # httpd resatart
  sudo service httpd stop

  sudo rm -f ${TARGET_DIR}
  sudo ln -sf ${SYMLINK} ${TARGET_DIR}

  # httpd resatart
  sudo service httpd start
}

copy() {
  if [ -z "${HNAME}" ] ; then
    usage
  fi
  if [ -z "${KEY}" ] ; then
    scp ${FILES} ${UNAME}@${HNAME}:~ 
  else
    scp -i ${KEY} ${FILES} ${UNAME}@${HNAME}:~ 
  fi
}

usage() {
  echo "Usage: `basename $0` { -a | -i | -d | -c hostname  [-k identity_file] -u user | -s target_name}"
  echo "        -a:archive ${TARGET_DIR} をアーカイブします" 
  echo "        -i:initial ${TARGET_DIR} に本体がある場合、${DEPLOY_ROOT}配下に移動させて、オリジナルとします" 
  echo "        -d:deploy  アーカイブしたファイルを ${DEPLOY_ROOT} 配下にデプロイします"
  echo "                   ${DEPLOY_ROOT} 配下にオリジナルが無い場合は先にinitial処理を行なって下さい"
  echo "        -c:copy    scpで指定されたホストにデプロイ用ファイル一式をコピーします. -u でユーザ、-k で鍵を指定できます" 
  echo "        -s:switch  向き先を指定したターゲットに切り替えます"
 
  exit 1
}

while getopts adic:u:k:s: OPT
do
  case $OPT in
    a) 
      ARCHIVE=YES
      ;;
    d)
      DEPLOY=YES
      ;;
    i)
      INITIAL=YES
      ;;
    c)
      COPY=YES
      HNAME=${OPTARG}
      ;;
    u)
      UNAME=${OPTARG}
      ;;
    k)
      KEY=${OPTARG}
      ;;
    s)
      SWITCH=YES
      SWITCH_TARGET=${OPTARG}
      ;;
    :|\?)
      usage
      ;;
  esac
done

if [ "${ARCHIVE}" = "YES" ] ; then
  archive
  exit
fi

if [ "${INITIAL}" = "YES" ] ; then
  initial 
  exit
fi

if [ "${DEPLOY}" = "YES" ] ; then
  deploy
  exit
fi

if [ "${SWITCH}" = "YES" ] ; then
  switch ${SWITCH_TARGET}
  exit
fi

if [ "${COPY}" = "YES" ] ; then
  copy
  exit
fi

usage
