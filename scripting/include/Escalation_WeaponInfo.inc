#if defined _escalation_weaponinfo_included
#endinput
#endif
#define _escalation_weaponinfo_included

#include<adt>

/** 
 * Upgrade permissions for a weapon.
 */
enum WeaponUpgradePermissions
{
	Upgrade_Not_Allowed = 0, /**< The upgrade is not allowed on this weapon. You dont' need to disallow all upgrades you don't want a weapon having, this the default value. */
	Upgrade_Allowed = 1, /**< The upgrade is allowed on this weapon. */
	Upgrade_Allowed_Hidden = 2, /**< The upgrade is allowed on this weapon but is hidden from the upgrade menu. */
	Upgrade_Check_Parent /**< The upgrade isn't allowed on this weapon but the weapon has a parent that should be checked. This is the default value when the weapon's parent doesn't equal WEAPONINFO_NO_PARENT. */
};

#define WEAPONINFO_NO_PARENT -1
#define WEAPONINFO_INVALID_SLOT -1


/**
 * Stores information about a weapon, like what upgrades it is allowed,
 * what slot the weapon is used in and what weapon it is a child of.
 */
enum WeaponInfo 
{
	m_iObjectType,  /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	m_iParent, /**< The weapon index of the parent of this weapon. */
	m_iWeaponSlot, /**<  The slot this weapon belongs in. */
	Handle:m_hAllowedUpgradesTrie, /**< An associative array of allowed upgrades on this weapon. These are indexed by integers and the values are those in the enum WeaponUpgradePermissions. */
};

static const WeaponInfoID = (1 << _:WeaponInfo); /**< Each object recieves it's own ID. As a rule it is i << ObjectEnum. With i being the order the object's code was written in. */

/**
 * Constructs a WeaponInfo object in the array provided and initializes it's members to those provided. 
 *
 * @param this				An array to construct the object in. 
 * @param iParent			The weapon to parent this weapon to.
 * @param iSlot				The slot this weapon takes up.
 *
 * @noreturn
 */
WeaponInfo_ConstructFull (this[], iParent, iSlot)
{
	this[m_iObjectType] = WeaponInfoID;
	this[m_iParent] = iParent;
	this[m_iWeaponSlot] = iSlot;
	
	this[m_hAllowedUpgradesTrie] = CreateTrie();
}

/**
 * Destroys a WeaponInfo object so that it can safely go out of scope.
 *
 * @param this				A WeaponInfo object to destroy. 
 *
 * @error					Invalid object.
 * @noreturn
 */
WeaponInfo_Destroy (this[])
{
	if (this[m_iObjectType] != WeaponInfoID)
	{
		ThrowError("Invalid object passed to destructor. A constructed object is required.");
	}
	
	this[m_iObjectType] = 0;
	this[m_iParent] = 0;
	
	if (this[m_hAllowedUpgradesTrie] != INVALID_HANDLE)
	{
		CloseHandle(this[m_hAllowedUpgradesTrie]);
		this[m_hAllowedUpgradesTrie] = INVALID_HANDLE;
	}
}

/**
 * Sets an upgrade's permissions with the weapon.
 *
 * @param this				A WeaponInfo object. 
 * @param Upgrade			The name of the upgrade to check the permissions of. 
 * @param iPermissions		The permissions to set the upgrade as having.
 *
 * @error					Invalid object.
 * @noreturn
 */
WeaponInfo_SetUpgradePermissions (this[], const String:Upgrade[], WeaponUpgradePermissions:iPermissions)
{

#if defined USE_OBJECT_SAFETY_CHECK
	if (this[m_iObjectType] != WeaponInfoID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif
	
	SetTrieValue(this[m_hAllowedUpgradesTrie], Upgrade, iPermissions);
}

/**
 * Gets an upgrade's permissions with the weapon.
 *
 * @param this				A WeaponInfo object. 
 * @param Upgrade			The name of the upgrade to check the permissions of. 
 *
 * @error					Invalid object.
 * @return					The permissions assigned to the upgrade.
 */
WeaponUpgradePermissions:WeaponInfo_GetUpgradePermissions (this[], const String:Upgrade[])
{

#if defined USE_OBJECT_SAFETY_CHECK
	if (this[m_iObjectType] != WeaponInfoID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	new WeaponUpgradePermissions:iValue;
	
	if (! GetTrieValue(this[m_hAllowedUpgradesTrie], Upgrade, iValue))
	{
		if (this[m_iParent] != WEAPONINFO_NO_PARENT)
		{
			return Upgrade_Check_Parent;
		}
		else
		{
			return Upgrade_Not_Allowed;
		}
	}
	else
	{
		return iValue;
	}
}


/**
 * Gets a weapon's parent ID.
 *
 * @param this				A WeaponInfo object. 
 *
 * @error					Invalid object.
 * @return					The ID of the weapon's parent.
 */
WeaponInfo_GetParent (this[])
{

#if defined USE_OBJECT_SAFETY_CHECK
	if (this[m_iObjectType] != WeaponInfoID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif
	
	return this[m_iParent];
}

/**
 * Gets a weapon's slot.
 *
 * @param this				A WeaponInfo object. 
 *
 * @error					Invalid object.
 * @return					The slot the weapon occupies.
 */
WeaponInfo_GetSlot (this[])
{

#if defined USE_OBJECT_SAFETY_CHECK
	if (this[m_iObjectType] != WeaponInfoID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif
	
	return this[m_iWeaponSlot];
}