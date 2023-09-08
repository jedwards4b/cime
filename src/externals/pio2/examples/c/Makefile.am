## This is the automake file for building the C examples for the PIO
## library.

# Ed Hartnett 5/7/18

# Link to our assembled library.
<<<<<<< HEAD
AM_LDFLAGS = ${top_builddir}/src/clib/libpio.la
=======
LDADD = ${top_builddir}/src/clib/libpioc.la
>>>>>>> 9ae124d1f9ead77919941e9f34da9753616f11c3
AM_CPPFLAGS = -I$(top_srcdir)/src/clib

# Build the tests for make check.
check_PROGRAMS = example1 examplePio darray_no_async

<<<<<<< HEAD
# Tests will run from a bash script.
TESTS = run_tests.sh

# Distribute the test script.
EXTRA_DIST = run_tests.sh

# Clean up files produced during testing.
CLEANFILES = *.nc *.log
=======
if RUN_TESTS
# Tests will run from a bash script.
TESTS = run_tests.sh
endif # RUN_TESTS

# Distribute the test script.
EXTRA_DIST = run_tests.sh.in CMakeLists.txt example2.c

# Clean up files produced during testing.
CLEANFILES = *.nc *.log *.clog2 *.slog2

DISTCLEANFILES = run_tests.sh
>>>>>>> 9ae124d1f9ead77919941e9f34da9753616f11c3
