#if defined _escalation_upgradedata_included
#endinput
#endif
#define _escalation_upgradedata_included

#include<adt>
#include<Escalation_LevelData>

#define UpgradeDataID (5 << _:UpgradeData)

//! Thie fine object stores the information of an upgrade, save for it's name since the container it's stored in is supposed to handle that.
enum UpgradeData
{
	m_iObjectType, //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	m_iCost, //!< The amount of credits it costs to buy each level.
	m_iSlot, //!< The weapon slot this upgrade affects.
	bool:m_bPassive, //!< Is the upgrade passive? If it is we can't apply it to weapons that have the "While active" attribute. (The upgrade manager just applies it to a different weapon.)
	m_iLevels, //!< How many levels this upgrade has to it. 
	Handle:m_hLevelData //!< An ADT array storing the attribute data of each level.
};

//! Constructs a UpgradeData object in the array provided. 
/*! \param this[] An array that has been created with UpgradeData as the size.
	\param iCost How many credits the upgrade costs.
	\param iSlot The weapon slot this upgrade applies to.
	\param bool:bPassive Is this a passive upgrade?
	\sa UpgradeData_Destroy */
UpgradeData_Construct(this[], iCost, iSlot, bool:bPassive)
{
	this[UpgradeData:m_iObjectType] = UpgradeDataID;
	this[m_iCost] = iCost;
	this[m_iSlot] = iSlot;
	this[m_bPassive] = bPassive;
	this[m_iLevels] = 0;
	
	this[m_hLevelData] = CreateArray(_:LevelData);
}

//! Destroys a UpgradeData object so it can go out of scope. 
/*! \param this[] A constructed UpgradeData object.
	\sa UpgradeData_Construct */
UpgradeData_Destroy (this[])
{
	if (this[UpgradeData:m_iObjectType] != UpgradeDataID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}

	this[UpgradeData:m_iObjectType] = 0;
	this[m_iCost] = 0;
	this[m_iSlot] = 0;
	this[m_bPassive] = false;
	this[m_iLevels] = 0;
	
	for (new i = 0; i < GetArraySize(this[m_hLevelData]); i++)
	{
		decl tmpLevelData[LevelData];
	
		GetArrayArray(this[m_hLevelData], i, tmpLevelData[0]);
		
		LevelData_Destroy(tmpLevelData[0]);
	}
	
	CloseHandle(this[m_hLevelData]);
	
	this[m_hLevelData] = INVALID_HANDLE;
}

//! Adds an upgrade level to the object. 
/*! \param this[] A constructed UpgradeData object.
	\param const Level[] A LevelData object containing the information of this level's attributes.
	\sa UpgradeData_GetLevelCount */
UpgradeData_AddLevel (this[], const Level[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[UpgradeData:m_iObjectType] != UpgradeDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	PushArrayArray(this[m_hLevelData], Level);
	
	this[m_iLevels] ++;	
}

//! Returns the cost of the upgrade.
/*! \param this[] A constructed UpgradeData object.
	\return The cost of the upgrade. */
UpgradeData_GetCost (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[UpgradeData:m_iObjectType] != UpgradeDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	return this[m_iCost];
}

//! Returns the slot of the upgrade.
/*! \param this[] A constructed UpgradeData object.
	\return The slot of the upgrade. */
UpgradeData_GetSlot (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[UpgradeData:m_iObjectType] != UpgradeDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	return this[m_iSlot];
}

//! Returns if the upgrade is passive.
/*! \param this[] A constructed UpgradeData object.
	\return True if the upgrade is passive, false if it is not. */
bool:UpgradeData_IsPassive (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[UpgradeData:m_iObjectType] != UpgradeDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	return this[m_bPassive];
}

//! Returns the level count of the upgrade.
/*! \param this[] A constructed UpgradeData object.
	\return The level count of the upgrade. */
UpgradeData_GetLevelCount (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[UpgradeData:m_iObjectType] != UpgradeDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	return this[m_iLevels];
}

//! Gets the information of a level of the upgrade.
/*! \param this[] A constructed UpgradeData object.
	\param iLevel The level to get the information of.
	\param Level[] An array created with LevelData as the size to store the level object in.*/
UpgradeData_GetLevel(this[], iLevel, Level[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[UpgradeData:m_iObjectType] != UpgradeDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
		if (iLevel > this[m_iLevels])
		{
			ThrowError("iLevel is greater than the upgrade's max level. iLevel - %i m_iLevels - %i", iLevel, this[m_iLevels]);
		}
	#endif	
	
	
	GetArrayArray(this[m_hLevelData], (iLevel - 1), Level);
}