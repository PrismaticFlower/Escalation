#if defined _escalation_weaponinfo_included
#endinput
#endif
#define _escalation_weaponinfo_included

#include<adt>

//! Used by WeaponInfo to store permissions for an upgrade.
/*! Used by WeaponInfo in m_hAllowedUpgradesTrie as the stored value.
*/
enum WeaponUpgradePermissions
{
	Upgrade_Not_Allowed = 0, //!< The upgrade is not allowed on this weapon. You dont' need to disallow all upgrades you don't want a weapon having, this the default value.
	Upgrade_Allowed = 1, //!< The upgrade is allowed on this weapon.
	Upgrade_Allowed_Hidden = 2, //!< The upgrade is allowed on this weapon but is hidden from the upgrade menu.
	Upgrade_Check_Parent //!< The upgrade isn't allowed on this weapon but the weapon has a parent that should be checked. This is the default value when the weapon's parent doesn't equal WEAPONINFO_NO_PARENT.
};

#define WEAPONINFO_NO_PARENT -1 //!< Can be set as a weapon's parent so that it won't use a parent.
#define WEAPONINFO_INVALID_SLOT -1
#define WeaponInfoID (1 << _:WeaponInfo) //!< Each object recieves it's own ID. As a rule it is i << ObjectEnum. With i being the order the object's code was written in.

//! Used to store information on a weapon for the plugin.
/*! Stores information about a weapon for Escalation that is used to check if a weapon is allowed an upgrade and also is used to build an upgrade menu for the weapon.
*/
enum WeaponInfo 
{
	m_iObjectType,  //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	m_iParent, //!< The weapon index of the parent of this weapon.
	m_iWeaponSlot, //!< The slot this weapon belongs in.
	Handle:m_hAllowedUpgradesTrie, //!< An associative array of allowed upgrades on this weapon. These are indexed by integers and the values are those in the enum WeaponUpgradePermissions.
};

//! Constructs a WeaponInfo object in the array provided and initializes it's members to those provided. 
/*! \param this[] An array that is created with WeaponInfo being the size.
	\param iParent A valid TF2 weapon index that will act as this weapon's parent.
	\param iSlot The slot this weapon takes up in a player's loadout.
	\sa WeaponInfo_Construct, WeaponInfo_ConstructCopy and WeaponInfo_Destroy */
WeaponInfo_ConstructFull (this[], iParent, iSlot)
{
	this[m_iObjectType] = WeaponInfoID;
	this[m_iParent] = iParent;
	this[m_iWeaponSlot] = iSlot;
	
	this[m_hAllowedUpgradesTrie] = CreateTrie();
}

//! Destroys a WeaponInfo object so that it's array can safely go out of scope.
/*! \param this[] An array containing a constructed WeaponInfo object.
	\sa WeaponInfo_Construct, WeaponInfo_ConstructFull and WeaponInfo_ConstructCopy */
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

//! Sets the permissions of an upgrade for the weapon.
/*! \param this[] An array containing a constructed WeaponInfo object.
	\param String:Upgrade[] A string containing the name of the upgrade to set permissions for.
	\param WeaponUpgradePermissions:iPermissions A value from WeaponUpgradePermissions telling the plugin the permissions of the upgrade.
	\sa WeaponUpgradePermissions
*/
WeaponInfo_SetUpgradePermissions (this[], const String:Upgrade[], WeaponUpgradePermissions:iPermissions)
{

#if defined USE_OBJECT_SAFETY_CHECK
	if (this[m_iObjectType] != WeaponInfoID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

/*	new iValue; //Needed to store the value from GetTrieValue since there wouldn't appear to be a function for checking if a key exsists in a Trie already.
	
	if (! GetTrieValue(this[m_hAllowedUpgradesTrie], Upgrade, iValue))
	{
		PushArrayString(this[m_hAllowedUpgradesArray], Upgrade);
	} */
	
	SetTrieValue(this[m_hAllowedUpgradesTrie], Upgrade, iPermissions);
}

//! Gets the permissions of an upgrade for the weapon.
/*! \param this[] An array containing a constructed WeaponInfo object.
	\param String:Upgrade[] A string containing the name of the upgrade to set permissions for.
	\return A value from WeaponUpgradePermissions telling the plugin the permissions of the upgrade.
	\sa WeaponUpgradePermissions
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

//! Gets the weapon ID of the assigned parent to the object.
/*! \param this[] An array containing a constructed WeaponInfo object.
	\return The item definition ID of the weapon's parent.
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

//! Gets the slot of the weapon.
/*! \param this[] An array containing a constructed WeaponInfo object.
	\return The slot of the weapon.
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