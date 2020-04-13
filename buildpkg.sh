#!/bin/sh

DIE=0
distro=$1
./builddirs.sh $distro

#subir a Moldeo.org
#find midi -type d -exec sh -c 'echo "${datadir}{}" >> moldeosamples.dirs; echo "${datadir}{}/*.*" >> moldeosamples.install' \;
#find sound -type d -exec sh -c 'echo "${datadir}{}" >> moldeosamples.dirs; echo "${datadir}{}/*.*" >> moldeosamples.install' \;
#find scripting -type d -exec sh -c 'echo "${datadir}{}" >> moldeosamples.dirs; echo "${datadir}{}/*.*" >> moldeosamples.install' \;
./autogen.sh --prefix=/usr && make

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
dh_make -i -e info@moldeo.org -p moldeosamples -c gpl3


sed -i -e 's/Architecture: any/Architecture: amd64/g' debian/control
sed -i -e 's/Section: unknown/Section: graphics/g' debian/control
sed -i -e 's/Maintainer: fabricio /Maintainer: Moldeo Interactive /g' debian/control
sed -i -e 's/<insert the upstream URL, if relevant>/http:\\\\www.moldeo.org/g' debian/control

sed -i -e 's/unstable/experimental/g' debian/changelog
sed -i -e 's/\-1/\-1'${distro}'/g' debian/changelog
sed -i -e 's/fabricio/Moldeo Interactive/g' debian/changelog
sed -i -e 's/Initial release (Closes: #nnnn)  <nnnn is the bug number of your ITP>/Initial release/g' debian/changelog

cat ../../moldeosamples.dirs >  debian/moldeosamples.dirs
cat ../../moldeosamples.install >  debian/moldeosamples.install

xed ../../control.amd64.11.10 debian/control ../../moldeosamples.dirs debian/moldeosamples.dirs ../../moldeosamples.install debian/moldeosamples.install debian/changelog

dpkg-buildpackage -us -uc -rfakeroot 2>&1 | tee ../../buildpkg_logs.txt


echo "Success: extraction"

exit 0
