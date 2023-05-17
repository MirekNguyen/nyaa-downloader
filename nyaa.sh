#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TMP_FILE="${SCRIPT_DIR}/query.xhtml";

query=""

# Loop through each argument provided by the user
for arg in "$@"; do
    # Append the argument to the concatenated_args string
    query+=" $arg"
done
query=$(echo "${query}" | awk '{$1=$1};1');
if [ "$query" == "" ]; then
  read -p "Search anime: " query;
fi

query=$(echo "$query" | tr ' ' '+');
curl -s "https://nyaa.si/?page=rss&f=0&c=0_0&q=${query}" > "$TMP_FILE";
xml_data=$(xmllint --xpath '//item/title/text() | //item/link/text()' "$TMP_FILE");
rm -rf "$TMP_FILE";

titles=();
links=();
index=0;

while IFS= read -r line; do
  if [ $index == 0 ]; then
    titles+=("$line");
  elif [ $index == 1 ]; then
    links+=("$line");
  fi
  ((index+=1));
  if [ $index == 2 ]; then
    index=0;
  fi
done <<< "$xml_data"

for index in "${!titles[@]}"; do
    element="${titles[index]}";
    printf "%2d) %s\n" "$index" "$element"
done

while true
do
  read -p "Choose an option: " option;
  if [ "$option" == "q" ]; then
    exit;
  elif ! [[ "$option" =~ ^[0-9]+(,[0-9]*)?$ ]] || [ "$option" -gt "$index"  ]; then
    echo "Invalid option";
    exit 1;
  else
    transmission-remote -a "${links[$option]}" 1>/dev/null &&
    echo -e "\nTransmission: ${titles[$option]}";
  fi
done
