#if defined _escalation_bannedupgrades_included
#endinput
#endif
#define _escalation_bannedupgrades_included

#include<adt>
#include<Escalation_Constants>

/**
 * Stores which upgrades have been banned.
 */ 
enum BannedUpgrades
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	Handle:m_hBanned, /**< A hashmap used to store which upgrades have been banned. */
	Handle:m_hBannedCombos, /**< A hashmap used to store which weapon and upgrade combinations have been banned. */
	Handle:m_hBannedCombosAdmin /**< A hashmap used to store which weapon and upgrade combinations have been banned by the admin. */
}

static const BannedUpgradesID = (9 << _:BannedUpgrades);

/**
 * Constructs a BannedUpgrades object in the array provided. 
 *
 * @param this				An array to construct the object in.
 *
 * @noreturn
 */
BannedUpgrades_Construct (this[])
{
	this[BannedUpgrades:m_iObjectType] = BannedUpgradesID;	

	this[m_hBanned] = CreateTrie();
	this[m_hBannedCombos] = CreateTrie();
	this[m_hBannedCombosAdmin] = CreateTrie();
}

/**
 * Destroys a BannedUpgrades object so it can safely go out of scope.
 *
 * @param this				A BannedUpgrades object to destroy.
 *
 * @error					Invalid object.
 * @noreturn
 */
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

/**
 * Resets all banned upgrades.
 *
 * @param this				A BannedUpgrades object.
 *
 * @error					Invalid object.
 * @noreturn
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


/**
 * Resets all banned upgrades/weapon combinations.
 *
 * @param this				A BannedUpgrades object.
 * @param bResetAdminBans	If True reset upgrades/weapon combinations banned by the admin or 
 *							if false reset upgrades/weapon combinations banned by the plugin.
 *
 * @error					Invalid object.
 * @noreturn
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

/**
 * Bans an upgrade.
 *
 * @param this				A BannedUpgrades object.
 * @param Upgrade 			The name of the upgrade to ban.
 *
 * @error					Invalid object.
 * @noreturn
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

/**
 * Unbans an upgrade.
 *
 * @param this				A BannedUpgrades object.
 * @param Upgrade 			The name of the upgrade to unban.
 *
 * @error					Invalid object.
 * @noreturn
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

/**
 * Checks to see if an upgrade is banned.
 *
 * @param this				A BannedUpgrades object.
 * @param Upgrade 			The name of the upgrade to check.
 *
 * @error					Invalid object.
 * @return					True if the upgrade is banned, false if it isn't.
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

/**
 * Bans an upgrades/weapon combination.
 *
 * @param this				A BannedUpgrades object.
 * @param iWeaponID			The ID of the weapon to ban the upgrade being used with.
 * @param Upgrade 			The name of the upgrade to ban.
 * @param bAdminBan			If true this will be stored as an admin ban, if false it will be stored as a plugin ban.
 *
 * @error					Invalid object.
 * @noreturn
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

/**
 * Unbans an upgrades/weapon combination.
 *
 * @param this				A BannedUpgrades object.
 * @param iWeaponID			The ID of the weapon to unban the upgrade being used with.
 * @param Upgrade 			The name of the upgrade to unban.
 *
 * @error					Invalid object.
 * @noreturn
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

/**
 * Checks if an upgrades/weapon combination is banned.
 *
 * @param this				A BannedUpgrades object.
 * @param iWeaponID			The ID of the weapon to check if the upgrade is banned from being used with.
 * @param Upgrade 			The name of the upgrade to check.
 *
 * @error					Invalid object.
 * @return					True if the upgrades/weapon combination is banned, false if they aren't.
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