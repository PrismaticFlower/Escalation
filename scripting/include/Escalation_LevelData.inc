#if defined _escalation_leveldata_included
#endinput
#endif
#define _escalation_leveldata_included

#include<adt>


#define LevelDataID (10 << _:LevelData)

enum AttributeInfo
{
	_iAttribute,
	Float:_fValue,
	bool:_bIsPercent
}


enum LevelData
{
	m_iObjectType, //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	Handle:m_hAttributes //!< An array containing all the attributes of the level.
}

//! Constructs an empty LevelData object in the array provided.
/*! \param this[] An array that is created with LevelData being the size.
	\sa LevelData_Destroy */
LevelData_Construct (this[])
{
	this[LevelData:m_iObjectType] = LevelDataID;
	
	this[m_hAttributes] = CreateArray(_:AttributeInfo);
}

//! Destroys a LevelData object so it can go out of scope.
/*! \param this[] An array that is created with LevelData being the size.
	\sa LevelData_Construct */
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

//! Adds an attribute to the level data object.
/*! \param this[] An array that is created with LevelData being the size.
	\param iAttribute You know, the item definition index of the attribute we're adding.
	\param fValue The value of the attribute we're adding.
	\param bIsPercent Is the value a percentage?
	\sa LevelData_GetAttribute */
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

//! Gets an attribute from the object.
/*! \param this[] An array that is created with LevelData being the size.
	\param iPosition The index of the attribute to fetch the information of.
	\param Attribute[] An array to store the information in, should have been created with the size AttributeInfo.
	\sa LevelData_AddAttribute */
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

//! Gets the number of attributes in the object.
/*! \param this[] An array that is created with LevelData being the size.
	\return The number of attributes in the object.
	\sa LevelData_AddAttribute */
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