#if defined _escalation_upgrademenucache_included
#endinput
#endif
#define _escalation_upgrademenucache_included

#include<adt>

#define UpgradeMenuCacheID (3 << _:UpgradeMenuCache)

//! Acts as a container for menu handles enabling them to be looked up with the item definition index of a weapon.
enum UpgradeMenuCache
{
	m_iObjectType, //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	Handle:m_hMenus, //!< A hash map of menu handles.
	Handle:m_hMenusIndex //!< A SourceMod array used to iterate the above hash map.
}

//! Constructs a UpgradeMenuCache object in the array provided. 
/*! \param this[] An array that has been created with UpgradeMenuCache as the size.
	\sa UpgradeMenuCache_Destroy */
UpgradeMenuCache_Construct (this[])
{
	this[UpgradeMenuCache:m_iObjectType] = UpgradeMenuCacheID;

	this[m_hMenus] = CreateTrie();
	this[m_hMenusIndex] = CreateArray();
}

//! Destroy a UpgradeMenuCache object so it can safely go out of scope. 
/*! \param this[] An array that has been created with UpgradeMenuCache as the size.
	\sa UpgradeMenuCache_Construct */
UpgradeMenuCache_Destroy (this[])
{
	if (this[UpgradeMenuCache:m_iObjectType] != UpgradeMenuCacheID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}
	
	this[UpgradeMenuCache:m_iObjectType] = 0;

	UpgradeMenuCache_CloseHandles(this);
}

//! A private function that safely destroys the handles of the object.
/*! \param this[] An array containing a constructed UpgradeMenuCache object.
*/
static UpgradeMenuCache_CloseHandles (this[])
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

//! A private function that removes a menu from the cache.
/*! \param this[] An array containing a constructed UpgradeMenuCache object.
	\param iWeaponID The weapon to remove from the cache.
*/
static UpgradeMenuCache_RemoveMenu(this[], iWeaponID)
{
	new iPosition = FindValueInArray(this[m_hMenusIndex], iWeaponID);
	
	if (iPosition == -1)
	{
		ThrowError("Attempt to remove weapon %i from cache when it does not exist!")
	}
	else
	{
		RemoveFromArray(this[m_hMenusIndex], iPosition);
	}
	
	
	new Handle:tmpHandle;
	decl String:WeaponID[16];
	
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID));
	
	GetTrieValue(this[m_hMenus], WeaponID, tmpHandle);
	
	if (tmpHandle != INVALID_HANDLE)
	{
		CloseHandle(tmpHandle);
	}
	
	RemoveFromTrie(this[m_hMenus], WeaponID);
}


//! Adds an already created menu handle to the container and stores it under the WeaponID supplied.
/*! \param this[] An array that has been created with UpgradeMenuCache as the size.
	\param Handle:hMenu The menu handle to store in the container.
	\param iWeaponID The item definition index of the weapon that will later be used to fetch the menu handle.
	\sa UpgradeMenuCache_GetMenu */
UpgradeMenuCache_AddMenu (this[], Handle:hMenu, iWeaponID)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[UpgradeMenuCache:m_iObjectType] != UpgradeMenuCacheID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	decl String:WeaponID[16];
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID));
	
	if (! SetTrieValue(this[m_hMenus], WeaponID, hMenu, false))
	{
		UpgradeMenuCache_RemoveMenu(this, iWeaponID);
		SetTrieValue(this[m_hMenus], WeaponID, hMenu, false);
	}
	
	PushArrayCell(this[m_hMenusIndex], iWeaponID);
}

//! Retrieves a menu handle from the cache using the WeaponID supplied.
/*! \param this[] An array that has been created with UpgradeMenuCache as the size.
	\param iWeaponID The item definition index of the weapon to fetch the menu handle of.
	\return The handle of the menu on success or INVALID_HANDLE on failure.
	\sa UpgradeMenuCache_AddMenu */
Handle:UpgradeMenuCache_GetMenu (this[], iWeaponID)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[UpgradeMenuCache:m_iObjectType] != UpgradeMenuCacheID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	new Handle:tmpHandle;
	decl String:WeaponID[16];
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID));
	
	if (! GetTrieValue(this[m_hMenus], WeaponID, tmpHandle))
	{
		return INVALID_HANDLE;
	}
	
	return tmpHandle;
}