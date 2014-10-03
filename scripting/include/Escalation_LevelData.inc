#if defined _escalation_leveldata_included
#endinput
#endif
#define _escalation_leveldata_included

#include<adt>

/**
 * Data struct for storing attribute information.
 */ 
enum AttributeInfo
{
	_iAttribute,
	Float:_fValue,
	bool:_bIsPercent
}

/**
 * Stores the attribute data of an upgrade level.
 */ 
enum LevelData
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	Handle:m_hAttributes /**< An array containing all the attributes of the level. */
}

static const LevelDataID = (10 << _:LevelData);

/**
 * Constructs a LevelData object in the array provided. 
 *
 * @param this				An array to construct the object in.
 *
 * @noreturn
 */
LevelData_Construct (this[])
{
	this[LevelData:m_iObjectType] = LevelDataID;
	
	this[m_hAttributes] = CreateArray(_:AttributeInfo);
}

/**
 * Destroys a LevelData object so it can safely go out of scope. 
 *
 * @param this				A LevelData object to destroy.
 *
 * @error					Invalid object.
 * @noreturn
 */
LevelData_Destroy (this[])
{
	if (this[LevelData:m_iObjectType] != LevelDataID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}

	this[LevelData:m_iObjectType] = 0;

	CloseHandle(this[m_hAttributes]);
	
	this[m_hAttributes] = INVALID_HANDLE;

}

/**
 * Adds an attribute to the level data. 
 *
 * @param this				A LevelData object.
 * @param iAttribute		The index of the attribute to add.
 * @param fValue			The value of the attribute to add.
 * @param bIsPercent		Is the attribute's value a percent?
 *
 * @error					Invalid object.
 * @noreturn
 */
LevelData_AddAttribute (this[], iAttribute, Float:fValue, bool:bIsPercent)
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[LevelData:m_iObjectType] != LevelDataID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif


	new tmpAttribute[AttributeInfo];

	tmpAttribute[_iAttribute] = iAttribute;
	tmpAttribute[_fValue] = fValue;
	tmpAttribute[_bIsPercent] = bIsPercent;
	
	PushArrayArray(this[m_hAttributes], tmpAttribute[0]);
}

/**
 * Gets an attribute's information. 
 *
 * @param this				A LevelData object.
 * @param iPosition			The index of the attribute of the attribute to get.
 * @param Attribute			An array to store the information in, should have been created with the size AttributeInfo
 *
 * @error					Invalid object.
 * @noreturn
 */
LevelData_GetAttribute (this[], iPosition, Attribute[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[LevelData:m_iObjectType] != LevelDataID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif
	
	GetArrayArray(this[m_hAttributes], iPosition, Attribute);
}

/**
 * Gets number of attributes in the object. 
 *
 * @param this				A LevelData object.
 *
 * @error					Invalid object.
 * @return					The number of attributes the level has.
 */
LevelData_GetAttributeCount (this[])
{
#if defined USE_OBJECT_SAFETY_CHECK
	if (this[LevelData:m_iObjectType] != LevelDataID)
	{
		ThrowError("Invalid object passed to function. A constructed object is required.");
	}
#endif

	return GetArraySize(this[m_hAttributes]);
}