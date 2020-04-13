#!/bin/bash
export mdatadir="/usr/share/moldeo/"
export mdatadirinstall="debian/moldeosamples/usr/share/moldeo/"
distro=$1

rm moldeosamples.dirs
rm moldeosamples.install
touch moldeosamples.dirs
touch moldeosamples.install


function moldeosamples_dirs {
	basedir=$1
	makefileam=$basedir'/Makefile.am'
	basedirs=`find $basedir -type d`
	echo "datadir = \${prefix}/share/moldeo" > $makefileam
	echo "fontsdir = \${datadir}/fonts" >> $makefileam
	echo "cursorsdir = \${datadir}/cursors" >> $makefileam
	echo "iconsdir = \${datadir}/icons" >> $makefileam
	echo "desktopdir = \${prefix}/share/applications" >> $makefileam
	echo "pixmapsdir = \${prefix}/share/pixmaps" >> $makefileam
	echo "testdir = \${datadir}/test" >> $makefileam
	echo "testsimpledir = \${testdir}" >> $makefileam
	echo "" >> $makefileam
	echo "basicdir = \${datadir}/"$basedir >> $makefileam
	echo "" >> $makefileam


	bc=0
	#for (( c=1; c<=5; c++ ))
	for b in $basedirs
	do
			#echo $bc

			if (( $bc != 0 ))
			then
				brel=${b//${basedir}\//}
				bsize=${#b}
				b1=${b//\//}
				b2=${b1//_/}
				if (( $bsize < 40 ))
				then
					echo $mdatadir''$b >> moldeosamples.dirs
					echo $mdatadirinstall''$b"/*.*" >> moldeosamples.install
					echo $b2"dir = "\${basicdir}/$brel"" >> $makefileam
					echo "dist_"$b2"_DATA = "$brel"/*.*" >> $makefileam
				fi
				echo "" >> $makefileam

			fi

			if (( $bc == 0 ))
			then
				bc=1
			fi

	done
	echo '======================'
	echo $makefileam
	echo '======================'
	cat $makefileam
}

echo '' > moldeosamples.dirs
echo '' > moldeosamples.install

moldeosamples_dirs basic
moldeosamples_dirs taller
moldeosamples_dirs samples
moldeosamples_dirs midi
moldeosamples_dirs scripting
moldeosamples_dirs sound
moldeosamples_dirs kinect

cat moldeosamples.dirs
cat moldeosamples.install
