#!/bin/sh

#this code is tested un fresh 2015-11-21-raspbian-jessie-lite Raspberry Pi image
#by default this script should be located in two subdirecotries under the home

#sudo apt-get update -y && sudo apt-get upgrade -y
#sudo apt-get install git -y
#mkdir -p /home/pi/detect && cd /home/pi/detect
#git clone https://github.com/catonrug/detect-raspbian.git && cd detect-raspbian && chmod +x check.sh && ./check.sh

#check if script is located in /home direcotry
pwd | grep "^/home/" > /dev/null
if [ $? -ne 0 ]; then
  echo script must be located in /home direcotry
  return
fi

#it is highly recommended to place this directory in another directory
deep=$(pwd | sed "s/\//\n/g" | grep -v "^$" | wc -l)
if [ $deep -lt 4 ]; then
  echo please place this script in deeper directory
  return
fi

#set application name based on directory name
#this will be used for future temp directory, database name, google upload config, archiving
appname=$(pwd | sed "s/^.*\///g")

#set temp directory in variable based on application name
tmp=$(echo ../tmp/$appname)

#create temp directory
if [ ! -d "$tmp" ]; then
  mkdir -p "$tmp"
fi

#check if database directory has prepared 
if [ ! -d "../db" ]; then
  mkdir -p "../db"
fi

#set database variable
db=$(echo ../db/$appname.db)

#if database file do not exist then create one
if [ ! -f "$db" ]; then
  touch "$db"
fi

#check if google drive config directory has been made
#if the config file exists then use it to upload file in google drive
#if no config file is in the directory there no upload will happen
if [ ! -d "../gd" ]; then
  mkdir -p "../gd"
fi

#search for all links which ends with "latest"
linklist=$(wget -qO- https://www.raspberrypi.org/downloads/raspbian/ | \
sed "s/\d034/\n/g" | \
grep "http.*latest$" | \
sed '$alast line')

printf %s "$linklist" | while IFS= read -r line
do {

#use spider mode to output all information abaout request
#do not download anything
wget -S --spider -o $tmp/output.log $line

#take the first link which starts with http and ends with zip
url=$(sed "s/http/\nhttp/g" $tmp/output.log | \
sed "s/zip/zip\n/g" | \
grep "^http.*zip$" | head -1)

#calculate exact filename of link
filename=$(echo $url | sed "s/^.*\///g")

#check if this link is in database
grep "$url" $db > /dev/null
if [ $? -ne 0 ]
then
echo new version detected!
echo $url
echo "$url">> $db
			
#lets send emails to all people in "posting" file
emails=$(cat ../posting | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "$filename" "$url"
} done
echo
fi

} done

#clean and remove whole temp direcotry
rm $tmp -rf > /dev/null
