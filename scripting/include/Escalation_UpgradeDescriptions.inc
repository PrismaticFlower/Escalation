#if defined _escalation_upgradedescriptions_included
#endinput
#endif
#define _escalation_upgradedescriptions_included

#include<adt>

#define UpgradeDescriptionsID (8 << _:UpgradeDescriptions)

//! Stores the translation strings and values of the descriptions for the upgarde menu of each upgrade.
enum UpgradeDescriptions
{
	m_iObjectType, //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	Handle:m_hDescriptions, //!< A SourceMod trie (hashmap since 1.6) used to store the descriptions.
}

//! Constructs an empty UpgradeDescriptions object in the array provided.
/*! \param this[] An array that is created with UpgradeDescriptions being the size.
	\sa UpgradeDescriptions_Destroy */
UpgradeDescriptions_Construct (this[])
{
	this[UpgradeDescriptions:m_iObjectType] = UpgradeDescriptionsID;	
	
	this[m_hDescriptions] = CreateTrie();
}

//! Destroys a UpgradeDescriptions object so that it's array can safely go out of scope.
/*! \param this[] An array containing a constructed UpgradeDescriptions object.
	\sa UpgradeDescriptions_Construct */
UpgradeDescriptions_Destroy (this[])
{
	if (this[UpgradeDescriptions:m_iObjectType] != UpgradeDescriptionsID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}
	
	this[UpgradeDescriptions:m_iObjectType] = 0;
	
	CloseHandle(this[m_hDescriptions]);
	
	this[m_hDescriptions] = INVALID_HANDLE;
}


//! Adds a string to the container.
/*! \param this[] An array containing a constructed WeaponInfo object.
	\param String:Upgrade[] The upgrade to add the translation key under.
	\param iIndex The index of description (upgrades have multiple ones describing each attribute)
	\param String:Description[] The translation key to add to the container.
*/
UpgradeDescriptions_AddDescription(this[], const String:Upgrade[], iIndex, const String:Description[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDescriptions:m_iObjectType] != UpgradeDescriptionsID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	decl String:Key[256];
	decl String:Index[16];
	
	IntToString(iIndex, Index, sizeof(Index));

	strcopy(Key, sizeof(Key), Upgrade);
	StrCat(Key, sizeof(Key), Index);
	
	SetTrieString(this[m_hDescriptions], Key, Description);
}

//! Adds a value to the container.
/*! \param this[] An array containing a constructed WeaponInfo object.
	\param String:Upgrade[] The upgrade to add the value under.
	\param iIndex The index of value (upgrades have multiple ones describing each attribute)
	\param iLevel The level to add the value under.
	\param iValue The value itself to add to the container.
	\param String:Description[] The translation key to add to the container.
*/
UpgradeDescriptions_AddValue(this[], const String:Upgrade[], iIndex, iLevel, iValue)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDescriptions:m_iObjectType] != UpgradeDescriptionsID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	decl String:Key[256];
	decl String:Index[16];
	decl String:Level[16];

	IntToString(iIndex, Index, sizeof(Index));	
	IntToString(iLevel, Level, sizeof(Level));

	strcopy(Key, sizeof(Key), Upgrade);
	StrCat(Key, sizeof(Key), Index);
	StrCat(Key, sizeof(Key), Level);

	SetTrieValue(this[m_hDescriptions], Key, iValue);
}


//! Gets a string from the container.
/*! \param this[] An array containing a constructed WeaponInfo object.
	\param String:Upgrade[] The upgrade to get the translation key of.
	\param iIndex The index of key (upgrades have multiple ones describing each attribute)
	\param String:Description[] The buffer to store the translation key in.
	\param iSize The size of aforementioned buffer.
*/
UpgradeDescriptions_GetDescription(this[], const String:Upgrade[], iIndex, String:Description[], iSize)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[UpgradeDescriptions:m_iObjectType] != UpgradeDescriptionsID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	decl String:Key[256];
	decl String:Index[16];
	
	IntToString(iIndex, Index, sizeof(Index));

	strcopy(Key, sizeof(Key), Upgrade);
	StrCat(Key, sizeof(Key), Index);


	if (! GetTrieString(this[m_hDescriptions], Key, Description, iSize))
	{
		ThrowError("Attempt to fetch invalid translation key from container. Upgrade - %s iIndex - %i", Upgrade, iIndex);
	}
}

//! Gets a value from the container.
/*! \param this[] An array containing a constructed WeaponInfo object.
	\param String:Upgrade[] The upgrade to get the translation key of.
	\param iIndex The index of key (upgrades have multiple ones describing each attribute)
	\param iLevel The level to get the value of.
	\return The value from the container.
*/
UpgradeDescriptions_GetValue(this[], const String:Upgrade[], iIndex, iLevel)
{
	new iValue;
	decl String:Key[256];
	decl String:Index[16];
	decl String:Level[16];

	IntToString(iIndex, Index, sizeof(Index));	
	IntToString(iLevel, Level, sizeof(Level));

	strcopy(Key, sizeof(Key), Upgrade);
	StrCat(Key, sizeof(Key), Index);
	StrCat(Key, sizeof(Key), Level);

	if (! GetTrieValue(this[m_hDescriptions], Key, iValue))
	{
		ThrowError("Attempt to fetch invalid value from container. Upgrade - %s iIndex - %i iLevel - %i", Upgrade, iIndex, iLevel);
	}

	return iValue;
}