#if defined _escalation_playerdata_included
#endinput
#endif
#define _escalation_playerdata_included

#include<adt>
#include<Escalation_Constants>


/**
 * Stores all a client's variables so they're all nice and encapsulated.
 */
enum PlayerData
{
	m_iObjectType, /**< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.) */
	m_iClient, /**< The index of the client the object was created for. */
	
	//Upgrade QueueZ!
	Handle:m_hUpgradeQueueScout, /**< An array of upgrade queue structs for Scout. */
	Handle:m_hUpgradeQueueSoldier, /**< An array of upgrade queue structs for Soldier. */
	Handle:m_hUpgradeQueuePyro, /**< An array of upgrade queue structs for Pyro. */
	Handle:m_hUpgradeQueueDemoman, /**< An array of upgrade queue structs for Demoman. */
	Handle:m_hUpgradeQueueHeavy, /**< An array of upgrade queue structs for Heavy. */
	Handle:m_hUpgradeQueueEngineer, /**< An array of upgrade queue structs for Engineer. */
	Handle:m_hUpgradeQueueMedic, /**< An array of upgrade queue structs for Medic. */
	Handle:m_hUpgradeQueueSpy, /**< An array of upgrade queue structs for Spy. */
	Handle:m_hUpgradeQueueSniper, /**< An array of upgrade queue structs for Sniper. */
	
	//Highest upgrade level on Queue hash maps! 
	Handle:m_hNextLevelScout, /**< A hash map storing the current level of an upgrade on the queue for Scout. */
	Handle:m_hNextLevelSoldier, /**< A hash map storing the current level of an upgrade on the queue for Soldier. */
	Handle:m_hNextLevelPyro, /**< A hash map storing the current level of an upgrade on the queue for Pyro. */
	Handle:m_hNextLevelDemoman, /**< A hash map storing the current level of an upgrade on the queue for Demoman. */
	Handle:m_hNextLevelHeavy, /**< A hash map storing the current level of an upgrade on the queue for Heavy. */
	Handle:m_hNextLevelEngineer, /**< A hash map storing the current level of an upgrade on the queue for Engineer. */
	Handle:m_hNextLevelMedic, /**< A hash map storing the current level of an upgrade on the queue for Medic. */
	Handle:m_hNextLevelSpy, /**< A hash map storing the current level of an upgrade on the queue for Spy. */
	Handle:m_hNextLevelSniper,  /**< A hash map storing the current level of an upgrade on the queue for Sniper. */
	
	m_iQueuePosition, /**< A variable that can be used to keep track of where a client's upgrade queue has been processed up to. */
	
	m_iWeaponIndex_0, /**< The item definition index of the player's primary weapon. */
	m_iWeaponIndex_1, /**< The item definition index of the player's secondary weapon. */
	m_iWeaponIndex_2, /**< The ite- You're not really going to make me say it are you? */

	bool:m_bHaveWeaponsChanged, /**< Keeps track of if the client's weapons have changed. */
	
	Handle:m_hDeathCounter, /**< A SourceMod array used to track the amount of times the player has died to another player. */
	m_iCredits, /**< How many credits does the player have? I don't know, you don't know. This variable however does know. */
	m_iEarnedCredits, /**< Stores how many credits the client has personally earned. (Non-team objective ones.) */
	bool:m_bGiveObjectiveCredits, /**< Does the client want objective credits given to them when they join a team? */
	
	m_iCaptureStartTimer, /**< A timer for tracking when we last started capturing a control point. */
	
	bool:m_bHasOpenedMenu, /**< Has the client opened the upgrade menu at least once? */
	
	Handle:m_hHUDText, /**< A HUD text synchronizer object for displaying the client's credits count. */
	Handle:m_hHUDReminderText /**< A HUD text synchronizer object for reminding the client to open the upgrade menu. */
};

static const PlayerDataID = (4 << _:PlayerData);

/**
 * Constructs a PlayerData object in the array provided. 
 *
 * @param this				An array to construct the object in. 
 * @param iClient			The index of the client the object is being created for.
 *
 * @noreturn
 */
PlayerData_ConstructFull (this[], iClient)
{
	this[PlayerData:m_iObjectType] = PlayerDataID;
	
	this[m_iClient] = iClient;
	
	this[m_hUpgradeQueueScout] = CreateArray(_:UpgradeQueue);
	this[m_hUpgradeQueueSoldier] = CreateArray(_:UpgradeQueue);
	this[m_hUpgradeQueuePyro] = CreateArray(_:UpgradeQueue);
	this[m_hUpgradeQueueDemoman] = CreateArray(_:UpgradeQueue);
	this[m_hUpgradeQueueHeavy] = CreateArray(_:UpgradeQueue);
	this[m_hUpgradeQueueEngineer] = CreateArray(_:UpgradeQueue);
	this[m_hUpgradeQueueMedic] = CreateArray(_:UpgradeQueue);
	this[m_hUpgradeQueueSpy] = CreateArray(_:UpgradeQueue);
	this[m_hUpgradeQueueSniper] = CreateArray(_:UpgradeQueue);
	
	this[m_hNextLevelScout] = CreateTrie();
	this[m_hNextLevelSoldier] = CreateTrie();
	this[m_hNextLevelPyro] = CreateTrie();
	this[m_hNextLevelDemoman] = CreateTrie();
	this[m_hNextLevelHeavy] = CreateTrie();
	this[m_hNextLevelEngineer] = CreateTrie();
	this[m_hNextLevelMedic] = CreateTrie();
	this[m_hNextLevelSpy] = CreateTrie();
	this[m_hNextLevelSniper] = CreateTrie();

	this[m_iWeaponIndex_0] = -1; //If Valve make a weapon with the item definition index of -1 I'll be shocked.
	this[m_iWeaponIndex_1] = -1;
	this[m_iWeaponIndex_2] = -1;
	
	this[m_bHaveWeaponsChanged] = false;
	
	this[m_iQueuePosition] = 0;	
	this[m_iCredits] = 0;
	this[m_iEarnedCredits] = 0;
	
	this[m_hDeathCounter] = CreateArray(1);
	
	for (new i; i <= MaxClients; i++)
	{
		PushArrayCell(this[m_hDeathCounter], 0);
	}
	
	this[m_iCaptureStartTimer] = 0;
	this[m_bHasOpenedMenu] = false;
	
	this[m_hHUDText] = CreateHudSynchronizer();
	this[m_hHUDReminderText] = CreateHudSynchronizer();
}


/**
 * Destroys a PlayerData object so it can safely go out of scope. 
 *
 * @param this				A PlayerData object to destroy. 
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_Destroy (this[])
{
	if (this[PlayerData:m_iObjectType] != PlayerDataID)
	{
		ThrowError("Invalid object passed to destructor. A valid, constructed object is expected.");
	}
	
	this[PlayerData:m_iObjectType] = 0;

	if (IsClientInGame(this[m_iClient]))
	{
		ClearSyncHud(this[m_iClient], this[m_hHUDText]);
		ClearSyncHud(this[m_iClient], this[m_hHUDReminderText]);
	}

	PlayerData_CloseHandles(this);
	
	this[m_iQueuePosition] = 0;
	this[m_iCredits] = 0;
	this[m_iEarnedCredits] = 0;
	
	this[m_iCaptureStartTimer] = 0;
	this[m_bHasOpenedMenu] = false;
}

/**
 * Safely closes all of the object's handles.
 *
 * @param this				A PlayerData object to close the handles of. 
 *
 * @noreturn
 */
static PlayerData_CloseHandles (this[])
{	
	CloseHandle(this[m_hUpgradeQueueScout]);
	CloseHandle(this[m_hUpgradeQueueSoldier]);
	CloseHandle(this[m_hUpgradeQueuePyro]);
	CloseHandle(this[m_hUpgradeQueueDemoman]);
	CloseHandle(this[m_hUpgradeQueueHeavy]);
	CloseHandle(this[m_hUpgradeQueueEngineer]);
	CloseHandle(this[m_hUpgradeQueueMedic]);
	CloseHandle(this[m_hUpgradeQueueSpy]);
	CloseHandle(this[m_hUpgradeQueueSniper]);
	
	this[m_hUpgradeQueueScout] = INVALID_HANDLE;
	this[m_hUpgradeQueueSoldier] = INVALID_HANDLE;
	this[m_hUpgradeQueuePyro] = INVALID_HANDLE;
	this[m_hUpgradeQueueDemoman] = INVALID_HANDLE;
	this[m_hUpgradeQueueHeavy] = INVALID_HANDLE;
	this[m_hUpgradeQueueEngineer] = INVALID_HANDLE;
	this[m_hUpgradeQueueMedic] = INVALID_HANDLE;
	this[m_hUpgradeQueueSpy] = INVALID_HANDLE;
	this[m_hUpgradeQueueSniper] = INVALID_HANDLE;

	CloseHandle(this[m_hNextLevelScout]);
	CloseHandle(this[m_hNextLevelSoldier]);
	CloseHandle(this[m_hNextLevelPyro]);
	CloseHandle(this[m_hNextLevelDemoman]);
	CloseHandle(this[m_hNextLevelHeavy]);
	CloseHandle(this[m_hNextLevelEngineer]);
	CloseHandle(this[m_hNextLevelMedic]);
	CloseHandle(this[m_hNextLevelSpy]);
	CloseHandle(this[m_hNextLevelSniper]);
	
	this[m_hNextLevelScout] = INVALID_HANDLE;
	this[m_hNextLevelSoldier] = INVALID_HANDLE;
	this[m_hNextLevelPyro] = INVALID_HANDLE;
	this[m_hNextLevelDemoman] = INVALID_HANDLE;
	this[m_hNextLevelHeavy] = INVALID_HANDLE;
	this[m_hNextLevelEngineer] = INVALID_HANDLE;
	this[m_hNextLevelMedic] = INVALID_HANDLE;
	this[m_hNextLevelSpy] = INVALID_HANDLE;
	this[m_hNextLevelSniper] = INVALID_HANDLE;
	
	
	CloseHandle(this[m_hDeathCounter]);
	this[m_hDeathCounter] = INVALID_HANDLE;
	
	CloseHandle(this[m_hHUDText]);
	CloseHandle(this[m_hHUDReminderText]);
	
	this[m_hHUDText] = INVALID_HANDLE;
	this[m_hHUDReminderText] = INVALID_HANDLE;
}

/************************Upgrade Queue Functions************************/

/**
 * Pushes an upgrade onto the client's upgrade queue. 
 *
 * @param this				A PlayerData object. 
 * @param iClass			The class whose upgrade queue to push the upgrade onto.
 * @param Upgrade			The upgrade to push onto the queue.
 * @param iMaxLevel			The max level of the upgrade to push onto the queue.
 * @param iLevel			A variable by reference to store the the level of the upgrade pushed onto the queue.
 *
 * @error					Invalid object or invalid class.
 * @return					True if the upgrade was pushed onto the client's queue successfully, false if the client already had the highest level of the upgrade.
 */
bool:PlayerData_PushUpgradeToQueue (this[], TFClassType:iClass, const String:Upgrade[], iMaxLevel, &iLevel)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	decl tmpUpgradeQueue[UpgradeQueue];
	new Handle:hArray = PlayerData_ClassIDToUpgradeQueue(this, iClass);
	iLevel = PlayerData_SetUpgradeNextLevel(this, Upgrade, iClass, iMaxLevel);
	
	strcopy(tmpUpgradeQueue[_Upgrade], sizeof(tmpUpgradeQueue[_Upgrade]), Upgrade)
	tmpUpgradeQueue[_iLevel] = iLevel;
	tmpUpgradeQueue[_bOwned] = false;
	
	if (tmpUpgradeQueue[_iLevel] > iMaxLevel)
	{
		return false;
	}
	else
	{
		PushArrayArray (hArray, tmpUpgradeQueue[0]);
		return true;
	}
	
}

/**
 * Gets an UpgradeQueue struct from the client's queue. 
 *
 * @param this				A PlayerData object. 
 * @param iClass			The class whose upgrade queue to deal with.
 * @param iIndex			The index of the upgrade to get from the queue.
 * @param upgradequeue		The buffer to store the UpgradeQueue struct in.
 * @param iMaxSize			The max size of the aforementioned buffer.
 *
 * @error					Invalid object, invalid class or iIndex out of range.
 * @noreturn
 */
PlayerData_GetUpgradeOnQueue (this[], TFClassType:iClass, iIndex, upgradequeue[], iMaxSize)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	new Handle:hArray = PlayerData_ClassIDToUpgradeQueue(this, iClass);
	
	GetArrayArray(hArray, iIndex, upgradequeue, iMaxSize);
}

/**
 * Sets an UpgradeQueue struct on the client's upgrade queue.  
 *
 * @param this				A PlayerData object. 
 * @param iClass			The class whose upgrade queue to deal with.
 * @param iIndex			The index of the upgrade to set on the queue.
 * @param upgradequeue		The UpgradeQueue struct to store on the queue.
 *
 * @error					Invalid object, invalid class or iIndex out of range.
 * @noreturn
 */
PlayerData_SetUpgradeOnQueue (this[], TFClassType:iClass, iIndex, const upgradequeue[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	new Handle:hArray = PlayerData_ClassIDToUpgradeQueue(this, iClass);
	
	SetArrayArray(hArray, iIndex, upgradequeue);
}

/**
 * Removes an UpgradeQueue struct from the client's upgrade queue.  
 *
 * @param this				A PlayerData object. 
 * @param iClass			The class whose upgrade queue to deal with.
 * @param iIndex			The index of the upgrade to remove from the queue.
 *
 * @error					Invalid object, invalid class or iIndex out of range.
 * @noreturn
 */
PlayerData_RemoveUpgradeFromQueue (this[], TFClassType:iClass, iIndex)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	new Handle:hArray = PlayerData_ClassIDToUpgradeQueue(this, iClass);

	decl UpgradeToRemove[UpgradeQueue];
	
	GetArrayArray(hArray, iIndex, UpgradeToRemove[0], sizeof(UpgradeToRemove));
	RemoveFromArray(hArray, iIndex);

	new iLevel = PlayerData_DecrementUpgradeLevel(this, UpgradeToRemove[_Upgrade], iClass);
	
	if (iLevel == 0)
	{
		return;
	}
	
	for (new i = 0; i < GetArraySize(hArray); i ++)
	{
		decl tmpUpgradeQueue[UpgradeQueue];
		
		GetArrayArray(hArray, i, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
		
		if (StrEqual(UpgradeToRemove[_Upgrade], tmpUpgradeQueue[_Upgrade]))
		{
			if (tmpUpgradeQueue[_iLevel] > UpgradeToRemove[_iLevel])
			{
				tmpUpgradeQueue[_iLevel]--;
			}
			
			SetArrayArray(hArray, i, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
		}
	}
}

//! Shifts an upgrade in the player's queue up.
/*! \param this[] A constructed PlayerData object.
	\param TFClassType:iClass The class whose upgrade queue we'll be dealing with. 
	\param iIndex The index to set the upgrade queue information of.
	\return True if the upgrades were swapped, false if some conditon caused them to stay in the same place.
	\sa PlayerData_PushUpgradeToQueue, PlayerData_GetUpgradeOnQueue, PlayerData_GetUpgradeQueueSize and PlayerData_ResetUpgradeQueue */

/**
 * Shifts an upgrade in the player's queue up.  
 *
 * @param this				A PlayerData object. 
 * @param iClass			The class whose upgrade queue to deal with.
 * @param iIndex			The index of the upgrade to shift up.
 *
 * @error					Invalid object, invalid class or iIndex out of range.
 * @return					True if the upgrade was shifted up, false if it wasn't because it was owned or an upgrade of the same type was above it.
 */
bool:PlayerData_ShiftUpgradeInQueue (this[], TFClassType:iClass, iIndex)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif

	if (iIndex == 0)
	{
		return false;
	}

	new Handle:hArray = PlayerData_ClassIDToUpgradeQueue(this, iClass);

	decl UpgradeToShift[UpgradeQueue];
	decl UpgradeToSwapWith[UpgradeQueue];
	
	GetArrayArray(hArray, iIndex, UpgradeToShift[0], sizeof(UpgradeToShift));
	GetArrayArray(hArray, (iIndex - 1), UpgradeToSwapWith[0], sizeof(UpgradeToSwapWith));

	if (StrEqual(UpgradeToShift[_Upgrade], UpgradeToSwapWith[_Upgrade]))
	{
		return false;
	}
	
	if (UpgradeToSwapWith[_bOwned])
	{
		return false;
	}
	
	SwapArrayItems(hArray, iIndex, (iIndex - 1));
	
	return true;
}

/**
 * Gets the size of the player's upgrade queue.
 *
 * @param this				A PlayerData object. 
 * @param iClass			The class whose upgrade queue to deal with.
 *
 * @error					Invalid object or invalid class.
 * @return					The size of the player's upgrade queue.
 */
PlayerData_GetUpgradeQueueSize (this[], TFClassType:iClass)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	new Handle:hArray = PlayerData_ClassIDToUpgradeQueue(this, iClass);
	return GetArraySize(hArray);
}

/**
 * Resets the upgrade queue of a class.
 *
 * @param this				A PlayerData object. 
 * @param iClass			The class whose upgrade queue to deal with.
 *
 * @error					Invalid object or invalid class.
 * @noreturn
 */
PlayerData_ResetUpgradeQueue (this[], TFClassType:iClass)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif

	new Handle:hArray = PlayerData_ClassIDToUpgradeQueue(this, iClass);
	new Handle:hMap = PlayerData_ClassIDToLevelMap(this, iClass);
	
	ClearArray(hArray);
	ClearTrie(hMap);
}

/**
 * Gets the client's upgrade queue position.
 *
 * @param this				A PlayerData object. 
 *
 * @error					Invalid object.
 * @return					The client's upgrade queue position.
 */
PlayerData_GetQueuePosition (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	return this[m_iQueuePosition];
}

/**
 * Increments the client's upgrade queue position.
 *
 * @param this				A PlayerData object. 
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_IncrementQueuePosition (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	this[m_iQueuePosition] ++;
}

/**
 * Resets the client's upgrade queue position.
 *
 * @param this				A PlayerData object. 
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_ResetQueuePosition (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	this[m_iQueuePosition] = 0;
}

/**
 * Gets the highest level of an upgrade on the client's upgrade queue.
 *
 * @param this				A PlayerData object. 
 * @param Upgrade			The upgrade to get the highest level of.
 * @param iClass			The class whose upgrade queue to deal with.
 *
 * @error					Invalid object or invalid class.
 * @return					The highest level of the upgrade on the queue.
 */
PlayerData_GetUpgradeLevel (this[], const String:Upgrade[], TFClassType:iClass)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif

	new iLevel;

	new Handle:hMap = PlayerData_ClassIDToLevelMap(this, iClass);

	GetTrieValue(hMap, Upgrade, iLevel);

	return iLevel;
}

/**
 * Get the next level of an upgrade to put onto the queue.
 * And also at the same time increase the count in the level maps.
 *
 * @param this				A PlayerData object. 
 * @param Upgrade			The upgrade to set the next level of.
 * @param iClass			The class whose upgrade queue to deal with.
 * @param iMaxLevel			The max level of the upgrade.
 *
 * @error					Invalid class.
 * @return					The next level of the upgrade to put onto the queue or iMaxLevel + 1 if the highest level was already present.
 */
static PlayerData_SetUpgradeNextLevel (this[], const String:Upgrade[], TFClassType:iClass, iMaxLevel)
{
	new Handle:hMap = PlayerData_ClassIDToLevelMap(this, iClass);
	new iNextLevel;
	
	if (! GetTrieValue(hMap, Upgrade, iNextLevel))
	{
		iNextLevel = 1;
	}
	else
	{
		if (iNextLevel != iMaxLevel)
		{
			iNextLevel ++;
		}
		else
		{
			return iMaxLevel + 1;
		}
	}
	
	
	SetTrieValue(hMap, Upgrade, iNextLevel);
	
	return iNextLevel;
}

/**
 * Decrements the highest level of the upgrade in the level maps.
 *
 * @param this				A PlayerData object. 
 * @param Upgrade			The upgrade to decrease the level of.
 * @param iClass			The class whose upgrade queue to deal with.
 *
 * @error					Invalid class.
 * @return					The new highest level of the upgrade on the queue.
 */
static PlayerData_DecrementUpgradeLevel (this[], const String:Upgrade[], TFClassType:iClass)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif

	new iLevel;

	new Handle:hMap = PlayerData_ClassIDToLevelMap(this, iClass);

	if (GetTrieValue(hMap, Upgrade, iLevel))
	{
		iLevel -= 1;

		if (iLevel == 0)
		{
			RemoveFromTrie(hMap, Upgrade);
		}
		else
		{
			SetTrieValue(hMap, Upgrade, iLevel);
		}
	}

	return iLevel;
}

//! A private function used to turn a class ID into the ADT array handle for it's upgrade queue.
/*! \param this[] A constructed PlayerData object.
	\param TFClassType:iClass The class to fetch the array handle of.
	\return The handle of the classes' upgrade queue. */

/**
 * Gets the upgrade queue of a class.
 *
 * @param this				A PlayerData object. 
 * @param iClass			The class whose upgrade queue to fetch.
 *
 * @error					Invalid class.
 * @return					The handle of the class's upgrade queue.
 */
static Handle:PlayerData_ClassIDToUpgradeQueue (this[], TFClassType:iClass)
{
	switch (iClass)
	{
		case TFClass_Scout:
		{
			return this[m_hUpgradeQueueScout];
		}
		case TFClass_Soldier:
		{
			return this[m_hUpgradeQueueSoldier];
		}
		case TFClass_Pyro:
		{
			return this[m_hUpgradeQueuePyro];
		}
		case TFClass_DemoMan:
		{
			return this[m_hUpgradeQueueDemoman];
		}
		case TFClass_Heavy:
		{
			return this[m_hUpgradeQueueHeavy];
		}
		case TFClass_Engineer:
		{
			return this[m_hUpgradeQueueEngineer];
		}
		case TFClass_Medic:
		{
			return this[m_hUpgradeQueueMedic];
		}
		case TFClass_Spy:
		{
			return this[m_hUpgradeQueueSpy];
		}
		case TFClass_Sniper:
		{
			return this[m_hUpgradeQueueSniper];
		}
		default:
		{
			ThrowError("Invalid class index. iClass - %i", iClass);
		}
	}
	
	return INVALID_HANDLE;
}

/**
 * Gets the upgrade queue level map of a class.
 *
 * @param this				A PlayerData object. 
 * @param iClass			The class whose upgrade queue to fetch.
 *
 * @error					Invalid class.
 * @return					The handle of the class's level map.
 */
static Handle:PlayerData_ClassIDToLevelMap (this[], TFClassType:iClass)
{
	switch (iClass)
	{
		case TFClass_Scout:
		{
			return this[m_hNextLevelScout];
		}
		case TFClass_Soldier:
		{
			return this[m_hNextLevelSoldier];
		}
		case TFClass_Pyro:
		{
			return this[m_hNextLevelPyro];
		}
		case TFClass_DemoMan:
		{
			return this[m_hNextLevelDemoman];
		}
		case TFClass_Heavy:
		{
			return this[m_hNextLevelHeavy];
		}
		case TFClass_Engineer:
		{
			return this[m_hNextLevelEngineer];
		}
		case TFClass_Medic:
		{
			return this[m_hNextLevelMedic];
		}
		case TFClass_Spy:
		{
			return this[m_hNextLevelSpy];
		}
		case TFClass_Sniper:
		{
			return this[m_hNextLevelSniper];
		}
		default:
		{
			ThrowError("Invalid class index. iClass - %i", iClass);
		}
	}
	
	return INVALID_HANDLE;
}

/************************Death Counter Functions************************/

/**
 * Increments the client's death counter against another client.
 *
 * @param this				A PlayerData object. 
 * @param iAttacker			The client index of the attacker.
 *
 * @error					Invalid object.
 * @return					The new value of the death counter.
 */
PlayerData_IncrementDeathCounter (this[], iAttacker)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	new iNewValue = GetArrayCell(this[m_hDeathCounter], iAttacker) + 1;
	SetArrayCell(this[m_hDeathCounter], iAttacker, iNewValue);
	
	return iNewValue;
}


/**
 * Resets the client's death counter against another client.
 *
 * @param this				A PlayerData object. 
 * @param iAttacker			The client index of the attacker.
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_ResetDeathCounter (this[], iAttacker)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	SetArrayCell(this[m_hDeathCounter], iAttacker, 0);
}

/**
 * Gets the value of a death counter against another client.
 *
 * @param this				A PlayerData object. 
 * @param iAttacker			The client index of the attacker.
 *
 * @error					Invalid object.
 * @return					The value of the death counter.
 */
PlayerData_GetDeathCounter (this[], iAttacker)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	return GetArrayCell(this[m_hDeathCounter], iAttacker);
}

/************************Credits Setters & Getters************************/

/**
 * Sets the client's credit count.
 *
 * @param this				A PlayerData object. 
 * @param iValue			The value to use with the set operation.
 * @param iOperation		The set operation to take.
 *
 * @error					Invalid object.
 * @return					The new value of the client's credits.
 */
PlayerData_SetCredits (this[], iValue, Set_Operation:iOperation)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	switch (iOperation)
	{
		case SET_ABSOLUTE:
		{
			this[m_iCredits] = iValue;
		}
		case SET_ADD:
		{
			this[m_iCredits] += iValue;
		}
		case SET_SUBTRACT:
		{
			this[m_iCredits] -= iValue;
		}
		case SET_MULTIPLY:
		{
			this[m_iCredits] *= iValue;
		}
		case SET_DIVIDE:
		{
			this[m_iCredits] /= iValue;
		}
		case SET_MODULO:
		{
			this[m_iCredits] %= iValue;
		}
	}
	
	//ThrowError("PlayerData_SetCredits fell through the switch block. This should be impossible. iValue - %i iOperation - %i", iValue, iOperation);
	
	SetHudTextParams(0.2, 0.918, 3600.0, 255, 255, 255, 200);
	if (IsClientInGame(this[m_iClient]))
	{
		ShowSyncHudText(this[m_iClient], this[m_hHUDText], "%t", "Menu_Credits", this[m_iCredits]);
	}

	return this[m_iCredits];
}

/**
 * Gets the client's credit count.
 *
 * @param this				A PlayerData object. 
 *
 * @error					Invalid object.
 * @return					The value of the client's credits.
 */
PlayerData_GetCredits (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	return this[m_iCredits];
}

/**
 * Sets the client's earned credits.
 *
 * @param this				A PlayerData object. 
 * @param iValue			The value to use with the set operation.
 * @param iOperation		The set operation to take.
 *
 * @error					Invalid object.
 * @return					The new value of the client's earned credits.
 */
PlayerData_SetEarnedCredits (this[], iValue, Set_Operation:iOperation)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	switch (iOperation)
	{
		case SET_ABSOLUTE:
		{
			this[m_iCredits] = iValue;
		}
		case SET_ADD:
		{
			this[m_iCredits] += iValue;
		}
		case SET_SUBTRACT:
		{
			this[m_iCredits] -= iValue;
		}
		case SET_MULTIPLY:
		{
			this[m_iCredits] *= iValue;
		}
		case SET_DIVIDE:
		{
			this[m_iCredits] /= iValue;
		}
		case SET_MODULO:
		{
			this[m_iCredits] %= iValue;
		}
	}

	return this[m_iEarnedCredits];
}

/**
 * Gets the client's earned credit count.
 *
 * @param this				A PlayerData object. 
 *
 * @error					Invalid object.
 * @return					The value of the client's earned credits.
 */
PlayerData_GetEarnedCredits (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	return this[m_iEarnedCredits];
}

/**
 * Sets if the client wants objective credits or not.
 *
 * @param this				A PlayerData object. 
 * @param bValue			The value to set it to.
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_SetGiveObjectiveCredits (this[], bool:bValue)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	this[m_bGiveObjectiveCredits] = bValue;
}

/**
 * Gets if the client wants objective credits or not.
 *
 * @param this				A PlayerData object. 
 *
 * @error					Invalid object.
 * @return					True if the client wants objective credits, false if they don't.
 */
bool:PlayerData_GetGiveObjectiveCredits (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	return this[m_bGiveObjectiveCredits];
}


/************************Weapon Functions************************/

/**
 * Updates the object's cached weapon indexes.
 *
 * @param this				A PlayerData object. 
 * @param iSlot				The weapon slot to update.
 * @param iIndex			The item definition index of the new weapon.
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_UpdateWeapon (this[], iSlot, iIndex)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	switch (iSlot)
	{
		case 0:
		{
			if (iIndex != this[m_iWeaponIndex_0])
			{
				this[m_bHaveWeaponsChanged] = true;
				this[m_iWeaponIndex_0] = iIndex;
			}
		}
		case 1:
		{
			if (iIndex != this[m_iWeaponIndex_1])
			{
				this[m_bHaveWeaponsChanged] = true;
				this[m_iWeaponIndex_1] = iIndex;
			}			
		}
		case 2:
		{
			if (iIndex != this[m_iWeaponIndex_2])
			{
				this[m_bHaveWeaponsChanged] = true;
				this[m_iWeaponIndex_2] = iIndex;
			}			
		}
		default:
		{
			ThrowError("Invalid slot passed to function.");
		}
	}
}

/**
 * Checks if a client's weapons have changed since the function was last called.
 *
 * @param this				A PlayerData object.
 *
 * @error					Invalid object.
 * @return					True if they have changed, false if they haven't.
 */
bool:PlayerData_HaveWeaponsChanged (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif

	new bool:bResult;

	if (this[m_bHaveWeaponsChanged])
	{
		bResult = true;
		this[m_bHaveWeaponsChanged] = false;
	}

	return bResult;
}

/**
 * Gets the item definition index of a client's wepaon in a slot.
 *
 * @param this				A PlayerData object.
 * @param iSlot				The slot to get the weapon ID of.
 *
 * @error					Invalid object.
 * @return					The item definition index of the weapon or -1 if PlayerData_UpdateWeapon hasn't been called yet.
 */
PlayerData_GetWeaponID (this[], iSlot)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif

	switch (iSlot)
	{
		case 0:
		{
			return this[m_iWeaponIndex_0];
		}
		case 1:
		{
			return this[m_iWeaponIndex_1];
		}
		case 2:
		{
			return this[m_iWeaponIndex_2];
		}
		default:
		{
			ThrowError("Attempt to get weapon ID from unsupported slot.");
		}
	}
	
	return -1;
}

/************************Misc Utilities************************/

/**
 * Gets the time since the client last started to capture a control point.
 *
 * @param this				A PlayerData object.
 *
 * @error					Invalid object.
 * @return					The time in seconds since the player last started to capture a control point.
 */
PlayerData_GetTimeStartedCapture (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	
	return GetTime() - this[m_iCaptureStartTimer];
}

/**
 * Sets the time when the client started to capture a control point.
 *
 * @param this				A PlayerData object.
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_SetTimeStartedCapture (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	this[m_iCaptureStartTimer] = GetTime();
}

/**
 * Gets if the client has opened the upgrade menu.
 *
 * @param this				A PlayerData object.
 *
 * @error					Invalid object.
 * @return					True if the client has opened the upgrade menu, false if they haven't.
 */
bool:PlayerData_GetHasOpenedMenu (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	
	return this[m_bHasOpenedMenu];
}

/**
 * Sets that the client has opened the upgrade menu.
 *
 * @param this				A PlayerData object.
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_SetHasOpenedMenu (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	this[m_bHasOpenedMenu] = true;
	
	ClearSyncHud(this[m_iClient], this[m_hHUDReminderText]);
}

/**
 * Forces a client's HUD credit counter to be redisplayed to them.
 *
 * @param this				A PlayerData object.
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_ForceHudTextUpdate (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif

	SetHudTextParams(0.2, 0.918, 3600.0, 255, 255, 255, 200);

	if (IsClientInGame(this[m_iClient]))
	{
		ShowSyncHudText(this[m_iClient], this[m_hHUDText], "%t", "Menu_Credits", this[m_iCredits]);
	}
}

/**
 * Displays a reminder to open the upgrade menu to the client.
 *
 * @param this				A PlayerData object.
 *
 * @error					Invalid object.
 * @noreturn
 */
PlayerData_DisplayHudReminder (this[])
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif

	SetHudTextParams(-1.0, -1.0, 60.0, 255, 255, 255, 255);
	if (IsClientInGame(this[m_iClient]))
	{
		ShowSyncHudText(this[m_iClient], this[m_hHUDReminderText], "%t", "Open_Menu_ReminderHud");

	}
}