#!/bin/bash

# 変数を各環境の値にセットしてご利用下さい
# -------------------------
#SDK
SDK="iphoneos6.0"
# コンフィグレーション(「Debug」、「Release」、「Ad hoc」)
CONFIGURATION="Release"
# Xcodeのプロジェクト名
PROJ_FILE_PATH="hoge.xcodeproj"
# ワークスペース名
WORKSPACE="hoge.xcworkspace"
# スキーマ名
SCHEME="hoge"
# ターゲット名
TARGET_NAME="hoge"
#「Build Settings」にある、プロダクト名
PRODUCT_NAME="hoge"
# 出力されるipaファイル名 
IPA_FILE_NAME="hoge"
# ライセンス取得時の開発者名
DEVELOPPER_NAME="iPhone Distribution:  hoge"
# アプリのプロビジョニングファイルのパス
PROVISIONING_PATH="${HOME}/Library/MobileDevice/Provisioning\ Profiles/hoge.mobileprovision"

# Program本体
# --------------------------
PROJ_DIR=`dirname ${PROJ_FILE_PATH}`
WORK_DIR="${PROJ_DIR}/ipa_work"
INFOPLIST_FILE=${PROJ_DIR}/${PRODUCT_NAME}/iPadPosDemo-Info.plist

if [ ! -d ${WORK_DIR} ]; then
    mkdir "${WORK_DIR}"
fi

# version
#BundleVersion=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFOPLIST_FILE")
#buildNumber=`echo ${BundleVersion} | cut -d. -f4`
#buildNumber=$(($buildNumber + 1))
#BundleVersion="`date +%Y.%m.%d`.${buildNumber}"
BundleVersion="`date +%Y.%m.%d.%H%M`"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BundleVersion" "$INFOPLIST_FILE"
if [ $? -ne 0 ] ; then
  echo "BUILD NUMBER ERROR"
  exit 1
fi
 
# クリーン
# -------------------------
#(cd ${PROJ_DIR} && xcodebuild clean -project "${PROJ_FILE_PATH}")
(cd ${PROJ_DIR} && xcodebuild clean -workspace "${WORKSPACE}" -scheme "${SCHEME}")

# ビルド
# -------------------------
#(cd ${PROJ_DIR} && xcodebuild -project "${PROJ_FILE_PATH}" -sdk "${SDK}" -configuration "${CONFIGURATION}" -target "${TARGET_NAME}" install DSTROOT="${WORK_DIR}")
(cd ${PROJ_DIR} && xcodebuild -workspace "${WORKSPACE}" -scheme "${SCHEME}" -sdk "${SDK}" -configuration "${CONFIGURATION}" install DSTROOT="${WORK_DIR}")
if [ $? -ne 0 ] ; then
  echo "BUILD ERROR"
  exit 2
fi

# Create ipa File
# -------------------------
(cd ${PROJ_DIR} && xcrun -sdk "${SDK}" PackageApplication "${WORK_DIR}/Applications/${PRODUCT_NAME}.app" -o "${WORK_DIR}/${IPA_FILE_NAME}.ipa" -embed "${PROVISIONING_PATH}")

if [ $? -ne 0 ] ; then
  echo "MAKE IPA ERROR"
  exit 3
fi

# scp ipa 
./scp.sh "${WORK_DIR}/${IPA_FILE_NAME}.ipa"

DAY=`date +%Y/%m/%d-%H:%M:%S`
sed -i -e "s@[0-9]\{4\}/[0-9]\{2\}/[0-9]\{2\}-[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}@${DAY}@" install.html
./scp.sh ./install.html
