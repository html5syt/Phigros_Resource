set -e
version=`python3 taptap.py`
if [ "$version" = `cat version.txt` ]
then
	echo "No update"
	exit
fi
sudo apt-get install libvorbisenc2 ffmpeg -y
pip install UnityPy~=1.10.0
pip install fsb5
git clone --single-branch -b master https://github.com/html5syt/Phigros_Resource/
wget -nv -O Phigros.apk `cat url.txt`
java -jar PhigrosMetadata-1.2.jar Phigros.apk
dotnet Il2CppDumper.dll libil2cpp.so global-metadata.dat .
dotnet TypeTreeGeneratorCLI.dll -p DummyDll/ -a Assembly-CSharp.dll -v 2019.4.31f1c1 -c GameInformation -c GetCollectionControl -c TipsProvider -d json_min -o Phigros_Resource/typetree.json

cd Phigros_Resource
git commit -am "$version" && git push
git clone --single-branch -b info https://github.com/html5syt/Phigros_Resource info
git clone --no-checkout --single-branch -b avatar https://github.com/html5syt/Phigros_Resource avatar
git clone --no-checkout --single-branch -b illustration https://github.com/html5syt/Phigros_Resource illustration
git clone --no-checkout --single-branch -b illustrationBlur https://github.com/html5syt/Phigros_Resource illustrationBlur
git clone --no-checkout --single-branch -b illustrationLowRes https://github.com/html5syt/Phigros_Resource illustrationLowRes
git clone --no-checkout --single-branch -b chart https://github.com/html5syt/Phigros_Resource chart
git clone --no-checkout --single-branch -b music https://github.com/html5syt/Phigros_Resource music
python3 gameInformation.py ../Phigros.apk
python3 resource.py ../Phigros.apk
python3 webp.py

cd info
echo $version > version.txt
git commit -am "$version" && git push
cd ..

cd avatar
git add .
git commit -m "$version" && git push
cd ..

cd illustration
git add .
git commit -m "$version" && git push
cd ..

cd illustrationBlur
git add .
git commit -m "$version" && git push
cd ..

cd illustrationLowRes
git add .
git commit -m "$version" && git push
cd ..

cd chart
git add .
git commit -m "$version" && git push
cd ..

cd music
git add .
git commit -m "$version" && git push
cd ..

cd ..
echo $version > version.txt
git commit -am "$version" && git push
