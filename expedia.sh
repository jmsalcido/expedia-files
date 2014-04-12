#!/bin/bash

# must have rename (sudo apt-get install rename)

# expedia languages
declare -a expedia_languages=("en_US" "ar_SA" "da_DK" "de_DE" "el_GR" "fi_FI" "fr_FR" "hu_HU" "in_ID" "it_IT" "ja_JP" "ko_KR" "ms_MY" "nl_NL" "no_NO" "pl_PL" "pt_BR" "ru_RU" "es_ES" "sv_SE" "th_TH" "tr_TR" "zh_TW" "zh_CN")

# download the entire files.
echo "Starting to download files (this will take a while)"
declare url="http://www.ian.com/affiliatecenter/include/V2/"
declare -a fileNames=("ActivePropertyList" "PropertyTypeList" "PropertyDescriptionList" "PropertyAttributeLink" "AttributeList")
for i in "${fileNames[@]}"
do
    echo "Downloading $i"
    declare f=""
    for language in ${expedia_languages[@]}
    do
        if [ "$language" != "en_US" ]
        then
            language="_$language"
            f="$i$language.zip"
        else
            echo "English!"
            f="$i.zip"
        fi

        if [ -a "./$f" ]
        then
            echo $f" already exists"
            continue
        fi

        wget "$url$f"
    done
done
echo "Downloading images file"
if [ -a "./HotelImageList.zip" ]
then
    echo "HotelImagesList.zip already exists"
else
    wget "http://www.ian.com/affiliatecenter/include/V2/HotelImageList.zip"
fi
echo "Downloading themes file"
if [ -a "./HotelImageList.zip" ]
then
    echo "Property_Themes_Data.zip already exists"
else
    wget "http://www.ian.com/affiliatecenter/include/Property_Themes_Data.zip"
fi
echo "Downloaded expedia files"

echo "Starting to unzip files"
for f in ./*.zip
do
    unzip -d unzip $f
done
cd unzip;

# print the entire files pertaining an airport code.
# $12 == AirportCode
awk -v airportcode="SFO" -F'|' 'BEGIN { OFS="|" } ($12==airportcode && NR>1){print $1}' ActivePropertyList.txt > ./hotelids
declare -a hotelcodes=()
while read h;
    do
        hotelcodes=("${hotelcodes[@]}" $h)
    done < ./hotelids;
# echo ${hotelcodes[@]}
# create final dir
mkdir -p final
echo "Parsing all the files..."
for f in *.txt
do
    echo "Parsing "$f
    if [ -a "./final/$f" ]
    then
        echo "$f already exists in ./final"
        continue
    fi
    if [[ "$f" = "AttributeList"*"txt" ]] || [[ "$f" = "PropertyTypeList"*"txt" ]]
    then
        # it is a small file, copy and continue.
        cp $f ./final/$f
        cd final
        # create the zip file (we will need this..)
        zip $f.zip $f
        cd ..
        continue;
    fi
    if [[ "$f" = "PropertyAttributeLink"*"txt" ]] || [[ "$f" = "HotelImageList"*"txt" ]]
    then
        awk -v arr="${hotelcodes[*]}" -v found=0 -v allowedError=0 -F'|' 'BEGIN { OFS="|" split(arr, list, " ");} (NR==1){print} (NR>1){for(i=0;i<length(list);i+=1){if(allowedError>5000000 && found==1){ exit 1} if($1 == list[i]){{print; allowedError=0; found=1}}else{allowedError++;}}}' $f > ./final/$f
        continue
    fi
    if [[ "$f" = "PropertyDescription"*"txt" ]]
    then
        awk -v arr="${hotelcodes[*]}" -v allowedError=0 -F'|' 'BEGIN { OFS="|" split(arr, list, " ");} (NR==1){print} (NR>1){for(i=0;i<length(list);i+=1){if(allowedError>1160905){ exit 1} if($1 == list[i]){{print; allowedError=0}}else{allowedError++;}}}' $f > ./final/$f
    else
        awk -v arr="${hotelcodes[*]}" -v allowedError=0 -F'|' 'BEGIN { OFS="|" split(arr, list, " ");} (NR==1){print} (NR>1){for(i=0;i<length(list);i+=1){if(allowedError>10000) {exit 1}if($1 == list[i]) {{print; allowedError=0}}else{allowedError++}}}' $f > ./final/$f
    fi
    cd final
    # create the zip file (we will need this..)
    zip $f.zip $f
    cd ..
    continue
done
echo "Done, parsing."
cd final
# must have rename (sudo apt-get install rename)
echo 'rename -v "s/.txt.zip/.zip/##g" *zip'
rename -v "s/.txt.zip/.zip/##g" *zip
mv *zip /home/jsalcido/Dropbox/Public/Expedia/V2/

# echo ${hotelcodes[@]};