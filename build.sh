#!/bin/bash
set -e
source common.sh
set_keys
export VERSION=$(grep -m1 -o '[0-9]\+\(\.[0-9]\+\)\{3\}' vanadium/args.gn)
export CHROMIUM_SOURCE=https://chromium.googlesource.com/chromium/src.git # https://github.com/chromium/chromium.git
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y sudo lsb-release file nano git curl python3 python3-pillow imagemagick librsvg2-bin
sudo dpkg --add-architecture i386; sudo apt-get update; sudo apt-get install -y libgcc-s1:i386

git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PWD/depot_tools:$PATH"
mkdir -p chromium/src/out/Default; cd chromium/src
git init
git remote add origin $CHROMIUM_SOURCE
git fetch --depth 1 $CHROMIUM_SOURCE +refs/tags/$VERSION:chromium_$VERSION
git checkout $VERSION
cp $SCRIPT_DIR/.gclient ../.gclient

# https://grapheneos.org/build#browser-and-webview
rm -rf $SCRIPT_DIR/vanadium/patches/*trichrome-{apk-build-targets,browser-apk-targets}.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*detailed-language*.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*javascript-optimizer-{site-setting,settings-UI}.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*component-updates.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*{pdf,PDF,for-content-public,toolbar-button,configs-from-config-app,config-app-parsing,new-tab-card,predictive-back}*.patch
# rm -rf $SCRIPT_DIR/vanadium/patches/*crashpad*.patch
replace "$SCRIPT_DIR/vanadium/patches" "VANADIUM" "TITANIUM"
replace "$SCRIPT_DIR/vanadium/patches" "Vanadium" "Titanium"
replace "$SCRIPT_DIR/vanadium/patches" "vanadium" "titanium"
find "$SCRIPT_DIR/vanadium/patches" -name '000[1-3]-*.patch' -exec sed -i 's@Titanium@chrome+@g' {} +
sed -i 's|<string name="app_name" translatable="false">.*</string>|<string name="app_name" translatable="false">chrome+</string>|g' "$SCRIPT_DIR/vanadium/patches/0004-Vanadium-branding.patch" 2>/dev/null || true
sed -i 's|Titanium bookmarks|chrome+ bookmarks|g; s|Titanium search|chrome+ search|g' "$SCRIPT_DIR/vanadium/patches/0004-Vanadium-branding.patch" 2>/dev/null || true
git am --whitespace=nowarn --keep-non-patch $SCRIPT_DIR/vanadium/patches/*.patch

gclient sync -D --no-history --nohooks
gclient runhooks
./build/install-build-deps.sh --no-prompt

source $SCRIPT_DIR/patch.sh
cp $SCRIPT_DIR/args.gn out/Default/args.gn
gn gen out/Default # gn args out/Default; echo 'treat_warnings_as_errors = false' >> out/Default/args.gn
mkdir -p out/tmp out/release

autoninja -C out/Default chrome_public_apk
mv $(find out/Default/apks -name '*[Cc]hrome*.apk' | head -n 1) out/tmp/$VERSION-armeabi-v7a.apk
sed -i 's/target_cpu = "arm"/target_cpu = "arm64"/' out/Default/args.gn
autoninja -C out/Default chrome_public_apk
mv $(find out/Default/apks -name '*[Cc]hrome*.apk' | head -n 1) out/tmp/$VERSION-arm64-v8a.apk

export PATH=$PWD/third_party/jdk/current/bin/:$PATH
export ANDROID_HOME=$PWD/third_party/android_sdk/public
sign_apk out/tmp/$VERSION-armeabi-v7a.apk out/release/$VERSION-armeabi-v7a.apk
sign_apk out/tmp/$VERSION-arm64-v8a.apk out/release/$VERSION-arm64-v8a.apk
rm -rf $SCRIPT_DIR/keys
