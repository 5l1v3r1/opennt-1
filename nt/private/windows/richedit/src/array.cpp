/*
 *	@doc INTERNAL
 *
 *	@module	ARRAY.C	-- Generic Array Implementation |
 *	
 *	Original Author: <nl>
 *		Christian Fortini
 *
 *	History: <nl>
 *		6/25/95  alexgo  Cleanup and Commented
 *
 *
 */


#include "_common.h"
#include "_array.h"

ASSERTDATA

//
//	Invariant support
//
#define	DEBUG_CLASSNAME	CArrayBase
#include "_invar.h"


// =============================  Utility routines  =========================

/* 	
 *	PTRUNION
 *
 *	@struct PTRUNION | A union of the different types of pointers.  Useful for copying
 *	memory around
 */
typedef union tagPointerUnion
{
	BYTE *pb;	//@field A byte pointer
	WORD *pw;	//@field A word pointer
	DWORD *pd;	//@field A dword pointer
} PTRUNION;


/*
 *	fumemmov
 *	
 *	@func Copies a block of memory (safe even if source and destination
 *	overlap).
 *
 *	@rdesc	nothing
 */
VOID fumemmov(
	VOID *pvTo,			//@parm	the start of the destination
	VOID const *pvFrom,	//@parm	the start of the source
	LONG cbMove			//@parm the size of the block to move
)
{
	TRACEBEGIN(TRCSUBSYSBACK, TRCSCOPEINTERN, "fumemmov");

	register UINT		cb = cbMove;
	UINT		  		uAlign;
	register PTRUNION	uDst, uSrc;

	uSrc.pb = (BYTE *)pvFrom;
	uDst.pb = (BYTE *)pvTo;

	if(uSrc.pb < uDst.pb)
	{
		uDst.pb += cb;
		uSrc.pb += cb;
	}

	uAlign = ((UINT)uDst.pb | (UINT)uSrc.pb) & 3;

//#if 0											// Uncomment to have byte only code
//	if(cb > 7)			// first be sure all cases work; then exclude small cb
//	{
	if(!uAlign)									// DWORD alignment
	{
		uAlign = cb & 3;						// Save fractional byte count
		cb >>= 2;								// Convert to DWORD count
		if(uSrc.pd < uDst.pd)						//  count
			while(cb-- > 0)						// rep movsd with DF = 1
				*--uDst.pd = *--uSrc.pd;
		else
			while(cb-- > 0)						// rep movsd with DF = 0
				*uDst.pd++ = *uSrc.pd++;
		cb = uAlign;							// Setup fractional DWORD move
	}
	else if(!(uAlign & 1))						// WORD alignment
	{
		uAlign = cb & 1;						// Save fractional WORD byte
		cb >>= 1;								//  count. Convert cb to WORD
		if(uSrc.pw < uDst.pw)					//  count
			while(cb-- > 0)						// rep movsw with DF = 1
				*--uDst.pw = *--uSrc.pw;
		else
			while(cb-- > 0)						// rep movsw with DF = 0
				*uDst.pw++ = *uSrc.pw++;
		cb = uAlign;							// Setup fractional WORD move
	}
//#endif

	if(uSrc.pb < uDst.pb)						// Move bytes if cb still > 0
		while(cb-- > 0)							// rep movsb with DF = 1
			*--uDst.pb = *--uSrc.pb;
	else
		while(cb-- > 0)							// rep movsb with DF = 0
			*uDst.pb++ = *uSrc.pb++;

//	*--((BYTE *)pvTo) = *--pbSrc;				// doesn't compile ??
}


/*
 *	fumemcmp
 *
 *	@func	does a binary compare of two blocks of memory
 *
 *	@rdesc	Returns 0 if the two blocks are equal, non-zero otherwise.
 */

INT fumemcmp(
	VOID const *pvA,	//@parm Block #1
	VOID const *pvB, 	//@parm Block #2
	INT cb				//@parm the number of bytes to compare
)
{
	register BYTE const *pbA = (BYTE const *)pvA;
	register BYTE const *pbB = (BYTE const *)pvB;

	//@todo optimize for DWORD alignment
	while(cb-- > 0)
	{
		const INT iRet = (INT) *pbA++ - (INT) *pbB++;

		if(iRet)
			return iRet;
	}

	return 0;
}


/*
 *	fumemset
 *
 *	@func	sets a block of memory to the byte value specified by <p iFill>
 *
 *	@rdesc 	nothing
 */
VOID fumemset(
	VOID *pv,	//@parm the memory block to fill
	INT iFill, 	//@parm the byte value to fill with
	INT cb		//@parm the number of bytes to fill
)
{
	register const BYTE b = (BYTE) iFill;
	register BYTE *pb = (BYTE *)pv;

	//@todo optimize for DWORD alignment
	while(cb-- > 0)
		*pb++ = b;
}


// ===================================  CArrayBase  ================================================

#ifdef DEBUG
/*
 *	CArrayBase::Invariant
 *
 *	@mfunc	Tests the array state to make sure it is valid.  DEBUG only
 *
 *	@rdesc	TRUE if the tests succeed, FALSE otherwise
 */
BOOL CArrayBase::Invariant(void) const
{
	Assert(_cbElem > 0 );

	if( _prgel == NULL )
	{
		Assert(_cel == 0);
		Assert(_celMax == 0);

		// we go ahead and return a value here so that
		// this function can be executed in the "watch"
		// window of various debuggers
		if( _cel != 0 || _celMax != 0 )
			return FALSE;
	}
	else
	{
		Assert(_celMax > 0 );
		Assert(_cel <= _celMax);

		if( _celMax == 0 || _cel > _celMax )
			return FALSE;
	}

	return TRUE;
}
#endif

/*
 *	CArrayBase::CArrayBase
 *
 *	@mfunc Constructor
 */
CArrayBase::CArrayBase(
	DWORD cbElem		//@parm	the size of an individual array element
)
{	
	_prgel = NULL; 
	_cel = 0; 
	_celMax = 0; 
	_cbElem = cbElem;
}

/* 
 *	CArrayBase::Elem
 *
 *	@mfunc	Returns a pointer to the element indexed by <p iel>
 *
 *	@rdesc	A pointer to the element indexed by <p iel>.  This pointer may
 *	be cast to a pointer of the appropriate element type.
 */
void* CArrayBase::Elem(
	DWORD iel	//@parm The index to use
) const
{
	_TEST_INVARIANT_

	AssertSz(iel == 0 || (iel > 0 && iel < _cel),
		"CArrayBase::Elem() - Index out of range");

	if( !_cel )
	{
		return NULL;
	}
	else
	{
		return _prgel + iel * _cbElem;
	}
}								 

/*
 *	CArrayBase::ArAdd
 *
 *	@mfunc	Adds <p celAdd> elements to the end of the array.
 *
 *	@rdesc	A pointer to the start of the new elements added.  If non-NULL, 
 *	<p pielIns> will be set to the index at which elements were added.
 */
void* CArrayBase::ArAdd(
	DWORD celAdd,	//@parm the number of elements to add
	DWORD *pielIns	//@parm if non-NULL, where to store the index of the first
					//element added
)
{
	char *pel;
	DWORD celNew;

	_TEST_INVARIANT_

	if(_cel + celAdd > _celMax)					// need to grow 
	{
		celNew = max (celGrow, celAdd + celGrow - celAdd % celGrow);
		pel = (char*)PvReAlloc(_prgel, (_celMax + celNew) * _cbElem);
		if(!pel)
			return NULL;
		_prgel = pel;
		pel += _cel * _cbElem;
		_celMax += celNew;
	}
	else
	{
		pel = _prgel + _cel * _cbElem;
		ZeroMemory(pel, celAdd * _cbElem);
	}

	if( pielIns )
	{
		*pielIns = _cel;
	}

	_cel += celAdd;
	return pel;
}

/*
 *	CArrayBase::ArInsert
 *
 *	@mfunc Inserts <p celIns> new elements at index <p iel>
 *
 *	@rdesc A pointer to the newly inserted elements.  Will be NULL on
 *	failure.
 */
void* CArrayBase::ArInsert(
	DWORD iel,		//@parm	the index at which to insert
	DWORD celIns	//@parm the number of elements to insert
)
{
	char *pel;
	DWORD celNew;

	_TEST_INVARIANT_

	AssertSz(iel <= _cel, "CArrayBase::Insert() - Insert out of range");

	if(iel >= _cel)
		return ArAdd(celIns, NULL);

	if(_cel + celIns > _celMax)				// need to grow 
	{
		AssertSz(_prgel, "CArrayBase::Insert() - Growing a non existent array !");

		celNew = max (celGrow, celIns + celGrow - celIns % celGrow); 
		pel = (char*)PvReAlloc(_prgel, (_celMax + celNew)*_cbElem);
		if(!pel)
		{
			TRACEERRORSZ("CArrayBase::Insert() - Couldn't realloc line array");
			return NULL;
		}
		_prgel = pel;
		_celMax += celNew;
	}
	pel = _prgel + iel * _cbElem;
	if(iel < _cel)				// Nove Elems up to make room for new ones
		MoveMemory(pel + celIns*_cbElem, pel, (_cel - iel)*_cbElem);
	_cel += celIns;

	return pel;
}

/*
 *	CArrayBase::Remove
 *
 *	@mfunc	Removes the <p celFree> elements from the array starting at index
 *	<p ielFirst>.  If <p celFree> is negative, then all elements after
 *	<p ielFirst> are removed.
 *
 *	@rdesc nothing
 */
void CArrayBase::Remove(
	DWORD ielFirst, 	//@parm the index at which elements should be removed
	LONG celFree, 		//@parm	the number of elements to remove. 
	ArrayFlag flag		//@parm what to do with the left over memory (delete or leave
						//alone.
)
{
	char *pel;

	_TEST_INVARIANT_

	if (celFree < 0)
		celFree = _cel - ielFirst;

	AssertSz(ielFirst + celFree <= _cel, "CArrayBase::Free() - Freeing out of range");

	if (_cel > ielFirst + celFree)
	{
		pel = _prgel + ielFirst * _cbElem;
		MoveMemory(pel, pel + celFree * _cbElem,
			(_cel - ielFirst - celFree) * _cbElem);
	}

	_cel -= celFree;

	if((flag == AF_DELETEMEM) && _cel < _celMax - celGrow)
	{
		// shrink array
		_celMax = _cel + celGrow - _cel % celGrow;
		pel = (char*)PvReAlloc(_prgel, _celMax * _cbElem);
		// we don't care if it fails since we're shrinking
		if(pel)
			_prgel = pel;
	}
}

/*
 *	CArrayBase::Clear
 *
 *	@mfunc	Clears the entire array, potentially deleting all of the memory
 *	as well.
 *
 *	@rdesc	nothing
 */
void CArrayBase::Clear(
	ArrayFlag flag	//@parm Indicates what should be done with the memory
					//in the array.  One of AF_DELETEMEM or AF_KEEPMEM
)
{
	_TEST_INVARIANT_

	if( flag == AF_DELETEMEM )
	{
		FreePv(_prgel);
		_prgel = NULL;
		_celMax = 0;
	}
	_cel = 0;
}

/*
 *	CArrayBase::Replace
 *
 *	@mfunc	Replaces the <p celRepl> elements at index <p ielRepl> with the
 *	contents of the array specified by <p par>.  If <p celRepl> is negative,
 *	then the entire contents of <p this> array starting at <p ielRepl> should
 *	be replaced.
 *
 *	@rdesc	Returns TRUE on success, FALSE otherwise.
 */
BOOL CArrayBase::Replace(
	DWORD ielRepl, 		//@parm the index at which replacement should occur
	LONG celRepl, 		//@parm the number of elements to replace (may be
						//negative, indicating that all
	CArrayBase *par		//@parm the array to use as the replacement source
)
{
	_TEST_INVARIANT_

	DWORD celMove = 0;
	DWORD celIns = par->Count();
	
	if (celRepl < 0)
		celRepl = _cel - ielRepl;

	AssertSz(ielRepl + celRepl <= _cel, "CArrayBase::ArReplace() - Replacing out of range");
	
	celMove = min(celRepl, (LONG)celIns);

	if (celMove > 0) 
	{
		MoveMemory(Elem(ielRepl), par->Elem(0), celMove * _cbElem);
		celIns -= celMove;
		celRepl -= celMove;
		ielRepl += celMove;
	}

	Assert(celIns >= 0);
	Assert(celRepl >= 0);
	Assert(celIns + celMove == par->Count());

	if(celIns > 0)
	{
		Assert(celRepl == 0);
		void *pelIns = ArInsert (ielRepl, celIns);
		if (!pelIns)
			return FALSE;
		MoveMemory(pelIns, par->Elem(celMove), celIns * _cbElem);
	}
	else if(celRepl > 0)
		Remove (ielRepl, celRepl, AF_DELETEMEM);

	return TRUE;
}


