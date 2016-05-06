AC_INIT([Moldeo Samples], [1.0.0.160], [info@moldeointeractive.com.ar], [moldeosamples])

AM_INIT_AUTOMAKE
AC_CONFIG_MACRO_DIR([m4])
AM_CONFIG_HEADER(config.h)

AC_LIBTOOL_CONFIG

AC_PROG_CC
AC_PROG_CC_STDC
AC_C_CONST
AC_PROG_LIBTOOL
AM_PROG_LIBTOOL


dnl Set install paths.
if test "x$prefix" = "xNONE" ; then
  prefix="/usr/local"
fi
if test "x$exec_prefix" = "xNONE" ; then
  exec_prefix=$prefix
fi

case "$host" in
        *-*-mingw*|*-*-cygwin*)
                AC_DEFINE(PLATFORM_WIN32, 1, [Platform is Win32])
                PLATFORM_STRING="Win32"
                ;;
        *-*-linux*)
                AC_DEFINE(PLATFORM_LINUX, 1, [Platform is Linux])
                PLATFORM_STRING="Linux"
                ;;
        *-*-darwin*)
		AC_MSG_WARN([Hello])
                AC_DEFINE(PLATFORM_APPLE, 1, [Platform is Apple])
                PLATFORM_STRING="Apple"
                ;;
        *)
                AC_MSG_WARN([*** Please add $host to configure.ac checks!])
                ;;
esac


case "$host" in
        i?86-* | k?-* | athlon-* | pentium*-)
                AC_DEFINE(ARCH_X86, 1, [Architecture is x86])
                ARCH_SPECIFIC_CFLAGS=""
                ARCH_STRING="X86"
                ;;
        x86_64-*)
                AC_DEFINE(ARCH_X86_64, 1, [Architecture is x86-64])
                ARCH_SPECIFIC_CFLAGS="-DUSE_ADDR64"
                ARCH_STRING="X86-64"
                with_boost_libdir="/usr/lib/x86_64-linux-gnu"
                libdir=$prefix"/lib"
                ;;
        ppc-* | powerpc-*)
		AC_MSG_WARN([HI THERE!])
                AC_DEFINE(ARCH_PPC, 1, [Architecture is PowerPC])
                ARCH_SPECIFIC_CFLAGS=""
                ARCH_STRING="PowerPC"
                ;;
        *)
                AC_MSG_ERROR([Unknown Architecture])
                ;;
esac


dnl Makefile outputs
AC_OUTPUT([
Makefile
basic/Makefile
taller/Makefile
samples/Makefile
])

