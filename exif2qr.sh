#!/bin/sh
FILE=$1
TYPE=${2:-qr}
OUTFILE=${FILE%.*}.gps$TYPE.png
GPSNR=$(exif "$FILE" -m -t GPSLatitudeRef 2>/dev/null)
GPSN=$(exif "$FILE" -m -t GPSLatitude 2>/dev/null)
GPSN=${GPSN%%,*}
test "$GPSNR" = "S" && GPSN="-$GPSN"
GPSER=$(exif "$FILE" -m -t GPSLongitudeRef 2>/dev/null)
GPSE=$(exif "$FILE" -m -t GPSLongitude 2>/dev/null)
GPSE=${GPSE%%,*}
test "$GPSER" = "W" && GPSE="-$GPSE"
ALT=$(exif "$FILE" -m -t GPSAltitude 2>/dev/null)
ALT=${ALT%m}
ALT=${ALT%.*}
TIME=$(exif "$FILE" -m -t GPSTimeStamp 2>/dev/null)
TIME=${TIME%.*}
DATE=$(exif "$FILE" -m -t GPSDateStamp 2>/dev/null)
DATETIME=$(exif "$FILE" -m -t DateTime 2>/dev/null)
if test -n "$GPSN" ; then
  STRING="geo:$GPSN,$GPSE"
# Android maps are broken and do not work with standard geo URLs
#  test -n "$ALT" && STRING="$STRING,$ALT"
  STRING="$STRING?d=$DATE&t=$TIME"
  test -n "$ALT" && STRING="$STRING&h=$ALT"
elif test -n "$DATETIME" ; then
  OUTFILE=${FILE%.*}.time$TYPE.png
  STRING="$DATETIME"
else
  exit 1
fi

case "$TYPE" in
  qr)
    qrencode -l M -m 2 -o "$OUTFILE" "$STRING"
    ;;
  dm)
    #echo "$STRING" | dmtxwrite -e b -d 3 -m 3 -o "$OUTFILE"
    iec16022 -f PNG -c "$STRING" -o "$OUTFILE"
    mogrify -scale 300% "$OUTFILE"
    ;;
  txt)
    echo "$STRING" > "$OUTFILE"
    ;;
  *)
    echo "Unknown target format"
esac
