#if defined _escalation_kvmap_included
#endinput
#endif
#define _escalation_kvmap_included

#include<Escalation_Constants>
#include<adt>

#define SECTION_NAME_MAX_LENGTH 256
#define VALUE_NAME_MAX_LENGTH 256
#define KEYVALUE_NAME_MAX_LENGTH (SECTION_NAME_MAX_LENGTH + VALUE_NAME_MAX_LENGTH + 1)

/**
 * Acts a wraper around a hash map
 */ 
enum KVMap
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	Handle:m_hKVMap /**< A hash map containing the values of all the keys. */
}

static const KVMapID  = (12 << _:KVMap);

/**
 * Constructs a KVMap object in the array provided. 
 *
 * @param this				An array to construct the object in.
 *
 * @noreturn
 */
KVMap_Construct (this[])
{
	this[KVMap:m_iObjectType] = KVMapID;
	
	this[m_hKVMap] = CreateTrie();
}

/**
 * Destroys a stock attributes object so it can safely go out of scope.
 *
 * @param this				A KVMap object to destroy.
 *
 * @error					Invalid object.
 * @noreturn
 */
stock KVMap_Destroy (this[])
{
	if (this[KVMap:m_iObjectType] != KVMapID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}

	this[KVMap:m_iObjectType] = 0;

	CloseHandle(this[m_hKVMap]);
	
	this[m_hKVMap] = INVALID_HANDLE;

}

/**
 * Set's the value of a key in the map.
 *
 * @param this				A KVMap object.
 * @param Section			The name of the section to set the key in.
 * @param Key				The name of the key to set.
 * @param cell				The cell to store.
 *
 * @error					Invalid object.
 * @return					True if the value was set, false if some error occurred.
 */
bool:KVMap_SetCell (this[], const String:Section[SECTION_NAME_MAX_LENGTH], const String:Key[VALUE_NAME_MAX_LENGTH], any:cell)
{
	if (this[KVMap:m_iObjectType] != KVMapID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}

	decl String:IndexKey[KEYVALUE_NAME_MAX_LENGTH];

	strcopy(IndexKey, sizeof(IndexKey), Section);
	StrCat(IndexKey, sizeof(IndexKey), ".");
	StrCat(IndexKey, sizeof(IndexKey), Key);

	return SetTrieValue(this[m_hKVMap], IndexKey, cell);
}

/**
 * Gets's the value of a key in the map.
 *
 * @param this				A KVMap object.
 * @param Section			The name of the section to set the key in.
 * @param Key				The name of the key to set.
 * @param cell				A reference to a cell to store the value in.
 *
 * @error					Invalid object.
 * @return					True if the value was fetched, false if some error occurred.
 */
stock bool:KVMap_GetCell (this[], const String:Section[SECTION_NAME_MAX_LENGTH], const String:Key[VALUE_NAME_MAX_LENGTH], &any:cell)
{
	if (this[KVMap:m_iObjectType] != KVMapID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}

	decl String:IndexKey[KEYVALUE_NAME_MAX_LENGTH];
	
	strcopy(IndexKey, sizeof(IndexKey), Section);
	StrCat(IndexKey, sizeof(IndexKey), ".");
	StrCat(IndexKey, sizeof(IndexKey), Key);

	return GetTrieValue(this[m_hKVMap], IndexKey, cell);
}

/**
 * Using a complete index string, gets's the value of a key in the map.
 *
 * @param this				A KVMap object.
 * @param IndexKey			The complete index string of the value. I.e "section.key"
 * @param cell				A reference to a cell to store the value in.
 *
 * @error					Invalid object.
 * @return					True if the value was fetched, false if some error occurred.
 */
bool:KVMap_IndexGetCell (this[], const String:IndexKey[KEYVALUE_NAME_MAX_LENGTH], &any:cell)
{
	if (this[KVMap:m_iObjectType] != KVMapID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}

	return GetTrieValue(this[m_hKVMap], IndexKey, cell);
}

/**
 * Using a complete index string, sets's the value of a key in the map.
 *
 * @param this				A KVMap object.
 * @param IndexKey			The complete index string of the value. I.e "section.key"
 * @param cell				The cell to store.
 *
 * @error					Invalid object.
 * @return					True if the value was set, false if some error occurred.
 */
bool:KVMap_IndexSetCell (this[], const String:IndexKey[KEYVALUE_NAME_MAX_LENGTH], any:cell)
{
	if (this[KVMap:m_iObjectType] != KVMapID)
	{
		ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
	}

	return SetTrieValue(this[m_hKVMap], IndexKey, cell);
}