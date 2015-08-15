#!/bin/sh

parse_coord()
{
  COORD_FULL="$2"
  COORD=${COORD_FULL%%,*}
  COORD_MIN=${COORD_FULL#*,}
  COORD_MIN=${COORD_MIN%%,*}
  COORD_SEC=${COORD_FULL##*,}
  if test "$COORD_MIN" -eq 0 -a "$COORD_SEC" -eq 0 2>/dev/null ; then
    eval "$1=\${COORD}"
    return
  fi
  COORD_BC=$(echo "scale = 7; $COORD + $COORD_MIN / 60 + $COORD_SEC / 3600" | bc)
  if ! test "${COORD_BC%%.*}" -eq "${COORD%%.*}" ; then
    echo "Failed to calculate GPS coordinates with bc"
    exit 1
  fi
  eval "$1=\${COORD_BC}"
}

FILE=$1
TYPE=${2:-qr}
OUTFILE=${FILE%.*}.gps$TYPE.png
GPSNR=$(exif "$FILE" -m --ifd=GPS -t GPSLatitudeRef 2>/dev/null)
GPSN_FULL=$(exif "$FILE" -m --ifd=GPS -t GPSLatitude 2>/dev/null)
parse_coord GPSN "$GPSN_FULL"
test "$GPSNR" = "S" && GPSN="-$GPSN"
GPSER=$(exif "$FILE" -m --ifd=GPS -t GPSLongitudeRef 2>/dev/null)
GPSE_FULL=$(exif "$FILE" -m --ifd=GPS -t GPSLongitude 2>/dev/null)
parse_coord GPSE "$GPSE_FULL"
test "$GPSER" = "W" && GPSE="-$GPSE"
ALT=$(exif "$FILE" -m --ifd=GPS -t GPSAltitude 2>/dev/null)
ALT=${ALT%m}
ALT=${ALT%.*}
TIME=$(exif "$FILE" -m --ifd=GPS -t GPSTimeStamp 2>/dev/null)
TIME=${TIME%.*}
DATE=$(exif "$FILE" -m --ifd=GPS -t GPSDateStamp 2>/dev/null)
DATETIME=$(exif "$FILE" -m -t DateTime 2>/dev/null)
if test -z "$DATETIME" ; then
  DATETIME=$(exif "$FILE" -m -t DateTimeOriginal 2>/dev/null)
fi
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
