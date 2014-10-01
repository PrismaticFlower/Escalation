#if defined _escalation_stockattributes_included
#endinput
#endif
#define _escalation_stockattributes_included

#include<Escalation>
#include<adt>


#define StockAttributesID (11 << _:StockAttributes)

enum StockAttributes
{
	m_iObjectType, //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	Handle:m_hStockAttributes //!< A trie containing the stock attributes of all the weapons.
}

//! Constructs an empty StockAttributes object in the array provided.
/*! \param this[] An array that is created with StockAttributes being the size.
	\param String:ItemsGamePath[] A string containing the path to items_game.
	\sa StockAttributes_Destroy */
StockAttributes_ConstructFull (this[], const String:ItemsGamePath[])
{
	this[StockAttributes:m_iObjectType] = StockAttributesID;
	
	this[m_hStockAttributes] = CreateTrie();
	
	StockAttributes_ParseItemsGame(this, ItemsGamePath);
}

static StockAttributes_ParseItemsGame (this[], const String:ItemsGamePath[])
{
	new Handle:hItems = CreateKeyValues("items_game");
	FileToKeyValues(hItems, ItemsGamePath);
	
	new Handle:hAttributes = CreateTrie();
	
	KvJumpToKey(hItems, "attributes");
	
	KvGotoFirstSubKey(hItems);

	do
	{
		decl String:SectionName[32];
		decl String:AttributeName[256];
		new iIndex;
		
		KvGetSectionName(hItems, SectionName, sizeof(SectionName));
		KvGetString(hItems, "name", AttributeName, sizeof(AttributeName));
		
		if (KvGetNum(hItems, "stored_as_integer", 1) == 1)
		{
			continue;
		}
		
		iIndex = StringToInt(SectionName);
		
		SetTrieValue(hAttributes, AttributeName, iIndex);
		
	} while KvGotoNextKey(hItems);
	
	KvRewind(hItems);

	//Item Slots
	new Handle:hItemSlots = CreateArray(8);
	
	PushArrayString(hItemSlots, "melee");
	PushArrayString(hItemSlots, "primary");
	PushArrayString(hItemSlots, "secondary");
	PushArrayString(hItemSlots, "pda");
	PushArrayString(hItemSlots, "pda2");
	
	KvJumpToKey(hItems, "items");
	
	KvGotoFirstSubKey(hItems);
	
	do
	{
		decl String:SectionName[32];
		decl String:ItemSlot[32];
		
		KvGetSectionName(hItems, SectionName, sizeof(SectionName));
		KvGetString(hItems, "item_slot", ItemSlot, sizeof(ItemSlot));
	
		if (FindStringInArray(hItemSlots, ItemSlot) == -1)
		{
			continue;
		}
		
		if (! KvJumpToKey(hItems, "attributes"))
		{
			continue;
		}

		if (! KvGotoFirstSubKey(hItems))
		{
			KvGoBack(hItems);
		
			continue;
		}

		new iAttributes[ENTITY_MAX_ATTRIBUTES];
		new Float:fValues[ENTITY_MAX_ATTRIBUTES];
		new iAttributeCount;

		do
		{
			decl String:AttributeName[32];
			new iAttribute;
			new Float:fValue;
			
			KvGetSectionName(hItems, AttributeName, sizeof(AttributeName));
			
			fValue = KvGetFloat(hItems, "value");
			GetTrieValue(hAttributes, AttributeName, iAttribute);
			
			if (iAttribute != 0)
			{
				iAttributes[iAttributeCount] = iAttribute;
				fValues[iAttributeCount] = fValue;
				iAttributeCount ++;
			}
			
		} while KvGotoNextKey(hItems);

		KvGoBack(hItems);
		KvGoBack(hItems);

		if (iAttributeCount != 0)
		{
			StockAttributes_AddToContainer(this, SectionName, iAttributes, fValues);
		}
		
	} while KvGotoNextKey(hItems);

	KvRewind(hItems);
	
	CloseHandle(hAttributes);
	CloseHandle(hItems);
	CloseHandle(hItemSlots);
}

//! Destroys a StockAttributes object so it can go out of scope.
/*! \param this[] An array that is created with StockAttributes being the size.
	\sa StockAttributes_Construct */
stock StockAttributes_Destroy (this[])
{
	if (this[StockAttributes:m_iObjectType] != StockAttributesID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}

	this[StockAttributes:m_iObjectType] = 0;

	CloseHandle(this[m_hStockAttributes]);
	
	this[m_hStockAttributes] = INVALID_HANDLE;

}

static StockAttributes_AddToContainer (this[], const String:WeaponID[], const iAttributes[ENTITY_MAX_ATTRIBUTES], const Float:fValues[ENTITY_MAX_ATTRIBUTES])
{
	decl String:ValueKey[256];
	
	strcopy(ValueKey, sizeof(ValueKey), WeaponID);
	StrCat(ValueKey, sizeof(ValueKey), "_f");

	SetTrieArray(this[m_hStockAttributes], WeaponID, iAttributes, ENTITY_MAX_ATTRIBUTES);
	SetTrieArray(this[m_hStockAttributes], ValueKey, fValues, ENTITY_MAX_ATTRIBUTES);
}

bool:StockAttributes_GetItemAttributes (this[], iWeaponID, iAttributes[ENTITY_MAX_ATTRIBUTES], Float:fValues[ENTITY_MAX_ATTRIBUTES])
{
	if (this[StockAttributes:m_iObjectType] != StockAttributesID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}
	decl String:WeaponID[64];
	decl String:ValueKey[256];

	IntToString(iWeaponID, WeaponID, sizeof(WeaponID));

	strcopy(ValueKey, sizeof(ValueKey), WeaponID);
	StrCat(ValueKey, sizeof(ValueKey), "_f");

	
	GetTrieArray(this[m_hStockAttributes], WeaponID, iAttributes, ENTITY_MAX_ATTRIBUTES);
	
	return GetTrieArray(this[m_hStockAttributes], ValueKey, fValues, ENTITY_MAX_ATTRIBUTES);
}