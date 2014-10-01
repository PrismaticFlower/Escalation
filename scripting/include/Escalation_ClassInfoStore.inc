#if defined _escalation_classinfostore_included
#endinput
#endif
#define _escalation_classinfostore_included

#include<adt>

#define ClassInfoStoreID (7 << _:ClassInfoStore)

enum ClassInfoStore
{
	m_iObjectType, //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	Handle:m_hUpgradesScout, //!< A SourceMod Trie containing what upgrades Scout is allowed to buy.
	Handle:m_hUpgradesSoldier, //!<A SourceMod ADT Trie containing what upgrades Soldier is allowed to buy.
	Handle:m_hUpgradesPyro, //!< A SourceMod Trie containing what upgrades Pyro is allowed to buy.
	Handle:m_hUpgradesDemoman, //!< A SourceMod Trie containing what upgrades Demoman is allowed to buy.
	Handle:m_hUpgradesHeavy, //!< A SourceMod Trie containing what upgrades Heavy is allowed to buy.
	Handle:m_hUpgradesEngineer, //!< A SourceMod Trie containing what upgrades Engineer is allowed to buy.
	Handle:m_hUpgradesMedic, //!< A SourceMod Trie containing what upgrades Medic is allowed to buy.
	Handle:m_hUpgradesSpy, //!< A SourceMod Trie containing what upgrades Spy is allowed to buy.
	Handle:m_hUpgradeseSniper //!< A SourceMod Trie containing what upgrades Sniper is allowed to buy.
};

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

//! A private function used to turn a class ID into the ADT trie handle for it's upgrade permissions.
/*! \param this[] A constructed PlayerData object.
	\param TFClassType:iClass The class to fetch the array handle of.
	\return The handle of the class's trie. */
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