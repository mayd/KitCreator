#! /usr/bin/env bash

if [ ! -f 'build.sh' ]; then
	echo 'ERROR: This script must be run from the directory it is in' >&2

	exit 1
fi
if [ -z "${TCLVERS}" ]; then
	echo 'ERROR: The TCLVERS environment variable is not set' >&2

	exit 1
fi

ZLIBVERS="1.2.8"
SRC="src/zlib-${ZLIBVERS}.tar.gz"
SRCURL="http://sourceforge.net/projects/libpng/files/zlib/${ZLIBVERS}/zlib-${ZLIBVERS}.tar.gz/download"
BUILDDIR="$(pwd)/build/zlib-${ZLIBVERS}"
OUTDIR="$(pwd)/out"
INSTDIR="$(pwd)/inst"
export ZLIBVERS SRC SRCURL BUILDDIR OUTDIR INSTDIR

# Set configure options for this sub-project
LDFLAGS="${LDFLAGS} ${KC_ZLIB_LDFLAGS}"
CFLAGS="${CFLAGS} ${KC_ZLIB_CFLAGS}"
CPPFLAGS="${CPPFLAGS} ${KC_ZLIB_CPPFLAGS}"
LIBS="${LIBS} ${KC_ZLIB_LIBS}"
export LDFLAGS CFLAGS CPPFLAGS LIBS

rm -rf 'build' 'out' 'inst'
mkdir 'build' 'out' 'inst' || exit 1

if [ ! -f "${SRC}" ]; then
	mkdir 'src' >/dev/null 2>/dev/null

	if [ ! -d 'buildsrc' ]; then
		download "${SRCURL}" "${SRC}" - || exit 1
	fi
fi

(
	cd 'build' || exit 1

	if [ ! -d '../buildsrc' ]; then
		gzip -dc "../${SRC}" | tar -xf -
	else
		cp -rp ../buildsrc/* './'
	fi

	cd "${BUILDDIR}" || exit 1

	case $(uname -s 2> /dev/null) in
		MINGW* | mingw*)
			# use win32/Makefile.gcc instead.
			echo "Running: cp win32/Makefile.gcc Makefile"
			cp win32/Makefile.gcc Makefile

			echo "Running: ${MAKE:-make}"
			${MAKE:-make} || exit 1

			echo "Running: BINARY_PATH=${INSTDIR}/bin INCLUDE_PATH=${INSTDIR}/include LIBRARY_PATH=${INSTDIR}/lib ${MAKE:-make} install"
			BINARY_PATH=${INSTDIR}/bin INCLUDE_PATH=${INSTDIR}/include LIBRARY_PATH=${INSTDIR}/lib ${MAKE:-make} install
			;;
		*)
			# If we are building for KitDLL, compile with '-fPIC'
			if [ "${KITTARGET}" = "kitdll" ]; then
				CFLAGS="${CFLAGS} -fPIC"
				export CFLAGS
			fi

			# We don't pass CONFIGUREEXTRA here, since this isn't a GNU autoconf
			# script and will puke
			echo "Running: ./configure --prefix=\"${INSTDIR}\" --libdir=\"${INSTDIR}/lib\" --static"
			./configure --prefix="${INSTDIR}" --libdir="${INSTDIR}/lib" --static

			echo "Running: ${MAKE:-make}"
			${MAKE:-make} || exit 1

			echo "Running: ${MAKE:-make} install"
			${MAKE:-make} install
			;;
	esac

	# We don't really care too much about failure in zlib
	exit 0
) || exit 1

exit 0
