#!/bin/bash
PROJ_DIR=$1
PROJ_NAME="hoge"
SDK="iphonesimulator6.0"
CONFIGURATION="Debug"
SCHEME="IntegrationTest"

if [ $# -eq 0 ] ; then
  PROJ_DIR="."
fi

# clean
(cd ${PROJ_DIR} && xcodebuild clean -workspace "${PROJ_DIR}/${PROJ_NAME}.xcworkspace" -scheme "${SCHEME}")

# build & install
(cd ${PROJ_DIR} && xcodebuild -workspace "${PROJ_DIR}/${PROJ_NAME}.xcworkspace" -sdk "${SDK}" -arch i386 -configuration "${CONFIGURATION}" -scheme "${SCHEME}" install DSTROOT="./")

#kill simulator if running
killall -s "iPhone Simulator" &> /dev/null
if [ $? -eq 0 ]; then
    killall -KILL -m "iPhone Simulator"
fi

# waxsim
/usr/local/bin/waxsim -s 6.0 -v /tmp/KIF-$$.mov -f ipad Applications/IntegrationTest.app > /tmp/KIF-$$.out 2>&1

success=`exec grep -c "TESTING FINISHED: 0 failures" /tmp/KIF-$$.out`

if [ "$success" = '0' ]
then 
    cat /tmp/KIF-$$.out
    echo "==========================================="
    echo "GUI Tests failed"
    echo "==========================================="
    exit 1
else
    echo "==========================================="
    echo "GUI Tests passed"
    echo "==========================================="
    exit 0
fi
