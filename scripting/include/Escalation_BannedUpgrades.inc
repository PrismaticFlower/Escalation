#if defined _escalation_bannedupgrades_included
#endinput
#endif
#define _escalation_bannedupgrades_included

#include<adt>
#include<escalation>

#define BannedUpgradesID (9 << _:BannedUpgrades)

//! Stores the translation strings and values of the descriptions for the upgarde menu of each upgrade.
enum BannedUpgrades
{
	m_iObjectType, //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	Handle:m_hBanned, //!< A SourceMod hashmap used to store which upgrades have been banned.
	Handle:m_hBannedCombos, //!< A SourceMod hashmap used to store which weapon and upgrade combinations have been banned.
	Handle:m_hBannedCombosAdmin //!< A SourceMod hashmap used to store which weapon and upgrade combinations have been banned by the admin.
}


//! Constructs an empty BannedUpgrades object in the array provided.
/*! \param this[] An array that is created with BannedUpgrades being the size.
	\sa BannedUpgrades_Destroy */
BannedUpgrades_Construct (this[])
{
	this[BannedUpgrades:m_iObjectType] = BannedUpgradesID;	

	this[m_hBanned] = CreateTrie();
	this[m_hBannedCombos] = CreateTrie();
	this[m_hBannedCombosAdmin] = CreateTrie();
}

//! Destroys a BannedUpgrades object so that it's array can safely go out of scope.
/*! \param this[] An array containing a constructed BannedUpgrades object.
	\sa BannedUpgrades_Construct */
stock BannedUpgrades_Destroy (this[])
{
	if (this[BannedUpgrades:m_iObjectType] != BannedUpgradesID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}
	
	this[BannedUpgrades:m_iObjectType] = 0;
	
	CloseHandle(this[m_hBanned]);
	CloseHandle(this[m_hBannedCombos]);
	CloseHandle(this[m_hBannedCombosAdmin]);
	
	this[m_hBanned] = INVALID_HANDLE;
	this[m_hBannedCombos] = INVALID_HANDLE;
	this[m_hBannedCombosAdmin] = INVALID_HANDLE;
}

//! Resets all banned upgrades.
/*! \param this[] An array containing a constructed BannedUpgrades object.
	*/
BannedUpgrades_ResetBanned (this[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[BannedUpgrades:m_iObjectType] != BannedUpgradesID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	CloseHandle(this[m_hBanned]);
	
	this[m_hBanned] = CreateTrie();
}

//! Resets all banned upgrades/weapon combinations.
/*! \param this[] An array containing a constructed BannedUpgrades object.
	\param bResetAdminBans If true upgrade combinations banned by the admin will be reset instead of config ones.
	*/
BannedUpgrades_ResetBannedCombos (this[], bool:bResetAdminBans = false)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[BannedUpgrades:m_iObjectType] != BannedUpgradesID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif
	
	if (bResetAdminBans)
	{
		CloseHandle(this[m_hBannedCombosAdmin]);
	
		this[m_hBannedCombosAdmin] = CreateTrie();
	}
	else
	{
		CloseHandle(this[m_hBannedCombos]);
	
		this[m_hBannedCombos] = CreateTrie();
	}
}

//! Adds an upgrade to the hashmap of banned upgrades.
/*! \param this[] An array containing a constructed BannedUpgrades object.
	\param String:Upgrade[] The name of the Upgrade to ban.
	*/
BannedUpgrades_BanUpgrade (this[], const String:Upgrade[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[BannedUpgrades:m_iObjectType] != BannedUpgradesID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	SetTrieValue(this[m_hBanned], Upgrade, 1);
}

//! Removes an upgrade from the hashmap of banned upgrades.
/*! \param this[] An array containing a constructed BannedUpgrades object.
	\param String:Upgrade[] The name of the Upgrade to unban.
	*/
BannedUpgrades_UnbanUpgrade (this[], const String:Upgrade[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[BannedUpgrades:m_iObjectType] != BannedUpgradesID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	RemoveFromTrie(this[m_hBanned], Upgrade);
}

//! Checks to see if an upgrade is banned.
/*! \param this[] An array containing a constructed BannedUpgrades object.
	\param String:Upgrade[] The name of the Upgrade to check the status of.
	\return True if the upgrade is banned, false if it isn't.
	*/
bool:BannedUpgrades_IsUpgradeBanned (this[], const String:Upgrade[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[BannedUpgrades:m_iObjectType] != BannedUpgradesID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	new iTestValue;
	
	return GetTrieValue(this[m_hBanned], Upgrade, iTestValue);
}

//! Bans an upgrade from being used with a weapon.
/*! \param this[] An array containing a constructed BannedUpgrades object.
	\param iWeaponID The item definition index of the weapon to ban the upgrade with.
	\param String:Upgrade[] The name of the Upgrade to ban.
	\param bAdminBan If true the this will be stored as an admin ban and the plugin will not reset it when config files are reloaded.
	*/
BannedUpgrades_BanCombo (this[], iWeaponID, const String:Upgrade[], bool:bAdminBan = false)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[BannedUpgrades:m_iObjectType] != BannedUpgradesID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif
	
	decl String:WeaponID[8];
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID));
	
	decl String:Key[UPGRADE_NAME_MAXLENGTH + 8];
	
	strcopy(Key, sizeof(Key), Upgrade);
	StrCat(Key, sizeof(Key), WeaponID);
	
	if (bAdminBan)
	{
		SetTrieValue(this[m_hBannedCombosAdmin], Key, 1);
	}
	else
	{
		SetTrieValue(this[m_hBannedCombos], Key, 1);
	}
}

//! Bans an upgrade from being used with a weapon.
/*! \param this[] An array containing a constructed BannedUpgrades object.
	\param iWeaponID The item definition index of the weapon to unban the upgrade with.
	\param String:Upgrade[] The name of the Upgrade to unban.
	*/
BannedUpgrades_UnbanCombo (this[], iWeaponID, const String:Upgrade[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[BannedUpgrades:m_iObjectType] != BannedUpgradesID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif
	
	decl String:WeaponID[8];
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID));
	
	decl String:Key[UPGRADE_NAME_MAXLENGTH + 8];
	
	strcopy(Key, sizeof(Key), Upgrade);
	StrCat(Key, sizeof(Key), WeaponID);
	

	RemoveFromTrie(this[m_hBannedCombosAdmin], Key);
	RemoveFromTrie(this[m_hBannedCombos], Key);
}


//! Checks to see if a weapon and an upgrade have been banned from being used together.
/*! \param this[] An array containing a constructed BannedUpgrades object.
	\param iWeaponID The item definition index of the weapon to check the status of.
	\param String:Upgrade[] The name of the Upgrade to check the status of.
	\return True if the combo is banned, false if it isn't.
	*/
bool:BannedUpgrades_IsComboBanned (this[], iWeaponID, const String:Upgrade[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[BannedUpgrades:m_iObjectType] != BannedUpgradesID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif
	
	new iTestValue;
	
	decl String:WeaponID[8];
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID));
	
	decl String:Key[UPGRADE_NAME_MAXLENGTH + 8];
	
	strcopy(Key, sizeof(Key), Upgrade);
	StrCat(Key, sizeof(Key), WeaponID);

	new bool:bResult = GetTrieValue(this[m_hBannedCombos], Key, iTestValue);
	
	if (! bResult)
	{
		bResult = GetTrieValue(this[m_hBannedCombosAdmin], Key, iTestValue);
	}
	
	return bResult;
}