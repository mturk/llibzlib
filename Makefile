# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Originally contributed by Mladen Turk <mturk apache.org>
#
CC = cl.exe
LN = link.exe
AR = lib.exe
RC = rc.exe
SRCDIR = .

!IF !DEFINED(BUILD_CPU) || "$(BUILD_CPU)" == ""
!IF DEFINED(VSCMD_ARG_TGT_ARCH)
CPU = $(VSCMD_ARG_TGT_ARCH)
!ELSE
!ERROR Must specify BUILD_CPU matching compiler x86 or x64
!ENDIF
!ELSE
CPU = $(BUILD_CPU)
!ENDIF

AFLAGS = /Zi /c
!IF "$(CPU)" == "x86"
ML = ml.exe
AFLAGS = /coff $(AFLAGS)
!ELSE
ML = ml64.exe
!ENDIF

!IF !DEFINED(WINVER) || "$(WINVER)" == ""
WINVER = 0x0601
!ENDIF

!IF DEFINED(_STATIC_MSVCRT)
CRT_CFLAGS = -MT
!ELSE
CRT_CFLAGS = -MD
!ENDIF

!IF !DEFINED(TARGET_LIB) || "$(TARGET_LIB)" == ""
TARGET_LIB = lib
!ENDIF

CFLAGS = $(CFLAGS) -I$(SRCDIR) -I$(SRCDIR)\contrib\minizip
CFLAGS = $(CFLAGS) -DNDEBUG -DWIN32 -D_WIN32_WINNT=$(WINVER) -DWINVER=$(WINVER)
!IF DEFINED(CMSC_VERSION)
CFLAGS = $(CFLAGS) -D_CMSC_VERSION=$(CMSC_VERSION)
!ENDIF
CFLAGS = $(CFLAGS) -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE -DASMV -DASMIN $(EXTRA_CFLAGS)

!IF DEFINED(_STATIC)
TARGET   = lib
PROJECT  = zlibwapi-1
ARFLAGS  = /nologo /SUBSYSTEM:CONSOLE /MACHINE:$(CPU) $(EXTRA_ARFLAGS)
!ELSE
TARGET   = dll
CFLAGS   = $(CFLAGS) -DZLIB_WINAPI
PROJECT  = libzlibwapi-1
LDFLAGS  = /nologo /INCREMENTAL:NO /OPT:REF /DEBUG /DLL /SUBSYSTEM:CONSOLE /MACHINE:$(CPU) $(EXTRA_LDFLAGS)
!ENDIF

WORKDIR  = $(CPU)-rel-$(TARGET)
OUTPUT   = $(WORKDIR)\$(PROJECT).$(TARGET)
PDBFLAGS = -Fo$(WORKDIR)\ -Fd$(WORKDIR)\$(PROJECT)
CLOPTS   = /c /nologo $(CRT_CFLAGS) /wd4267 -W3 -O2 -Ob2 -Zi
RFLAGS   = /l 0x409 /n /d NDEBUG /d WIN32 /d WINNT /d WINVER=$(WINVER)
RFLAGS   = $(RFLAGS) /d _WIN32_WINNT=$(WINVER) $(EXTRA_RFLAGS)
LDLIBS   = kernel32.lib $(EXTRA_LIBS)
BUILDPDB = $(WORKDIR)\$(PROJECT).pdb

OBJECTS = \
	$(WORKDIR)\adler32.obj \
	$(WORKDIR)\compress.obj \
	$(WORKDIR)\crc32.obj \
	$(WORKDIR)\deflate.obj \
	$(WORKDIR)\gzclose.obj \
	$(WORKDIR)\gzlib.obj \
	$(WORKDIR)\gzread.obj \
	$(WORKDIR)\gzwrite.obj \
	$(WORKDIR)\infback.obj \
	$(WORKDIR)\inffast.obj \
	$(WORKDIR)\inflate.obj \
	$(WORKDIR)\inftrees.obj \
	$(WORKDIR)\trees.obj \
	$(WORKDIR)\uncompr.obj \
	$(WORKDIR)\zutil.obj \
	$(WORKDIR)\ioapi.obj \
	$(WORKDIR)\iowin32.obj \
	$(WORKDIR)\unzip.obj \
	$(WORKDIR)\zip.obj

!IF "$(TARGET)" == "dll"
OBJECTS = $(OBJECTS) $(WORKDIR)\zlibwapi.res
!ENDIF

!IF "$(CPU)" == "x64"
ASM_OBJECTS = \
	$(WORKDIR)\inffas8664.obj \
	$(WORKDIR)\gvmat64.obj \
	$(WORKDIR)\inffasx64.obj
!ELSE
ASM_OBJECTS = \
	$(WORKDIR)\match686.obj \
	$(WORKDIR)\inffas32.obj
!ENDIF


all : $(WORKDIR) $(OUTPUT)

$(WORKDIR) :
	@-md $(WORKDIR)

{$(SRCDIR)}.c{$(WORKDIR)}.obj :
	$(CC) $(CLOPTS) $(CFLAGS) $(PDBFLAGS) $<

{$(SRCDIR)\contrib\minizip}.c{$(WORKDIR)}.obj :
	$(CC) $(CLOPTS) $(CFLAGS) $(PDBFLAGS) $<

{$(SRCDIR)\contrib\masmx64}.c{$(WORKDIR)}.obj :
	$(CC) $(CLOPTS) $(CFLAGS) $(PDBFLAGS) $<

{$(SRCDIR)\contrib\masmx64}.asm{$(WORKDIR)}.obj :
	$(ML) $(AFLAGS) /Fo$@ $<

{$(SRCDIR)\contrib\masmx86}.asm{$(WORKDIR)}.obj :
	$(ML) $(AFLAGS) /Fo$@ $<


{$(SRCDIR)}.rc{$(WORKDIR)}.res:
	$(RC) $(RFLAGS) /fo $@ $<

$(OUTPUT): $(WORKDIR) $(OBJECTS) $(ASM_OBJECTS)
!IF "$(TARGET)" == "dll"
	$(LN) $(LDFLAGS) $(OBJECTS) $(ASM_OBJECTS) $(LDLIBS) /def:$(SRCDIR)\zlibwapi.def /pdb:$(BUILDPDB) /out:$(OUTPUT)
!ELSE
	$(AR) $(ARFLAGS) $(OBJECTS) $(ASM_OBJECTS) /out:$(OUTPUT)
!ENDIF

!IF !DEFINED(INSTALLDIR) || "$(INSTALLDIR)" == ""
install:
	@echo INSTALLDIR is not defined
	@echo Use `nmake install INSTALLDIR=directory`
	@echo.
	@exit /B 1
!ELSE
install : all
!IF "$(TARGET)" == "dll"
	@xcopy /I /Y /Q "$(WORKDIR)\*.dll" "$(INSTALLDIR)\bin"
!ENDIF
	@xcopy /I /Y /Q "$(WORKDIR)\*.pdb" "$(INSTALLDIR)\bin"
	@xcopy /I /Y /Q "$(WORKDIR)\*.lib" "$(INSTALLDIR)\$(TARGET_LIB)"
	@xcopy /I /Y /Q "$(SRCDIR)\contrib\minizip\io*.h" "$(INSTALLDIR)\include"
	@copy /Y "$(SRCDIR)\zconf.h" "$(INSTALLDIR)\include" >NUL
	@copy /Y "$(SRCDIR)\zlib.h" "$(INSTALLDIR)\include" >NUL
	@copy /Y "$(SRCDIR)\contrib\minizip\unzip.h" "$(INSTALLDIR)\include" >NUL
	@copy /Y "$(SRCDIR)\contrib\minizip\zip.h" "$(INSTALLDIR)\include" >NUL
!ENDIF

clean:
	@-rd /S /Q $(WORKDIR) 2>NUL
