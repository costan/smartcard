/*
 * MUSCLE SmartCard Development ( http://www.linuxnet.com )
 *
 * Copyright (C) 1999
 *  David Corcoran <corcoran@linuxnet.com>
 *
 * $Id: wintypes.h 2537 2007-05-22 15:02:26Z rousseau $
 */

/**
 * @file
 * @brief This keeps a list of Windows(R) types.
 */

#ifndef __wintypes_h__
#define __wintypes_h__

#ifdef __cplusplus
extern "C"
{
#endif

#if !defined(WIN32)

#ifndef BYTE
	typedef unsigned char BYTE;
#endif
	typedef unsigned char UCHAR;
	typedef unsigned char *PUCHAR;
	typedef unsigned short USHORT;

#ifndef __COREFOUNDATION_CFPLUGINCOM__
	typedef unsigned long ULONG;
	typedef void *LPVOID;
	typedef short BOOL;
#endif

	typedef unsigned long *PULONG;
	typedef const void *LPCVOID;
	typedef uint32_t DWORD;
	typedef uint32_t *PDWORD;
	typedef uint16_t WORD;
	typedef long LONG;
	typedef const char *LPCSTR;
	typedef const BYTE *LPCBYTE;
	typedef BYTE *LPBYTE;
	typedef DWORD *LPDWORD;
	typedef unsigned char *LPSTR;

	/* these types were deprecated but still used by old drivers and
	 * applications. So just declare and use them. */
	typedef LPSTR LPTSTR;
	typedef LPCSTR LPCTSTR;

#else
#include <windows.h>
#endif

#ifdef __cplusplus
}
#endif

#endif
