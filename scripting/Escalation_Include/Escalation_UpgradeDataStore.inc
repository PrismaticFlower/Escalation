#if defined _escalation_upgradedatastore_included
#endinput
#endif
#define _escalation_upgradedatastore_included

#include<adt>
#include<Escalation_UpgradeData>

#define UpgradeDataStoreID (6 << _:UpgradeDataStore)

enum UpgradeDataStore
{
	m_iObjectType, //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	Handle:m_hUpgrades, //!< A SourceMod Trie containing the upgrade objects.
	Handle:m_hUpgradeKeys //!< A SourceMod Array containing all the keys that have been assigned an object in m_hUpgrades.
};


//! Constructs a UpgradeDataStore object in the array provided. 
/*! \param this[] An array that has been created with UpgradeDataStore as the size.
	\sa UpgradeDataStore_Destroy */
UpgradeDataStore_Construct (this[])
{
	this[UpgradeDataStore:m_iObjectType] = UpgradeDataStoreID;
	
	this[m_hUpgrades] = CreateTrie();
	this[m_hUpgradeKeys] = CreateArray(UPGRADE_NAME_MAXLENGTH / 4);
}

//! Detsroys a UpgradeDataStore object so it can safely go out of scope.
/*! \param this[] An array that has been created with UpgradeDataStore as the size.
	\sa UpgradeDataStore_Destroy */
UpgradeDataStore_Destroy (this[])
{
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}
	
	UpgradeDataStore_CloseHandles(this);

	this[UpgradeDataStore:m_iObjectType] = 0;
}

//! A private function used to close the handles of the object safely.
/*! \param this[] An array that has been created with UpgradeDataStore as the size.
	\sa UpgradeDataStore_Destroy */
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

//! Removes a UpgradeData object from the container.
/*! \param this[] An array that has been created with UpgradeDataStore as the size.
	\param String:Upgrade[] The upgrade to remove from the container. */
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

//! Adds an UpgradeData object to the container.
/*! \param this[] An array that has been created with UpgradeDataStore as the size.
	\param String:Upgrade[] A string that will serve as the name of the upgrade.
	\param UpgradeInfo An already constructed UpgradeData object to store in the container.
	\sa UpgradeDataStore_GetUpgrade */
UpgradeDataStore_AddUpgrade (this[], const String:Upgrade[], UpgradeInfo[], iMaxSize)
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

//! Gets a UpgradeData object from the container.
/*! \param this[] An array that has been created with UpgradeDataStore as the size.
	\param String:Upgrade[] The name of the upgrade to get from the container.
	\param UpgradeInfo An array created with UpgradeData as the size to store the object in. 
	\return True on the upgrade being fetched, false if it did not exist in the container.
	\sa UpgradeDataStore_AddUpgrade */
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

//! Fetches if an upgrade exists in the container.
/*! \param this[] An array that has been created with UpgradeDataStore as the size.
	\return True if the upgrade exists, false if it doesn't. */
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

//! Gets a the cost of an upgrade.
/*! \param this[] An array that has been created with UpgradeDataStore as the size.
	\param String:Upgrade[] The name of the upgrade to get from the container. 
	\return The cost of the upgrade or -1 on the upgrade not being found. */
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

//! Gets a the max level of an upgrade.
/*! \param this[] An array that has been created with UpgradeDataStore as the size.
	\param String:Upgrade[] The name of the upgrade to get from the container. 
	\return The max level of the upgrade or -1 on it not being found. */
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


Handle:UpgradeDataStore_GetMenuOfUpgrades (this[], MenuHandler:Handler, MenuAction:iMenuActions, iFlags)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDataStore:m_iObjectType] != UpgradeDataStoreID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}
#endif

	new Handle:hMenu = CreateMenu(Handler, iMenuActions);

	for (new i = 0; i < GetArraySize(this[m_hUpgradeKeys]); i++)
	{
		decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];
		GetArrayString(this[m_hUpgradeKeys], i, Upgrade, sizeof(Upgrade));
		
		AddMenuItem(hMenu, Upgrade, Upgrade, iFlags);
	}

	return hMenu;
}