#!/bin/sh
FILE="$1"
DATETIME=$(exif "$FILE" -m -t DateTime 2>/dev/null)
if test -z "$DATETIME" ; then
  DATETIME=$(exif "$FILE" -m -t DateTimeOriginal 2>/dev/null)
fi
if test -z "$DATETIME" ; then
  echo "No EXIF datetime for $FILE"
  exit 1
fi
DATETIME=$(echo "$DATETIME" | sed -e 's/\(....\):\(..\):\(..\) \(..\):\(..\):\(..\)/\1\2\3\4\5.\6/')
if test -z $(echo "$DATETIME" | grep "^20[0-9]\{10\}\.[0-9][0-9]$") ; then
   echo "Bad date format in $FILE: $DATETIME"
   exit 1
fi
if ! touch -c -t "$DATETIME" "$FILE" ; then
   echo "Failed setting timestamp on $FILE"
   exit 1
fi
# optionally also change time stamps of qr images
#BASE=$(echo "$FILE" | sed -e 's/\....$//')
#touch -c -t "$DATETIME" "$BASE"*dm.png "$BASE"*qr.png
