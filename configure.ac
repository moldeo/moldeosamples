AC_INIT([Moldeo Samples], [1.0.0.0], [info@moldeointeractive.com.ar], [moldeosamples])

AM_INIT_AUTOMAKE
AC_CONFIG_MACRO_DIR([m4])
AM_CONFIG_HEADER(config.h)

AC_LIBTOOL_CONFIG

AC_PROG_CC
AC_PROG_CC_STDC
AC_C_CONST
AC_PROG_LIBTOOL
AM_PROG_LIBTOOL

#dnl check for libmoldeo
PKG_CHECK_MODULES([LIBMOLDEO], [libmoldeo] ,has_libmoldeo=yes)

dnl Makefile outputs
AC_OUTPUT([
Makefile
basic/Makefile
taller/Makefile
samples/Makefile
])

