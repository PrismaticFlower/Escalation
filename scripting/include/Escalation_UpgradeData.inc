#if defined _escalation_upgradedata_included
#endinput
#endif
#define _escalation_upgradedata_included

#include<adt>
#include<Escalation_LevelData>


/**
 * Thie fine object stores the information of an upgrade.
 */ 
enum UpgradeData
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	m_iCost, /**< The amount of credits it costs to buy each level. */
	m_iSlot, /**< The weapon slot this upgrade affects. */
	bool:m_bPassive, /**< Is the upgrade passive? If it is we can't apply it to weapons that have the "While active" attribute. (The upgrade manager just applies it to a different weapon.)  */
	m_iLevels, /**< How many levels this upgrade has to it. */
	Handle:m_hLevelData /**< An array storing the attribute data of each level. */
};

static const UpgradeDataID = (5 << _:UpgradeData);

/**
 * Constructs an UpgradeData object in the array provided. 
 *
 * @param this				An array to construct the object in. 
 * @param iCost				How many credits the upgrade costs to buy.
 * @param iSlot				The weapon slot (if not a class upgrade) the upgrade applies to.
 * @param bPassive			If true the upgrade will be a class upgrade.
 *
 * @noreturn
 */
UpgradeData_Construct(this[], iCost, iSlot, bool:bPassive = false)
{
	this[UpgradeData:m_iObjectType] = UpgradeDataID;
	this[m_iCost] = iCost;
	this[m_iSlot] = iSlot;
	this[m_bPassive] = bPassive;
	this[m_iLevels] = 0;
	
	this[m_hLevelData] = CreateArray(_:LevelData);
}


/**
 * Destroys an UpgradeData object so it can safely go out of scope. 
 *
 * @param this				An UpgradeData object to destroy.
 *
 * @error					Invalid object.
 * @noreturn
 */
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

/**
 * Adds a level to the upgrade
 *
 * @param this				An UpgradeData object.
 * @param Level				The LevelData object containing the attribute information.
 *
 * @error					Invalid object.
 * @noreturn
 */
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

/**
 * Gets the cost of the upgrade.
 *
 * @param this				An UpgradeData object.
 *
 * @error					Invalid object.
 * @return					The cost of the credits.
 */
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

/**
 * Gets the weapon slot the upgrade takes up.
 *
 * @param this				An UpgradeData object.
 *
 * @error					Invalid object.
 * @return					The weapon slot of the upgrade.
 */
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


/**
 * Checks if the upgrade is passive.
 *
 * @param this				An UpgradeData object.
 *
 * @error					Invalid object.
 * @return					True if the upgrade is passive, false if it isn't.
 */
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

/**
 * Returns the level count of the upgrade.
 *
 * @param this				An UpgradeData object.
 *
 * @error					Invalid object.
 * @return					The level count of the upgrade.
 */
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


/**
 * Returns the level count of the upgrade.
 *
 * @param this				An UpgradeData object.
 * @param iLevel			The level to get the data of.
 * @param Level				An array created with the size LevelData to store the level information in.	
 *
 * @error					Invalid object or level out of bounds.
 * @noreturn
 */
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