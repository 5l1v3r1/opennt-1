!IF 0

Copyright (c) 1989  Microsoft Corporation

Module Name:

    sources.

Abstract:

    This file specifies the target component being built and the list of
    sources files needed to build that component.  Also specifies optional
    compiler switches and libraries that are unique for the component being
    built.


Author:

    Steve Wood (stevewo) 12-Apr-1989


Revision History:

    Terence Kwan (terryk) 13-Aug-1992
	add make_inf

!ENDIF

MAJORCOMP=inf
MINORCOMP=inf

INCLUDES=.

TARGETNAME=inf
TARGETPATH=obj
TARGETEXT=cpl
TARGETTYPE=notarget

SOURCES=

NTTARGETFILE0=cleansrc make_inf
