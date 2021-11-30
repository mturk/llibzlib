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

_CPU = x64
_LIB = lib

AFLAGS = /Zi /c
!IF "$(_CPU)" == "x86"
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
EXTRA_LIBS =
!ELSE
CRT_CFLAGS = -MD
!ENDIF

CFLAGS = $(CFLAGS) -I$(SRCDIR)
CFLAGS = $(CFLAGS) -DNDEBUG -DWIN32 -D_WIN32_WINNT=$(WINVER) -DWINVER=$(WINVER)
!IF DEFINED(_ASM)
CFLAGS = $(CFLAGS) -DASMV -DASMINF
!ENDIF
!IF DEFINED(CMSC_VERSION)
CFLAGS = $(CFLAGS) -D_CMSC_VERSION=$(CMSC_VERSION)
!ENDIF
CFLAGS = $(CFLAGS) -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE $(EXTRA_CFLAGS)

PROJECT  = zlib
!IF DEFINED(_STATIC)
TARGET   = lib
OUTNAME = $(PROJECT)static.$(TARGET)
PSUFFIX  = static
ARFLAGS  = /nologo /MACHINE:$(_CPU) $(EXTRA_ARFLAGS)
!UNDEF _PDB
!ELSE
TARGET   = dll
CFLAGS   = $(CFLAGS) -DZLIB_DLL
OUTNAME = $(PROJECT)1.$(TARGET)
LDFLAGS  = /nologo /INCREMENTAL:NO /OPT:REF /DLL /SUBSYSTEM:WINDOWS /MACHINE:$(_CPU) $(EXTRA_LDFLAGS)
!ENDIF

WORKDIR  = $(_CPU)-rel-$(TARGET)
IMPLIB   = $(WORKDIR)\$(PROJECT).lib
OUTPUT   = $(WORKDIR)\$(OUTNAME)
CLOPTS   = /c /nologo $(CRT_CFLAGS) /wd4267 -W3 -O2 -Ob2
RFLAGS   = /l 0x409 /n /d NDEBUG /d WIN32 /d WINNT /d WINVER=$(WINVER)
RFLAGS   = $(RFLAGS) /d _WIN32_WINNT=$(WINVER) $(EXTRA_RFLAGS)
LDLIBS   = kernel32.lib $(EXTRA_LIBS)
!IF DEFINED(_PDB)
PDBNAME  = -Fd$(WORKDIR)\$(PROJECT)
OUTPDB   = /pdb:$(WORKDIR)\$(PROJECT).pdb
CLOPTS   = $(CLOPTS) -Zi
LDFLAGS  = $(LDFLAGS) /DEBUG
!ENDIF
!IF DEFINED(_VENDOR_SFX)
RFLAGS = $(RFLAGS) /d _VENDOR_SFX=$(_VENDOR_SFX)
!ENDIF
!IF DEFINED(_VENDOR_NUM)
RFLAGS = $(RFLAGS) /d _VENDOR_NUM=$(_VENDOR_NUM)
!ENDIF

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
	$(WORKDIR)\zutil.obj

!IF "$(TARGET)" == "dll"
OBJECTS = $(OBJECTS) $(WORKDIR)\llzlib.res
!ENDIF

!IF DEFINED(_ASM)
!IF "$(_CPU)" == "x64"
ASM_OBJECTS = \
	$(WORKDIR)\inffas8664.obj \
	$(WORKDIR)\gvmat64.obj \
	$(WORKDIR)\inffasx64.obj
!ELSE
ASM_OBJECTS = \
	$(WORKDIR)\match686.obj \
	$(WORKDIR)\inffas32.obj
!ENDIF
!ELSE
ASM_OBJECTS =
!ENDIF

all : $(WORKDIR) $(OUTPUT)

$(WORKDIR) :
	@-md $(WORKDIR)

{$(SRCDIR)}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS) -Fo$(WORKDIR)\ $(PDBNAME) $<

{$(SRCDIR)\contrib\masmx64}.c{$(WORKDIR)}.obj:
	$(CC) $(CLOPTS) $(CFLAGS) -Fo$(WORKDIR)\ $(PDBNAME) $<

{$(SRCDIR)\contrib\masmx64}.asm{$(WORKDIR)}.obj:
	$(ML) $(AFLAGS) /Fo$@ $<

{$(SRCDIR)\contrib\masmx86}.asm{$(WORKDIR)}.obj:
	$(ML) $(AFLAGS) /Fo$@ $<


{$(SRCDIR)}.rc{$(WORKDIR)}.res:
	$(RC) $(RFLAGS) /fo $@ $<

$(OUTPUT): $(WORKDIR) $(OBJECTS) $(ASM_OBJECTS)
!IF "$(TARGET)" == "dll"
	$(LN) $(LDFLAGS) $(OBJECTS) $(ASM_OBJECTS) $(LDLIBS) $(OUTPDB) /implib:$(IMPLIB) /out:$(OUTPUT)
!ELSE
	$(AR) $(ARFLAGS) $(OBJECTS) $(ASM_OBJECTS) /out:$(OUTPUT)
!ENDIF

!IF !DEFINED(PREFIX) || "$(PREFIX)" == ""
install:
	@echo PREFIX is not defined
	@echo Use `nmake install PREFIX=directory`
	@echo.
	@exit /B 1
!ELSE
install : all
!IF "$(TARGET)" == "dll"
	@xcopy /I /Y /Q "$(WORKDIR)\*.dll" "$(PREFIX)\bin"
!ENDIF
!IF !DEFINED(_PDB)
	@xcopy /I /Y /Q "$(WORKDIR)\*.pdb" "$(PREFIX)\bin"
!ENDIF
	@xcopy /I /Y /Q "$(WORKDIR)\*.lib" "$(PREFIX)\$(_LIB)"
	@copy /Y "$(SRCDIR)\zconf.h" "$(PREFIX)\include" >NUL
	@copy /Y "$(SRCDIR)\zlib.h" "$(PREFIX)\include" >NUL
!ENDIF

clean:
	@-rd /S /Q $(WORKDIR) 2>NUL
