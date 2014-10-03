#if defined _escalation_upgradedescriptions_included
#endinput
#endif
#define _escalation_upgradedescriptions_included

#include<adt>

/**
 * Stores the translation strings and values of the descriptions for the upgarde menu of each upgrade.
 */
enum UpgradeDescriptions
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	Handle:m_hDescriptions, /**< A hashmap used to store the descriptions. */
}

static const UpgradeDescriptionsID = (8 << _:UpgradeDescriptions);


/**
 * Constructs an UpgradeDescriptions object in the array provided. 
 *
 * @param this				An array to construct the object in.
 *
 * @noreturn
 */
UpgradeDescriptions_Construct (this[])
{
	this[UpgradeDescriptions:m_iObjectType] = UpgradeDescriptionsID;	
	
	this[m_hDescriptions] = CreateTrie();
}

/**
 * Destroys an UpgradeDescriptions object so it can safely go out of scope. 
 *
 * @param this				An UpgradeDescriptions object to destroy.
 *
 * @error					Invalid object.
 * @noreturn
 */
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

/**
 * Adds a description's translation key to an upgrade. 
 *
 * @param this				An UpgradeDescriptions object.
 * @param Upgrade			The name of the upgrade to add the description under.
 * @param iIndex			The index of the description.
 * @param Description		The translation key of the description.
 *
 * @error					Invalid object.
 * @noreturn
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

/**
 * Adds a description's value to an upgrade. 
 *
 * @param this				An UpgradeDescriptions object.
 * @param Upgrade			The name of the upgrade to add the value under.
 * @param iIndex			The index of the description.
 * @param iLevel			The level to add the value under.
 * @param iValue			The value to add.
 *
 * @error					Invalid object.
 * @noreturn
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


/**
 * Gets a description's translation key for an upgrade. 
 *
 * @param this				An UpgradeDescriptions object.
 * @param Upgrade			The name of the upgrade to get the description of.
 * @param iIndex			The index of the description.
 * @param Description		The buffer to store the translation key in.
 * @param iSize				The max size of the above buffer.
 *
 * @error					Invalid object or attempt to fetch invalid description.
 * @noreturn
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

/**
 * Gets a description's value for an upgrade. 
 *
 * @param this				An UpgradeDescriptions object.
 * @param Upgrade			The name of the upgrade to get the value of.
 * @param iIndex			The index of the description.
 * @param iLevel			The level to get the value of.
 *
 * @error					Invalid object or attempt to fetch invalid description.
 * @return					The value associated with the description
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