#!/bin/sh

# zip27z.sh
# Murtaza Gulamali (29/11/2010)
#
# Convert all zip files in the present working directory into 7z files.

HERE=`pwd`
TMP_DIR=${HERE}/tmp

cd ${TMP_DIR}
for i in `ls -1 ../*.zip`; do
  unzip -q $i
  7z a -bd ${HERE}/`basename $i .zip`.7z *
  rm -rf *
done
cd ${HERE}
