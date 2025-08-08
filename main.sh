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



# 设置FFmpeg日志级别（仅显示错误信息）
export FFREPORT="file=/dev/null:level=32"

# 查找并处理文件
find . -type f \( -iname "*.png" -o -iname "*.wav" \) -print0 | while IFS= read -r -d $'\0' file; do
    case "${file,,}" in
        *.png)
            output="${file%.*}.webp"
            echo "正在转换: ${file} -> ${output}"
            if ffmpeg -v error -i "$file" "$output" &>/dev/null; then
                rm -f "$file"
                echo "转换成功并已删除原文件: ${file}"
            else
                echo "错误：转换失败 - ${file}" >&2
                rm -f "$output" 2>/dev/null
            fi
            ;;
        *.wav)
            output="${file%.*}.mp3"
            echo "正在转换: ${file} -> ${output}"
            if ffmpeg -v error -i "$file" -c:a libmp3lame -q:a 2 "$output" &>/dev/null; then
                rm -f "$file"
                echo "转换成功并已删除原文件: ${file}"
            else
                echo "错误：转换失败 - ${file}" >&2
                rm -f "$output" 2>/dev/null
            fi
            ;;
    esac
done

echo "所有文件处理完成！"

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
