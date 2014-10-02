#if defined _escalation_menucache_included
#endinput
#endif
#define _escalation_menucache_included

#include<adt>

/**
 * Acts as a cache for menu handles, handling their lifetime
 * and allowing them to be looked up with a unique index.
 */
enum MenuCache
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	Handle:m_hMenus, /**< A hash map of menu handles. */
	Handle:m_hMenusIndex /**< A SourceMod array used to iterate the above hash map. */
}

static const MenuCacheID = (3 << _:MenuCache);

/**
 * Constructs a MenuCache object in the array provided. 
 *
 * @param this				An array to construct the object in. 
 *
 * @noreturn
 */
MenuCache_Construct (this[])
{
	this[MenuCache:m_iObjectType] = MenuCacheID;

	this[m_hMenus] = CreateTrie();
	this[m_hMenusIndex] = CreateArray();
}

/**
 * Destroys a MenuCache object so that it can safely go out of scope.
 *
 * @param this				A MenuCache object to destroy.
 *
 * @error					Invalid object.
 * @noreturn
 */
MenuCache_Destroy (this[])
{
	if (this[MenuCache:m_iObjectType] != MenuCacheID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}
	
	this[MenuCache:m_iObjectType] = 0;

	MenuCache_CloseHandles(this);
}

/**
 * Safely closes a MenuCache's handles.
 *
 * @param this				A MenuCache object to close the handles of.
 *
 * @noreturn
 */
static MenuCache_CloseHandles (this[])
{
	for (new i = 0; i < GetArraySize(this[m_hMenusIndex]); i++)
	{
		new Handle:tmpHandle;
		new iKey = GetArrayCell(this[m_hMenusIndex], i);
		decl String:Key[16];

		IntToString(iKey, Key, sizeof(Key));

		GetTrieValue(this[m_hMenus], Key, tmpHandle);

		if (tmpHandle != INVALID_HANDLE)
		{
			CloseHandle(tmpHandle);
		}
	}

	CloseHandle(this[m_hMenus]);
	CloseHandle(this[m_hMenusIndex]);

	this[m_hMenus] = INVALID_HANDLE;
	this[m_hMenusIndex] = INVALID_HANDLE;
}

/**
 * Removes a single menu from the cache.
 *
 * @param this				A MenuCache object.
 * @param iMenuID			The ID of the menu to remove from the cache.
 *
 * @noreturn
 */
static MenuCache_RemoveMenu(this[], iMenuID)
{
	new iPosition = FindValueInArray(this[m_hMenusIndex], iMenuID);
	
	if (iPosition == -1)
	{
		ThrowError("Attempt to remove weapon %i from cache when it does not exist!")
	}
	else
	{
		RemoveFromArray(this[m_hMenusIndex], iPosition);
	}
	
	
	new Handle:tmpHandle;
	decl String:MenuID[16];
	
	IntToString(iMenuID, MenuID, sizeof(MenuID));
	
	GetTrieValue(this[m_hMenus], MenuID, tmpHandle);
	
	if (tmpHandle != INVALID_HANDLE)
	{
		CloseHandle(tmpHandle);
	}
	
	RemoveFromTrie(this[m_hMenus], MenuID);
}

/**
 * Adds a menu to the cache.
 *
 * @param this				A MenuCache object.
 * @param hMenu				The handle of the menu to store in the cache.
 * @param iMenuID			The integer to use as the menu's ID.
 *
 * @error					Invalid object.
 * @noreturn
 */
MenuCache_AddMenu (this[], Handle:hMenu, iMenuID)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[MenuCache:m_iObjectType] != MenuCacheID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	decl String:MenuID[16];
	IntToString(iMenuID, MenuID, sizeof(MenuID));
	
	if (! SetTrieValue(this[m_hMenus], MenuID, hMenu, false))
	{
		MenuCache_RemoveMenu(this, iMenuID);
		SetTrieValue(this[m_hMenus], MenuID, hMenu, false);
	}
	
	PushArrayCell(this[m_hMenusIndex], iMenuID);
}


/**
 * Gets a menu from the cache.
 *
 * @param this				A MenuCache object.
 * @param iMenuID			The ID of the menu in the cache.
 *
 * @error					Invalid object.
 * @return					The handle of the menu on success or INVALID_HANDLE on failure.
 */
Handle:MenuCache_GetMenu (this[], iMenuID)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[MenuCache:m_iObjectType] != MenuCacheID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	new Handle:tmpHandle;
	decl String:MenuID[16];
	IntToString(iMenuID, MenuID, sizeof(MenuID));
	
	if (! GetTrieValue(this[m_hMenus], MenuID, tmpHandle))
	{
		return INVALID_HANDLE;
	}
	
	return tmpHandle;
}