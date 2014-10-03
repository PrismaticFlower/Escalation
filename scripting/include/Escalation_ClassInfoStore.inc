#if defined _escalation_classinfostore_included
#endinput
#endif
#define _escalation_classinfostore_included

#include<adt>

/**
 * Stores which upgrades the classes are allowed.
 */ 
enum ClassInfoStore
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	Handle:m_hUpgradesScout, /**< A hash map containing what upgrades Scout is allowed to buy. */
	Handle:m_hUpgradesSoldier, /**< A hash map containing what upgrades Soldier is allowed to buy. */
	Handle:m_hUpgradesPyro, /**< A hash map containing what upgrades Pyro is allowed to buy. */
	Handle:m_hUpgradesDemoman, /**< A hash map containing what upgrades Demoman is allowed to buy. */
	Handle:m_hUpgradesHeavy, /**< A hash map containing what upgrades Heavy is allowed to buy. */
	Handle:m_hUpgradesEngineer, /**< A hash map containing what upgrades Engineer is allowed to buy. */
	Handle:m_hUpgradesMedic, /**< A hash map containing what upgrades Medic is allowed to buy. */
	Handle:m_hUpgradesSpy, /**< A hash map containing what upgrades Spy is allowed to buy. */
	Handle:m_hUpgradeseSniper /**< A hash map containing what upgrades Sniper is allowed to buy. */
};

static const ClassInfoStoreID = (7 << _:ClassInfoStore);

/**
 * Constructs a ClassInfoStore object in the array provided. 
 *
 * @param this				An array to construct the object in.
 *
 * @noreturn
 */
ClassInfoStore_Construct (this[])
{
	this[ClassInfoStore:m_iObjectType] = ClassInfoStoreID;
	
	this[m_hUpgradesScout] = CreateTrie();
	this[m_hUpgradesSoldier] = CreateTrie();
	this[m_hUpgradesPyro] = CreateTrie();
	this[m_hUpgradesDemoman] = CreateTrie();
	this[m_hUpgradesHeavy] = CreateTrie();
	this[m_hUpgradesEngineer] = CreateTrie();
	this[m_hUpgradesMedic] = CreateTrie();
	this[m_hUpgradesSpy] = CreateTrie();
	this[m_hUpgradeseSniper] = CreateTrie();
}

/**
 * Destroys a ClassInfoStore object in so it can safely go out of scope. 
 *
 * @param this				A ClassInfoStore object to destroy.
 *
 * @error					Invalid object.
 * @noreturn
 */
ClassInfoStore_Destroy (this[])
{
	if (this[ClassInfoStore:m_iObjectType] != ClassInfoStoreID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}
	
	this[ClassInfoStore:m_iObjectType] = ClassInfoStoreID;
	
	CloseHandle(this[m_hUpgradesScout]);
	CloseHandle(this[m_hUpgradesSoldier]);
	CloseHandle(this[m_hUpgradesPyro]);
	CloseHandle(this[m_hUpgradesDemoman]);
	CloseHandle(this[m_hUpgradesHeavy]);
	CloseHandle(this[m_hUpgradesEngineer]);
	CloseHandle(this[m_hUpgradesMedic]);
	CloseHandle(this[m_hUpgradesSpy]);
	CloseHandle(this[m_hUpgradeseSniper]);
	
	this[m_hUpgradesScout] = INVALID_HANDLE;
	this[m_hUpgradesSoldier] = INVALID_HANDLE;
	this[m_hUpgradesPyro] = INVALID_HANDLE;
	this[m_hUpgradesDemoman] = INVALID_HANDLE;
	this[m_hUpgradesHeavy] = INVALID_HANDLE;
	this[m_hUpgradesEngineer] = INVALID_HANDLE;
	this[m_hUpgradesMedic] = INVALID_HANDLE;
	this[m_hUpgradesSpy] = INVALID_HANDLE;
	this[m_hUpgradeseSniper] = INVALID_HANDLE;
}

/**
 * Sets a class as being allowed an upgrade.
 *
 * @param this				A ClassInfoStore object.
 * @param iClass			The class to set as being allowed the upgrade.
 * @param Upgrade			The upgrade to allow.
 *
 * @error					Invalid object.
 * @noreturn
 */
ClassInfoStore_SetUpgradeAllowed (this[], TFClassType:iClass, const String:Upgrade[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[ClassInfoStore:m_iObjectType] != ClassInfoStoreID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	new Handle:hTrie = ClassInfoStore_ClassIDToClassTrie(this, iClass);
	
	SetTrieValue(hTrie, Upgrade, true);
}

/** 
 * Checks if a class is allowed an upgrade.
 *
 * @param this				A ClassInfoStore object.
 * @param iClass			The class to check.
 * @param Upgrade			The upgrade to see if the class is allowed.
 *
 * @error					Invalid object.
 * @return					True if the class is allowed the upgrade, false if it isn't.
 */
bool:ClassInfoStore_IsUpgradeAllowed (this[], TFClassType:iClass, const String:Upgrade[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[ClassInfoStore:m_iObjectType] != ClassInfoStoreID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	new Handle:hTrie = ClassInfoStore_ClassIDToClassTrie(this, iClass);
	new iTest;
	
	return GetTrieValue(hTrie, Upgrade, iTest);
}

/** 
 * Gets a class's hash map of allowed upgrades.
 *
 * @param this				A ClassInfoStore object.
 * @param iClass			The class to get the hash map for.
 *
 * @return					The handle to the class's hash map.
 */
static Handle:ClassInfoStore_ClassIDToClassTrie (this[], TFClassType:iClass)
{
	switch (iClass)
	{
		case TFClass_Scout:
		{
			return this[m_hUpgradesScout];
		}
		case TFClass_Soldier:
		{
			return this[m_hUpgradesSoldier];
		}
		case TFClass_Pyro:
		{
			return this[m_hUpgradesPyro];
		}
		case TFClass_DemoMan:
		{
			return this[m_hUpgradesDemoman];
		}
		case TFClass_Heavy:
		{
			return this[m_hUpgradesHeavy];
		}
		case TFClass_Engineer:
		{
			return this[m_hUpgradesEngineer];
		}
		case TFClass_Medic:
		{
			return this[m_hUpgradesMedic];
		}
		case TFClass_Spy:
		{
			return this[m_hUpgradesSpy];
		}
		case TFClass_Sniper:
		{
			return this[m_hUpgradeseSniper];
		}
		default:
		{
			ThrowError("Invalid class index. iClass - %i", iClass);
		}
	}
	
	return INVALID_HANDLE;
}