#!/bin/bash
set -e

# 配置全局Git用户信息
git config --global user.email "action@github.com"
git config --global user.name "GitHub Action"

version=$(python3 taptap.py)
if [ "$version" = "$(cat version.txt)" ]
then
    echo "No update"
    exit
fi

sudo apt-get install libvorbisenc2 ffmpeg -y
pip install UnityPy~=1.10.0
pip install fsb5

# 使用带token的URL进行克隆
REPO_URL="https://html5syt:${GITHUB_TOKEN}@github.com/html5syt/Phigros_Resource"
git clone --single-branch -b master "$REPO_URL"

wget -nv -O Phigros.apk "$(cat url.txt)"
java -jar PhigrosMetadata-1.2.jar Phigros.apk
dotnet Il2CppDumper.dll libil2cpp.so global-metadata.dat .
dotnet TypeTreeGeneratorCLI.dll -p DummyDll/ -a Assembly-CSharp.dll -v 2019.4.31f1c1 -c GameInformation -c GetCollectionControl -c TipsProvider -d json_min -o Phigros_Resource/typetree.json

cd Phigros_Resource
git commit -am "$version" && git push

# 创建Resource分支的本地副本
git checkout -b Resource origin/Resource 2>/dev/null || git checkout --orphan Resource

# 确保目录结构存在
mkdir -p {avatar,chart,illustration,illustrationBlur,illustrationLowRes,info,music}

# 处理资源
python3 ../gameInformation.py ../Phigros.apk
python3 ../resource.py ../Phigros.apk
python3 ../webp.py

mkdir -p Resource
cd Resource

mkdir -p avatar chart illustration illustrationBlur illustrationLowRes info music

mv ../avatar/* ./avatar/ 
mv ../chart/* ./chart/ 
mv ../illustration/* ./illustration/ 
mv ../illustrationBlur/* ./illustrationBlur/ 
mv ../illustrationLowRes/* ./illustrationLowRes/ 
mv ../info/* ./info/ 
mv ../music/* ./music/ 

ls -la


# 提交所有更改
git add -f .
git commit -m "$version"
git push origin Resource

echo "Update Success"

cd ..
echo "$version" > version.txt
git add -f version.txt
git commit -m "$version" && git push