set -e

# 配置全局Git用户信息（必须）
git config --global user.email "action@github.com"
git config --global user.name "GitHub Action"

version=`python3 taptap.py`
if [ "$version" = `cat version.txt` ]
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

wget -nv -O Phigros.apk `cat url.txt`
java -jar PhigrosMetadata-1.2.jar Phigros.apk
dotnet Il2CppDumper.dll libil2cpp.so global-metadata.dat .
dotnet TypeTreeGeneratorCLI.dll -p DummyDll/ -a Assembly-CSharp.dll -v 2019.4.31f1c1 -c GameInformation -c GetCollectionControl -c TipsProvider -d json_min -o Phigros_Resource/typetree.json

cd Phigros_Resource
git commit -am "$version" && git push

# 克隆各分支时使用认证URL
clone_and_set_branch() {
    branch=$1
    git clone --no-checkout --single-branch -b "$branch" "$REPO_URL" "$branch"
    cd "$branch"
    git config core.sparsecheckout true
    echo "/*" > .git/info/sparse-checkout
    git checkout "$branch"
    cd ..
}

clone_and_set_branch info
clone_and_set_branch avatar
clone_and_set_branch illustration
clone_and_set_branch illustrationBlur
clone_and_set_branch illustrationLowRes
clone_and_set_branch chart
clone_and_set_branch music

python3 gameInformation.py ../Phigros.apk
python3 resource.py ../Phigros.apk
python3 webp.py

# 提交各分支的函数
commit_and_push() {
    branch_dir=$1
    commit_msg=$2
    cd "$branch_dir"
    git add .
    # 强制使用指定分支的远程URL（包含token）
    git remote set-url origin "$REPO_URL"
    git commit -m "$commit_msg" && git push origin "$branch_dir"
    cd ..
}

commit_and_push info "$version"
commit_and_push avatar "$version"
commit_and_push illustration "$version"
commit_and_push illustrationBlur "$version"
commit_and_push illustrationLowRes "$version"
commit_and_push chart "$version"
commit_and_push music "$version"

echo "Update Success"

cd ..
echo $version > version.txt
git add version.txt
git commit -m $version && git push