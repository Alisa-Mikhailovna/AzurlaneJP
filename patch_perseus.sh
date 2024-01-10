#!/bin/bash

# Download apkeep
get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"
artifacts["apktool.jar"]="iBotPeaches/Apktool apktool .jar"

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

chmod +x apkeep

# Download Azur Lane
#download_azurlane () {
#    if [ ! -f "com.YoStarEN.AzurLane" ]; then
#    ./apkeep -a com.YoStarEN.AzurLane .
#    fi
#}

#if [ ! -f "com.YoStarEN.AzurLane" ]; then
#    echo "Get Azur Lane apk"
#    download_azurlane
#    unzip -o com.YoStarEN.AzurLane.xapk -d AzurLane
#    cp AzurLane/com.YoStarEN.AzurLane.apk .
#fi
# Manual download
if [ ! -f "com.manjuu.azurlane.inner" ]; then
    echo "Get Azur Lane apk"
    wget https://drive.usercontent.google.com/download?id=19jMX2TwPLKDgVjkW_lFQrJntzfR5C4bG&export=download&confirm=t&uuid=86a1da66-8f30-4917-a80d-e295161f5807 -O com.manjuu.azurlane.inner.apk -q
    echo "apk downloaded !"
fi

# Download Perseus
if [ ! -d "Perseus" ]; then
    echo "Downloading Perseus"
    git clone https://github.com/Egoistically/Perseus
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar -q -f d com.manjuu.azurlane.inner.apk

echo "Copy Perseus libs"
cp -r Perseus/. com.manjuu.azurlane.inner/lib/

echo "Patching Azur Lane with Perseus"
oncreate=$(grep -n -m 1 'onCreate' com.manjuu.azurlane.inner/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" com.manjuu.azurlane.inner/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"Perseus\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" com.manjuu.azurlane.inner/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b com.manjuu.azurlane.inner -o build/com.manjuu.azurlane.inner.patched.apk

echo "Set Github Release version"
s=($(./apkeep -a com.manjuu.azurlane.inner -l))
echo "PERSEUS_VERSION=$(echo ${s[-1]})" >> $GITHUB_ENV
