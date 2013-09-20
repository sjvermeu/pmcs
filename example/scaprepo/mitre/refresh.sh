#!/bin/sh

URL_PRE="http://oval.mitre.org/repository/data/DownloadDefinition?id="
URL_POST="&type=save"

if [ $# -ne 1 ];
then
  echo "Usage: $0 <OVAL-LIST>"
  exit 1;
fi

if [ ! -f $1 ];
then
  echo "Usage: $0 <OVAL-LIST>";
  echo "";
  echo "Error: $1 is not a valid file.";
  exit 2;
fi

for OVAL in $(awk '{print $1}' $1);
do
  NAME=$(echo ${OVAL} | tr '[:.]' '_');
  ESCNAME=$(echo ${OVAL} | sed -e 's|:|%3a|g');
  echo "## Refreshing ${OVAL}";
  wget -O ${NAME}.xml "${URL_PRE}${ESCNAME}${URL_POST}"
done
