#if defined _escalation_weaponinfomanager_included
#endinput
#endif
#define _escalation_weaponinfomanager_included

#include<adt>
#include<Escalation_WeaponInfo>


#define ALL_CLASS_WEAPON_OFFSET 100000 /**< Used to offset all class weapon indexes in the hash map. */

/**
 * Acts as a container for WeaponInfo objects and also as an abstract interface between the plugin and the objects.
 */
enum WeaponInfoManager
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	Handle:m_hWeapons, /**< A hashmap used to store the weapons. */
	Handle:m_hWeaponsIndex /**< An array of the keys in m_hWeapons. */
}

static const WeaponInfoManagerID = (2 << _:WeaponInfoManager) /**< Each object recieves it's own ID. As a rule it is i << ObjectEnum. With i being the order the object's code was written in. */

/**
 * Constructs a WeaponInfoManager object in the array provided. 
 *
 * @param this				An array to construct the object in. 
 *
 * @noreturn
 */
WeaponInfoManager_Construct (this[])
{
	this[WeaponInfoManager:m_iObjectType] = WeaponInfoManagerID;	
	
	this[m_hWeapons] = CreateTrie();
	this[m_hWeaponsIndex] = CreateArray();
}

/**
 * Destroys a WeaponInfoManager object so that it can safely go out of scope. 
 *
 * @param this				A WeaponInfoManager object to destroy. 
 *
 * @error					Invalid Object.
 * @noreturn
 */
WeaponInfoManager_Destroy (this[])
{
	if (this[WeaponInfoManager:m_iObjectType] != WeaponInfoManagerID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}
	
	this[WeaponInfoManager:m_iObjectType] = 0;
	
	WeaponInfoManager_DestroyHandles(this);
}

/**
 * Close's a WeaponInfoManager's handles safely so no memory leaks occure.
 *
 * @param this				A WeaponInfoManager object to close the handles of. 
 *
 * @noreturn
 */
static WeaponInfoManager_DestroyHandles(this[])
{
	for(new i = 0; i < GetArraySize(this[m_hWeaponsIndex]); i++)
	{
		decl tmpWeapInfo[WeaponInfo];
		decl String:Key[16];
		new iKey;

		iKey = GetArrayCell(this[m_hWeaponsIndex], i);
		
		IntToString(iKey, Key, sizeof(Key));
		
		GetTrieArray(this[m_hWeapons], Key, tmpWeapInfo[0], _:WeaponInfo);
	
		WeaponInfo_Destroy(tmpWeapInfo[0]);
	}

	CloseHandle(this[m_hWeapons]);
	CloseHandle(this[m_hWeaponsIndex]);
		
	this[m_hWeapons] = INVALID_HANDLE;
	this[m_hWeaponsIndex] = INVALID_HANDLE;
}

/**
 * Removes a single weapon from the container so it can be replaced with a new one.
 *
 * @param this				A WeaponInfoManager object. 
 * @param iWeaponID			The ID of the weapon to remove.
 *
 * @noreturn
 */
static WeaponInfoManager_RemoveWeapon(this[], iWeaponID)
{	
	new iPosition = FindValueInArray(this[m_hWeaponsIndex], iWeaponID);
	
	if (iPosition == -1)
	{
		ThrowError("Attempt to remove weapon %i from container when it does not exist!", iWeaponID)
	}
	else
	{
		RemoveFromArray(this[m_hWeaponsIndex], iPosition);
	}
	
	decl String:WeaponID[16];
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID));

	decl tmpWeaponInfo[WeaponInfo];
	GetTrieArray(this[m_hWeapons], WeaponID, tmpWeaponInfo[0], _:WeaponInfo);
	
	WeaponInfo_Destroy(tmpWeaponInfo[0]);
	
	RemoveFromTrie(this[m_hWeapons], WeaponID);
}

/**
 * Adds a weapon to the container.
 *
 * @param this				A WeaponInfoManager object. 
 * @param iWeaponID			The ID of the weapon to add.
 * @param iParent			The ID of the weapon's parent, pass WEAPONINFO_NO_PARENT to stop the weapon having a parent.
 * @param iSlot				The slot the weapon occupies.
 * @param iClass			The class to add the weapon under. (Only done if the weapon is an all class weapon.)
 *
 * @error					Invalid Object.
 * @noreturn
 */
WeaponInfoManager_AddWeapon(this[], iWeaponID, iParent, iSlot, TFClassType:iClass = TFClass_Unknown)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[WeaponInfoManager:m_iObjectType] != WeaponInfoManagerID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	//LogMessage("Adding weapon %i to container under class - %i. Parent - %i Slot - %i", iWeaponID, iClass, iParent, iSlot);

	new newWeaponInfo[WeaponInfo];

	WeaponInfo_ConstructFull(newWeaponInfo[0], iParent, iSlot);

	if (IsAllClassWeapon(iWeaponID))
	{
		iWeaponID += (_:iClass * ALL_CLASS_WEAPON_OFFSET);
	}

	decl String:WeaponID[16];
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID));

	if (! SetTrieArray(this[m_hWeapons], WeaponID, newWeaponInfo[0], sizeof(newWeaponInfo), false))
	{
		WeaponInfoManager_RemoveWeapon(this, iWeaponID);
		SetTrieArray(this[m_hWeapons], WeaponID, newWeaponInfo[0], sizeof(newWeaponInfo), false);
	}
	
	PushArrayCell(this[m_hWeaponsIndex], iWeaponID);
}

/**
 * Tests if a weapon is allowed an upgrade.
 *
 * @param this				A WeaponInfoManager object. 
 * @param iWeaponID			The ID of the weapon to check.
 * @param Upgrade			The name of the upgrade to check.
 * @param iClass			If the weapon is an all class weapon it'll be checked against this class's version of the weapon.
 *
 * @error					Invalid Object.
 * @return					True if the weapon is allowed the upgrade, false if it isn't.
 */
bool:WeaponInfoManager_IsWeaponAllowedUpgrade(this[], iWeaponID, const String:Upgrade[], TFClassType:iClass = TFClass_Unknown)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[WeaponInfoManager:m_iObjectType] != WeaponInfoManagerID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif
	
	decl String:WeaponID[16];
	new WeaponUpgradePermissions:iResult;
	
	if (IsAllClassWeapon(iWeaponID))
	{
		iWeaponID += (_:iClass * ALL_CLASS_WEAPON_OFFSET);
	}	
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID)); //Got to do this after we've checked for an all class weapon.
	
	decl tmpWeaponInfo[WeaponInfo];
	
	if (! GetTrieArray(this[m_hWeapons], WeaponID, tmpWeaponInfo[0], sizeof(tmpWeaponInfo)))
	{
		return false;
	}
	
	iResult = WeaponInfo_GetUpgradePermissions(tmpWeaponInfo[0], Upgrade);
	
	while (iResult == Upgrade_Check_Parent)
	{
		iWeaponID = WeaponInfo_GetParent(tmpWeaponInfo[0]);
		IntToString(iWeaponID, WeaponID, sizeof(WeaponID));

		if (! GetTrieArray(this[m_hWeapons], WeaponID, tmpWeaponInfo[0], sizeof(tmpWeaponInfo)))
		{
			return false;
		}

		iResult = WeaponInfo_GetUpgradePermissions(tmpWeaponInfo[0], Upgrade);
	}

	
	if (iResult == Upgrade_Not_Allowed)
	{
		return false;
	}
	
	return true;
}

/**
 * Tests if a weapon exists in the container.
 *
 * @param this				A WeaponInfoManager object. 
 * @param iWeaponID			The ID of the weapon to check.
 * @param iClass			If the weapon is an all class weapon it'll be checked against this class's version of the weapon.
 *
 * @error					Invalid Object.
 * @return					True if the weapon is exists, false if it doesn't.
 */
bool:WeaponInfoManager_DoesWeaponExist(this[], iWeaponID, TFClassType:iClass = TFClass_Unknown)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[WeaponInfoManager:m_iObjectType] != WeaponInfoManagerID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif


	decl String:WeaponID[16];
	
	if (IsAllClassWeapon(iWeaponID))
	{
		iWeaponID += (_:iClass * ALL_CLASS_WEAPON_OFFSET);
	}	
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID)); //Got to do this after we've checked for an all class weapon.

	decl tmpWeaponInfo[WeaponInfo];
	
	return GetTrieArray(this[m_hWeapons], WeaponID, tmpWeaponInfo[0], sizeof(tmpWeaponInfo));
}

/**
 * Sets the permissions of an upgrade on the weapon in the container.
 *
 * @param this				A WeaponInfoManager object. 
 * @param iWeaponID			The ID of the weapon to set the upgrade permissions on.
 * @param Upgrade			The name of the upgrade to set the permissions of.
 * @param iPermissions		The permissions to set the upgrade as having.
 * @param iClass			If the weapon is an all class weapon the permissions will be set against this class's version of the weapon.
 *
 * @error					Invalid Object.
 * @noreturn
 */
WeaponInfoManager_SetWeaponPermissions(this[], iWeaponID, const String:Upgrade[], WeaponUpgradePermissions:iPermissions, TFClassType:iClass = TFClass_Unknown)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[WeaponInfoManager:m_iObjectType] != WeaponInfoManagerID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	if (IsAllClassWeapon(iWeaponID))
	{
		iWeaponID += (_:iClass * ALL_CLASS_WEAPON_OFFSET);
	}
	
	decl tmpWeaponInfo[WeaponInfo];	
	decl String:WeaponID[16];
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID)); //Got to do this after we've checked for an all class weapon.

	if (! GetTrieArray(this[m_hWeapons], WeaponID, tmpWeaponInfo[0], _:WeaponInfo))
	{
		ThrowError("Attempt to set permissions on a weapon that hasn't been added yet.");
	}
	
	WeaponInfo_SetUpgradePermissions(tmpWeaponInfo[0], Upgrade, iPermissions);
	
	SetTrieArray(this[m_hWeapons], WeaponID, tmpWeaponInfo[0], _:WeaponInfo)
}

/**
 * Gets the slot of a weapon in the container.
 *
 * @param this				A WeaponInfoManager object. 
 * @param iWeaponID			The ID of the weapon to get the slot of.
 * @param iClass			If the weapon is an all class weapon the slot will be fetched from this class's version of the weapon.
 *
 * @error					Invalid Object.
 * @noreturn
 */
WeaponInfoManager_GetSlot(this[], iWeaponID, TFClassType:iClass = TFClass_Unknown)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[WeaponInfoManager:m_iObjectType] != WeaponInfoManagerID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	if (IsAllClassWeapon(iWeaponID))
	{
		iWeaponID += (_:iClass * ALL_CLASS_WEAPON_OFFSET);
	}

	decl tmpWeaponInfo[WeaponInfo];	
	decl String:WeaponID[16];
	IntToString(iWeaponID, WeaponID, sizeof(WeaponID)); //Got to do this after we've checked for an all class weapon.

	if (! GetTrieArray(this[m_hWeapons], WeaponID, tmpWeaponInfo[0], _:WeaponInfo))
	{
		return WEAPONINFO_INVALID_SLOT;
	}

	new iSlot;
	new iParent;

	iSlot = WeaponInfo_GetSlot(tmpWeaponInfo[0]);
	iParent = WeaponInfo_GetParent(tmpWeaponInfo[0]);
	
	while (iSlot == WEAPONINFO_INVALID_SLOT)
	{
		if (iParent == WEAPONINFO_NO_PARENT)
		{
			ThrowError("Reached end of inheritance chain without finding a parent with a weapon slot defined. Weapon - %i Class - %i", iWeaponID, iClass);
		}

		IntToString(iParent, WeaponID, sizeof(WeaponID));

		if (! GetTrieArray(this[m_hWeapons], WeaponID, tmpWeaponInfo[0], _:WeaponInfo))
		{
			ThrowError("Invalid parent assigned to weapon. Weapon - %i Class - %i Parent - %i", iWeaponID, iClass, iParent);
		}
		
		iSlot = WeaponInfo_GetSlot(tmpWeaponInfo[0]);
		iParent = WeaponInfo_GetParent(tmpWeaponInfo[0]);
	}

	return iSlot;
}