#if defined _escalation_upgradedatastore_included
#endinput
#endif
#define _escalation_upgradedatastore_included

#include<adt>
#include<Escalation_UpgradeData>

/**
 * Acts as a container for UpgradeData objects.
 */ 
enum UpgradeDataStore
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	Handle:m_hUpgrades, /**< A SourceMod Trie containing the upgrade objects. */
	Handle:m_hUpgradeKeys /**< A SourceMod Array containing all the keys that have been assigned an object in m_hUpgrades. */
};


static const UpgradeDataStoreID = (6 << _:UpgradeDataStore);

/**
 * Constructs an UpgradeDataStore object in the array provided. 
 *
 * @param this				An array to construct the object in.
 *
 * @noreturn
 */
UpgradeDataStore_Construct (this[])
{
	this[UpgradeDataStore:m_iObjectType] = UpgradeDataStoreID;
	
	this[m_hUpgrades] = CreateTrie();
	this[m_hUpgradeKeys] = CreateArray(UPGRADE_NAME_MAXLENGTH / 4);
}

/**
 * Destroys an UpgradeDataStore object so it can safely go out of scope. 
 *
 * @param this				An UpgradeDataStore object to destroy.
 *
 * @error					Invalid object.
 * @noreturn
 */
UpgradeDataStore_Destroy (this[])
{
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}
	
	UpgradeDataStore_CloseHandles(this);

	this[UpgradeDataStore:m_iObjectType] = 0;
}

/**
 * Safley closes an UpgradeDataStore's handles. 
 *
 * @param this				An UpgradeDataStore to close the handles of.
 *
 * @noreturn
 */
static UpgradeDataStore_CloseHandles (this[])
{
	for (new i; i < GetArraySize(this[m_hUpgradeKeys]); i ++)
	{
		decl String:Key[32];
		GetArrayString(this[m_hUpgradeKeys], i, Key, sizeof(Key));

		decl tmpUpgradeData[UpgradeData];
		GetTrieArray(this[m_hUpgrades], Key, tmpUpgradeData[0], sizeof(tmpUpgradeData));

		UpgradeData_Destroy(tmpUpgradeData[0]);
	}
	
	CloseHandle(this[m_hUpgrades]);
	CloseHandle(this[m_hUpgradeKeys]);

	this[m_hUpgrades] = INVALID_HANDLE;
	this[m_hUpgradeKeys] = INVALID_HANDLE;
}

/**
 * Removes a single upgrade from the container.
 *
 * @param this				An UpgradeDataStore object.
 * @param Upgrade			The name of the upgrade to remove.
 *
 * @noreturn
 */
static UpgradeDataStore_RemoveUpgrade (this[], const String:Upgrade[])
{
	new iPosition = FindStringInArray(this[m_hUpgradeKeys], Upgrade);
	
	if (iPosition == -1)
	{
		ThrowError("Attempt to remove weapon %s from container when it does not exist!", Upgrade)
	}
	else
	{
		RemoveFromArray(this[m_hWeaponsIndex], iPosition);
	}
	
	decl tmpUpgradeData[UpgradeData];
	GetTrieArray(this[m_hUpgrades], Upgrade, tmpUpgradeData[0], sizeof(tmpUpgradeData));

	UpgradeData_Destroy(tmpUpgradeData[0]);
	
	RemoveFromTrie(this[m_hUpgrades], Upgrade);
}

/**
 * Adds an UpgradeData object to the container. 
 *
 * @param this				An UpgradeDataStore object.
 * @param Upgrade			The name of the upgrade being added.
 * @param UpgradeInfo		The UpgradeData object to be added to the container.
 * @param iMaxSize			The max size of the UpgradeData object's array.
 *
 * @error					Invalid object.
 * @noreturn
 */
UpgradeDataStore_AddUpgrade (this[], const String:Upgrade[], const UpgradeInfo[], iMaxSize)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}
#endif	

	
	if (! SetTrieArray(this[m_hUpgrades], Upgrade, UpgradeInfo, iMaxSize, false))
	{
		UpgradeDataStore_RemoveUpgrade(this, Upgrade);

		SetTrieArray(this[m_hUpgrades], Upgrade, UpgradeInfo, iMaxSize);
	}

	PushArrayString(this[m_hUpgradeKeys], Upgrade);
}

/**
 * Gets an UpgradeData object from the container. 
 *
 * @param this				An UpgradeDataStore object.
 * @param Upgrade			The name of the upgrade to fetch.
 * @param UpgradeInfo		The UpgradeData object to store the object being fetched in.
 * @param iMaxSize			The max size of the above array.
 *
 * @error					Invalid object.
 * @return					True if the upgrade existed and was fetched, false if it didn't exist.
 */
bool:UpgradeDataStore_GetUpgrade (this[], const String:Upgrade[], UpgradeInfo[], iMaxSize)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}
#endif	

	
	return GetTrieArray(this[m_hUpgrades], Upgrade, UpgradeInfo, iMaxSize);
}

/**
 * Checks to see if an upgrade exists in the container. 
 *
 * @param this				An UpgradeDataStore object.
 * @param Upgrade			The name of the upgrade to check for.
 *
 * @error					Invalid object.
 * @return					True if the upgrade exists, false if it doesn't exist.
 */
bool:UpgradeDataStore_UpgradeExists (this[], const String:Upgrade[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}
#endif	

	decl tmpUpgradeData[UpgradeData];
	
	return GetTrieArray(this[m_hUpgrades], Upgrade, tmpUpgradeData[0], sizeof(tmpUpgradeData));
}

/**
 * Gets the cost of an upgrade
 *
 * @param this				An UpgradeDataStore object.
 * @param Upgrade			The name of the upgrade to get the cost of.
 *
 * @error					Invalid object or attempting to get the cost of a non-exsistent upgrade.
 * @return					The cost of the upgrade.
 */
UpgradeDataStore_GetUpgradeCost (this[], const String:Upgrade[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}
#endif	

	decl tmpUpgradeData[UpgradeData];

	if (! GetTrieArray(this[m_hUpgrades], Upgrade, tmpUpgradeData[0], sizeof(tmpUpgradeData)))
	{
		ThrowError("Attempt to get the cost of an upgrade that does not exist. Upgrade: %s", Upgrade);
	}

	
	return UpgradeData_GetCost(tmpUpgradeData[0]);
}

/**
 * Gets the max level of an upgrade
 *
 * @param this				An UpgradeDataStore object.
 * @param Upgrade			The name of the upgrade to get the max level if of.
 *
 * @error					Invalid object or attempting to get the max level of a non-exsistent upgrade.
 * @return					The max level of the upgrade.
 */
UpgradeDataStore_GetUpgradeMaxLevel (this[], const String:Upgrade[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}
#endif

	decl tmpUpgradeData[UpgradeData];

	if (! GetTrieArray(this[m_hUpgrades], Upgrade, tmpUpgradeData[0], sizeof(tmpUpgradeData)))
	{
		ThrowError("Attempt to get the max level of an upgrade that does not exist. Upgrade: %s", Upgrade);
	}

	GetTrieArray(this[m_hUpgrades], Upgrade, tmpUpgradeData[0], sizeof(tmpUpgradeData));
	
	return UpgradeData_GetLevelCount(tmpUpgradeData[0]);
}

/**
 * Creates a menu where each item is the name of an upgrade.
 *
 * @param this				An UpgradeDataStore object.
 * @param fnHandler			A pointer to a function to use as the callback handle.
 * @param iMenuActions		The menu actions you want available in the callback.
 * @param iFlags			The default item draw flags to apply to each item.
 *
 * @error					Invalid object.
 * @return					The handle to the menu. You're responsible for the lifetime of the handle.
 */
Handle:UpgradeDataStore_GetMenuOfUpgrades (this[], MenuHandler:fnHandler, MenuAction:iMenuActions, iFlags)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}
#endif

	new Handle:hMenu = CreateMenu(fnHandler, iMenuActions);

	for (new i = 0; i < GetArraySize(this[m_hUpgradeKeys]); i++)
	{
		decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];
		GetArrayString(this[m_hUpgradeKeys], i, Upgrade, sizeof(Upgrade));
		
		AddMenuItem(hMenu, Upgrade, Upgrade, iFlags);
	}

	return hMenu;
}

/**
 * Creates an array where each entry is the name of an upgrade.
 *
 * @param this				An UpgradeDataStore object.
 *
 * @error					Invalid object.
 * @return					The handle to the array. You're responsible for the lifetime of the handle.
 */
 Handle:UpgradeDataStore_GetArrayOfUpgrades (this[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}
#endif

	return CloneArray(this[m_hUpgradeKeys]);
}
