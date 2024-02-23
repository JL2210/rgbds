# SPDX-License-Identifier: MIT

.SUFFIXES:
.SUFFIXES: .cpp .y .o

.PHONY: all clean install checkdiff develop debug coverage mingw32 mingw64 wine-shim dist

# User-defined variables

Q		:= @
PREFIX		:= /usr/local
bindir		:= ${PREFIX}/bin
mandir		:= ${PREFIX}/share/man
STRIP		:= -s
BINMODE		:= 755
MANMODE		:= 644

# Other variables

PKG_CONFIG	:= pkg-config
PNGCFLAGS	:= `${PKG_CONFIG} --cflags libpng`
PNGLDFLAGS	:= `${PKG_CONFIG} --libs-only-L libpng`
PNGLDLIBS	:= `${PKG_CONFIG} --libs-only-l libpng`

# Note: if this comes up empty, `version.cpp` will automatically fall back to last release number
VERSION_STRING	:= `git --git-dir=.git describe --tags --dirty --always 2>/dev/null`

WARNFLAGS	:= -Wall -pedantic -Wno-unknown-warning-option \
                   -Wno-gnu-zero-variadic-macro-arguments

# Overridable CXXFLAGS
CXXFLAGS	?= -O3 -flto -DNDEBUG
# Non-overridable CXXFLAGS
REALCXXFLAGS	:= ${CXXFLAGS} ${WARNFLAGS} -std=c++2a -I include \
		   -D_POSIX_C_SOURCE=200809L -fno-exceptions -fno-rtti
# Overridable LDFLAGS
LDFLAGS		?=
# Non-overridable LDFLAGS
REALLDFLAGS	:= ${LDFLAGS} ${WARNFLAGS} \
		   -DBUILD_VERSION_STRING=\"${VERSION_STRING}\"

# Wrapper around bison that passes flags depending on what the version supports
BISON		:= src/bison.sh

RM		:= rm -rf

# Used for checking pull requests
BASE_REF	:= origin/master

# Rules to build the RGBDS binaries

all: rgbasm rgblink rgbfix rgbgfx

rgbasm_obj := \
	src/asm/charmap.o \
	src/asm/fixpoint.o \
	src/asm/format.o \
	src/asm/fstack.o \
	src/asm/lexer.o \
	src/asm/macro.o \
	src/asm/main.o \
	src/asm/opt.o \
	src/asm/output.o \
	src/asm/parser.o \
	src/asm/rpn.o \
	src/asm/section.o \
	src/asm/symbol.o \
	src/asm/warning.o \
	src/extern/getopt.o \
	src/extern/utf8decoder.o \
	src/error.o \
	src/hashmap.o \
	src/linkdefs.o \
	src/opmath.o \
	src/util.o

src/asm/lexer.o src/asm/main.o: src/asm/parser.hpp

rgblink_obj := \
	src/link/assign.o \
	src/link/main.o \
	src/link/object.o \
	src/link/output.o \
	src/link/patch.o \
	src/link/script.o \
	src/link/sdas_obj.o \
	src/link/section.o \
	src/link/symbol.o \
	src/extern/getopt.o \
	src/extern/utf8decoder.o \
	src/error.o \
	src/hashmap.o \
	src/linkdefs.o \
	src/opmath.o \
	src/util.o

src/link/main.o: src/link/script.hpp

rgbfix_obj := \
	src/fix/main.o \
	src/extern/getopt.o \
	src/error.o

rgbgfx_obj := \
	src/gfx/main.o \
	src/gfx/pal_packing.o \
	src/gfx/pal_sorting.o \
	src/gfx/pal_spec.o \
	src/gfx/process.o \
	src/gfx/proto_palette.o \
	src/gfx/reverse.o \
	src/gfx/rgba.o \
	src/extern/getopt.o \
	src/error.o

rgbasm: ${rgbasm_obj}
	$Q${CXX} ${REALLDFLAGS} -o $@ ${rgbasm_obj} ${REALCXXFLAGS} src/version.cpp -lm

rgblink: ${rgblink_obj}
	$Q${CXX} ${REALLDFLAGS} -o $@ ${rgblink_obj} ${REALCXXFLAGS} src/version.cpp

rgbfix: ${rgbfix_obj}
	$Q${CXX} ${REALLDFLAGS} -o $@ ${rgbfix_obj} ${REALCXXFLAGS} src/version.cpp

rgbgfx: ${rgbgfx_obj}
	$Q${CXX} ${REALLDFLAGS} ${PNGLDFLAGS} -o $@ ${rgbgfx_obj} ${REALCXXFLAGS} ${PNGLDLIBS} src/version.cpp

test/gfx/randtilegen: test/gfx/randtilegen.cpp
	$Q${CXX} ${REALLDFLAGS} ${PNGLDFLAGS} -o $@ $^ ${REALCXXFLAGS} ${PNGCFLAGS} ${PNGLDLIBS}

test/gfx/rgbgfx_test: test/gfx/rgbgfx_test.cpp
	$Q${CXX} ${REALLDFLAGS} ${PNGLDFLAGS} -o $@ $^ ${REALCXXFLAGS} ${PNGLDLIBS}

# Rules to process files

# We want the Bison invocation to pass through our rules, not default ones
.y.o:

.y.cpp:
	$Q${BISON} $@ $<

# Bison-generated C++ files have an accompanying header
src/asm/parser.hpp: src/asm/parser.cpp
	$Qtouch $@
src/link/script.hpp: src/link/script.cpp
	$Qtouch $@

# Only RGBGFX uses libpng (POSIX make doesn't support pattern rules to cover all these)
src/gfx/main.o: src/gfx/main.cpp
	$Q${CXX} ${REALCXXFLAGS} ${PNGCFLAGS} -c -o $@ $<
src/gfx/pal_packing.o: src/gfx/pal_packing.cpp
	$Q${CXX} ${REALCXXFLAGS} ${PNGCFLAGS} -c -o $@ $<
src/gfx/pal_sorting.o: src/gfx/pal_sorting.cpp
	$Q${CXX} ${REALCXXFLAGS} ${PNGCFLAGS} -c -o $@ $<
src/gfx/pal_spec.o: src/gfx/pal_spec.cpp
	$Q${CXX} ${REALCXXFLAGS} ${PNGCFLAGS} -c -o $@ $<
src/gfx/process.o: src/gfx/process.cpp
	$Q${CXX} ${REALCXXFLAGS} ${PNGCFLAGS} -c -o $@ $<
src/gfx/proto_palette.o: src/gfx/proto_palette.cpp
	$Q${CXX} ${REALCXXFLAGS} ${PNGCFLAGS} -c -o $@ $<
src/gfx/reverse.o: src/gfx/reverse.cpp
	$Q${CXX} ${REALCXXFLAGS} ${PNGCFLAGS} -c -o $@ $<
src/gfx/rgba.o: src/gfx/rgba.cpp
	$Q${CXX} ${REALCXXFLAGS} ${PNGCFLAGS} -c -o $@ $<

.cpp.o:
	$Q${CXX} ${REALCXXFLAGS} -c -o $@ $<

# Target used to remove all files generated by other Makefile targets

clean:
	$Q${RM} rgbasm rgbasm.exe
	$Q${RM} rgblink rgblink.exe
	$Q${RM} rgbfix rgbfix.exe
	$Q${RM} rgbgfx rgbgfx.exe
	$Qfind src/ -name "*.o" -exec rm {} \;
	$Qfind . -type f \( -name "*.gcno" -o -name "*.gcda" -o -name "*.gcov" \) -exec rm {} \;
	$Q${RM} rgbshim.sh
	$Q${RM} src/asm/parser.cpp src/asm/parser.hpp
	$Q${RM} src/link/script.cpp src/link/script.hpp src/link/stack.hh
	$Q${RM} test/gfx/randtilegen test/gfx/rgbgfx_test

# Target used to install the binaries and man pages.

install: all
	$Qinstall -d ${DESTDIR}${bindir}/ ${DESTDIR}${mandir}/man1/ ${DESTDIR}${mandir}/man5/ ${DESTDIR}${mandir}/man7/
	$Qinstall ${STRIP} -m ${BINMODE} rgbasm rgblink rgbfix rgbgfx ${DESTDIR}${bindir}/
	$Qinstall -m ${MANMODE} man/rgbasm.1 man/rgblink.1 man/rgbfix.1 man/rgbgfx.1 ${DESTDIR}${mandir}/man1/
	$Qinstall -m ${MANMODE} man/rgbds.5 man/rgbasm.5 man/rgblink.5 ${DESTDIR}${mandir}/man5/
	$Qinstall -m ${MANMODE} man/rgbds.7 man/gbz80.7 ${DESTDIR}${mandir}/man7/

# Target used to check for suspiciously missing changed files.

checkdiff:
	$Qcontrib/checkdiff.bash `git merge-base HEAD ${BASE_REF}`

# This target is used during development in order to prevent adding new issues
# to the source code. All warnings are treated as errors in order to block the
# compilation and make the continous integration infrastructure return failure.
# The rationale for some of the flags is documented in the CMakeLists.

develop:
	$Q${MAKE} WARNFLAGS="${WARNFLAGS} -Werror -Wextra \
		-Walloc-zero -Wcast-align -Wcast-qual -Wduplicated-branches -Wduplicated-cond \
		-Wfloat-equal -Wlogical-op -Wnull-dereference -Wshift-overflow=2 \
		-Wstringop-overflow=4 -Wstrict-overflow=5 -Wundef -Wuninitialized -Wunused \
		-Wshadow \
		-Wformat=2 -Wformat-overflow=2 -Wformat-truncation=1 \
		-Wno-format-nonliteral -Wno-strict-overflow \
		-Wno-type-limits -Wno-tautological-constant-out-of-range-compare \
		-Wvla \
		-D_GLIBCXX_ASSERTIONS \
		-fsanitize=shift -fsanitize=integer-divide-by-zero \
		-fsanitize=unreachable -fsanitize=vla-bound \
		-fsanitize=signed-integer-overflow -fsanitize=bounds \
		-fsanitize=object-size -fsanitize=bool -fsanitize=enum \
		-fsanitize=alignment -fsanitize=null -fsanitize=address" \
		CXXFLAGS="-ggdb3 -Og -fno-omit-frame-pointer -fno-optimize-sibling-calls"

# This target is used during development in order to more easily debug with gdb.

debug:
	$Qenv ${MAKE} \
		CXXFLAGS="-ggdb3 -Og -fno-omit-frame-pointer -fno-optimize-sibling-calls"

# This target is used during development in order to inspect code coverage with gcov.

coverage:
	$Qenv ${MAKE} \
		CXXFLAGS="-ggdb3 -Og --coverage -fno-omit-frame-pointer -fno-optimize-sibling-calls"

# Targets for the project maintainer to easily create Windows exes.
# This is not for Windows users!
# If you're building on Windows with Cygwin or Mingw, just follow the Unix
# install instructions instead.

mingw32:
	$Q${MAKE} all test/gfx/randtilegen test/gfx/rgbgfx_test \
		CXX=i686-w64-mingw32-g++ \
		CXXFLAGS="-O3 -flto -DNDEBUG -static-libgcc" \
		PKG_CONFIG="PKG_CONFIG_SYSROOT_DIR=/usr/i686-w64-mingw32 pkg-config"

mingw64:
	$Q${MAKE} all test/gfx/randtilegen test/gfx/rgbgfx_test \
		CXX=x86_64-w64-mingw32-g++ \
		PKG_CONFIG="PKG_CONFIG_SYSROOT_DIR=/usr/x86_64-w64-mingw32 pkg-config"

wine-shim:
	$Qecho '#!/usr/bin/env bash' > rgbshim.sh
	$Qecho 'WINEDEBUG=-all wine $$0.exe "$${@:1}"' >> rgbshim.sh
	$Qchmod +x rgbshim.sh
	$Qln -s rgbshim.sh rgbasm
	$Qln -s rgbshim.sh rgblink
	$Qln -s rgbshim.sh rgbfix
	$Qln -s rgbshim.sh rgbgfx

# Target for the project maintainer to produce distributable release tarballs
# of the source code.

dist:
	$Qgit ls-files | sed s~^~$${PWD##*/}/~ \
	  | tar -czf rgbds-`git describe --tags | cut -c 2-`.tar.gz -C .. -T -
