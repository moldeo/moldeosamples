#!/bin/sh

DIE=0
rm moldeosamples.dirs
rm moldeosamples.install
touch moldeosamples.dirs
touch moldeosamples.install
export mdatadir="/usr/share/moldeo/"
find basic -type d -exec sh -c 'echo $mdatadir"{}" >> moldeosamples.dirs; echo $mdatadir"{}/*.*" >> moldeosamples.install' \;
find samples -type d -exec sh -c 'echo $mdatadir"{}" >> moldeosamples.dirs; echo $mdatadir"{}/*.*" >> moldeosamples.install' \;
find taller -type d -exec sh -c 'echo $mdatadir"{}" >> moldeosamples.dirs; echo $mdatadir"{}/*.*" >> moldeosamples.install' \;

#subir a Moldeo.org
#find midi -type d -exec sh -c 'echo "${datadir}{}" >> moldeosamples.dirs; echo "${datadir}{}/*.*" >> moldeosamples.install' \;
#find sound -type d -exec sh -c 'echo "${datadir}{}" >> moldeosamples.dirs; echo "${datadir}{}/*.*" >> moldeosamples.install' \;
#find scripting -type d -exec sh -c 'echo "${datadir}{}" >> moldeosamples.dirs; echo "${datadir}{}/*.*" >> moldeosamples.install' \;


echo "deb directory..."
(mkdir deb ) > /dev/null || {
	echo "cleaning..."

	(rm -Rf deb/*) > /dev/null || {
	  echo
	  echo "**Error**: removing error ."
	  echo ""
	  exit 1
	}
}



echo "making distribution source file..."
(make dist) > /dev/null || {
  echo
  echo "**Error**: make dist ."
  echo ""
  exit 1
}


echo "copying..."

(mv moldeosamples-*.tar.gz ./deb/) > /dev/null || {
  echo
  echo "**Error**: moving file ."
  echo ""
  exit 1
}


echo "renaming..."
( rename 's/\.tar.gz/\.orig.tar.gz/' deb/*.tar.gz ) > /dev/null || {
  echo
  echo "**Error**: renaming ."
  echo ""
  exit 1
}
( rename 's/\-/\_/' deb/*.tar.gz ) > /dev/null || {
  echo
  echo "**Error**: renaming ."
  echo ""
  exit 1
}


echo "extracting..."

(tar -C deb -zxvf ./deb/*.orig.tar.gz ) > /dev/null || {
  echo
  echo "**Error**: extracting ."
  echo ""
  exit 1
}

cd deb/moldeosamples-*
dh_make -m -e info@moldeointeractive.com.ar -p moldeosamples
gedit ../../control.amd64.11.10 debian/control ../../moldeosamples.dirs debian/moldeosamples.dirs ../../moldeosamples.install debian/moldeosamples.install debian/changelog

echo " 
Now execute: 
 cd deb/moldeosamples-*
 dpkg-buildpackage -us -uc -rfakeroot 2>&1 | tee ../../buildpkg_logs.txt
"


echo "Success: extraction"
exit 0
