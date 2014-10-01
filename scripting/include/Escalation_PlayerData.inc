#if defined _escalation_playerdata_included
#endinput
#endif
#define _escalation_playerdata_included

#include<adt>
#include<Escalation>

//! This one here is a data struct and has no member functions
/*! A data struct used to make up each player's upgrade queue. All the symbols are prefixed with _ so they can still be used in other parts of the code. */ 
enum UpgradeQueue
{
	String:_Upgrade[UPGRADE_NAME_MAXLENGTH], //!< The name of the upgrade.
	_iLevel, //!< The level of the upgrade on the queue.
	bool:_bOwned //!< Is the upgrade owned or not?
};

//! Thie fine object stores all the data the plugin could ever want for each player. (Okay maybe not all the data it could ever want, but still...)
enum PlayerData
{
	m_iObjectType, //!< A variable containing a unique number used to perform checks to ensure an object has been constructed. (Obivously not a robust check, but hopefully enough to catch out most programming mistakes.)
	m_iClient, //!< The index of the client the object was created for.
	
	//Upgrade QueueZ!
	Handle:m_hUpgradeQueueScout, //!< A SourceMod array of upgrade queue structs for Scout.
	Handle:m_hUpgradeQueueSoldier, //!< A SourceMod array of upgrade queue structs for Soldier.
	Handle:m_hUpgradeQueuePyro, //!< A SourceMod array of upgrade queue structs for Pyro.
	Handle:m_hUpgradeQueueDemoman, //!< A SourceMod array of upgrade queue structs for Demoman.
	Handle:m_hUpgradeQueueHeavy, //!< A SourceMod array of upgrade queue structs for Heavy.
	Handle:m_hUpgradeQueueEngineer, //!< A SourceMod array of upgrade queue structs for Engineer.
	Handle:m_hUpgradeQueueMedic, //!< A SourceMod array of upgrade queue structs for Medic.
	Handle:m_hUpgradeQueueSpy, //!< A SourceMod array of upgrade queue structs for Spy.
	Handle:m_hUpgradeQueueSniper, //!< A SourceMod array of upgrade queue structs for Sniper.
	
	//Highest upgrade level on Queue hash maps! 
	Handle:m_hNextLevelScout, //!< A SourceMod trie storing the current level of an upgrade on the queue for Scout.
	Handle:m_hNextLevelSoldier, //!< A SourceMod trie storing the current level of an upgrade on the queue for Soldier.
	Handle:m_hNextLevelPyro, //!< A SourceMod trie storing the current level of an upgrade on the queue for Pyro.
	Handle:m_hNextLevelDemoman, //!< A SourceMod trie storing the current level of an upgrade on the queue for Demoman.
	Handle:m_hNextLevelHeavy, //!< A SourceMod trie storing the current level of an upgrade on the queue for Heavy.
	Handle:m_hNextLevelEngineer, //!< A SourceMod trie storing the current level of an upgrade on the queue for Engineer.
	Handle:m_hNextLevelMedic, //!< A SourceMod trie storing the current level of an upgrade on the queue for Medic.
	Handle:m_hNextLevelSpy, //!< A SourceMod trie storing the current level of an upgrade on the queue for Spy.
	Handle:m_hNextLevelSniper,  //!< A SourceMod trie storing the current level of an upgrade on the queue for Sniper.
	
	m_iQueuePosition, //!< A variable that can be used to keep track of where a client's upgrade queue has been processed up to.
	
	m_iWeaponIndex_0, //!< The item definition index of the player's primary weapon.
	m_iWeaponIndex_1, //!< The item definition index of the player's secondary weapon.
	m_iWeaponIndex_2, //!< The ite- You're not really going to make me say it are you?

	bool:m_bHaveWeaponsChanged, //!< Keeps track of if the client's weapons have changed.
	
	Handle:m_hDeathCounter, //!< A SourceMod array used to track the amount of times the player has died to another player.
	m_iCredits, //!< How many credits does the player have? I don't know, you don't know. This variable however does know.
	m_iEarnedCredits, //!< Stores how many credits the client has personally earned. (Non-team objective ones.)
	bool:m_bGiveObjectiveCredits, //!< Does the client want objective credits given to them when they join a team?
	
	m_iCaptureStartTimer, //!< A timer for tracking when we last started capturing a control point.
	
	bool:m_bHasOpenedMenu, //!< Has the client opened the upgrade menu at least once?
	
	Handle:m_hHUDText, //!< A HUD text synchronizer object for displaying the client's credits count.
	Handle:m_hHUDReminderText //!< A HUD text synchronizer object for reminding the client to open the upgrade menu.
};

static const PlayerDataID = (4 << _:PlayerData);

//! Constructs a PlayerData object in the array provided. 
/*! \param this[] An array that has been created with PlayerData as the size.
	\param iClient The index of the client the object was created for.
	\sa PlayerData_Destroy */
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

//! Destroys a PlayerData object so it can go out of scope. 
/*! \param this[] A constructed PlayerData object.
	\sa PlayerData_Construct */
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

//! A private function that closes all of a PlayerData object's handles. 
/*! \param this[] A constructed PlayerData object.
	\sa PlayerData_Destroy */
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

//! Pushes an upgrade onto a player's upgrade queue.
/*! \param this[] A constructed PlayerData object.
	\param TFClassType:iClass The class whose upgrade queue we'll be dealing with.
	\param const String:Upgrade[] The upgrade to push onto the queue.
	\param iMaxLevel The max level of the upgrade being pushed onto the queue.
	\param &iNextLevel A reference to a variable to store the level of the upgrade pushed onto the queue.
	\return Returns true if the upgrade was added to the queue successfully or false if an instance of the upgrade was already on the queue at iMaxLevel.
	\sa PlayerData_GetUpgradeOnQueue, PlayerData_SetUpgradeOnQueue, PlayerData_GetUpgradeQueueSize and PlayerData_ResetUpgradeQueue */
bool:PlayerData_PushUpgradeToQueue (this[], TFClassType:iClass, const String:Upgrade[], iMaxLevel, &iNextLevel)
{
	#if defined USE_OBJECT_SAFETY_CHECK
		if (this[PlayerData:m_iObjectType] != PlayerDataID)
		{
			ThrowError("Invalid object passed to function. A valid, constructed object is expected.");
		}
	#endif
	
	decl tmpUpgradeQueue[UpgradeQueue];
	new Handle:hArray = PlayerData_ClassIDToUpgradeQueue(this, iClass);
	iNextLevel = PlayerData_SetUpgradeNextLevel(this, Upgrade, iClass, iMaxLevel);
	
	strcopy(tmpUpgradeQueue[_Upgrade], sizeof(tmpUpgradeQueue[_Upgrade]), Upgrade)
	tmpUpgradeQueue[_iLevel] = iNextLevel;
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

//! Retrieves an upgrade from the player's queue.
/*! \param this[] A constructed PlayerData object.
	\param TFClassType:iClass The class whose upgrade queue we'll be dealing with.
	\param iIndex The index to fetch the upgrade queue information from.
	\param upgradequeue[] An UpgardeQueue struct to store the upgrade information in.
	\sa PlayerData_PushUpgradeToQueue, PlayerData_SetUpgradeOnQueue, PlayerData_GetUpgradeQueueSize and PlayerData_ResetUpgradeQueue */
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

//! Sets an upgrade on the player's queue.
/*! \param this[] A constructed PlayerData object.
	\param TFClassType:iClass The class whose upgrade queue we'll be dealing with. 
	\param iIndex The index to set the upgrade queue information of.
	\param const upgradequeue[] An UpgardeQueue struct that has the upgrade queue information in.
	\sa PlayerData_PushUpgradeToQueue, PlayerData_GetUpgradeOnQueue, PlayerData_GetUpgradeQueueSize and PlayerData_ResetUpgradeQueue */
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

//! Removes an upgrade from the player's queue.
/*! \param this[] A constructed PlayerData object.
	\param TFClassType:iClass The class whose upgrade queue we'll be dealing with. 
	\param iIndex The index to set the upgrade queue information of.
	\sa PlayerData_PushUpgradeToQueue, PlayerData_GetUpgradeOnQueue, PlayerData_GetUpgradeQueueSize and PlayerData_ResetUpgradeQueue */
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

//! Gets the size of the player's queue.
/*! \param this[] A constructed PlayerData object.
	\param iClass The class whose upgrade queue to get the size of.
	\return The size of the upgrade queue.
	\sa PlayerData_PushUpgradeToQueue, PlayerData_GetUpgradeOnQueue, PlayerData_SetUpgradeOnQueue and PlayerData_ResetUpgradeQueue */
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

//! Resets the upgrade queue of a class.
/*! \param this[] A constructed PlayerData object.
	\param iClass The class whose upgrade queue to reset.
	\sa PlayerData_PushUpgradeToQueue, PlayerData_GetUpgradeOnQueue, PlayerData_SetUpgradeOnQueue and PlayerData_GetUpgradeQueueSize */
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

//! Gets the upgrade queue position.
/*! \param this[] A constructed PlayerData object.
	\return The upgrade queue position.
	\sa PlayerData_IncrementQueuePosition and PlayerData_ResetQueuePosition */
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

//! Increments the upgrade queue position.
/*! \param this[] A constructed PlayerData object.
	\sa PlayerData_GetQueuePosition and PlayerData_ResetQueuePosition */
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

//! Resets the upgrade queue position.
/*! \param this[] A constructed PlayerData object.
	\sa PlayerData_GetQueuePosition and PlayerData_IncrementQueuePosition */
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

//! A function used to get the level of an upgrade to on the queue.
/*! \param this[] A constructed PlayerData object.
	\param const String:Upgrade[] The upgrade to get the level of.
	\param TFClassType:iClass The class to get the upgrade level of.
	\return The highest level of the upgrade on the queue. */
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

//! A private function used to get the next level of an upgrade to put onto the queue and at the same time increase the count in the level maps.
/*! \param this[] A constructed PlayerData object.
	\param const String:Upgrade[] The upgrade to get the next level of.
	\param TFClassType:iClass The class to set the next upgrade level of.
	\param iMaxLevel The max level.
	\return The next level of the upgrade to put onto the queue or iMaxLevel + 1 if the highest level is already present. */
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

//! A function used to get the level of an upgrade to on the queue.
/*! \param this[] A constructed PlayerData object.
	\param const String:Upgrade[] The upgrade to decrease the level of.
	\param TFClassType:iClass The class to decrease the level of.
	\return The new highest level of the upgrade on the queue. */
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

//! A private function used to turn a class ID into the ADT trie handle for it's level tracker, thing.
/*! \param this[] A constructed PlayerData object.
	\param TFClassType:iClass The class to fetch the array handle of.
	\return The handle of the classes' level trie, thing. */
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

//! Increments the death counter of the player for the specified attacker.
/*! \param this[] A constructed PlayerData object.
	\param iAttacker The client of whoever killed this poor player.
	\return The new value of the death counter. */
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

//! Resets the death counter of the player for the specified attacker.
/*! \param this[] A constructed PlayerData object.
	\param iAttacker The client to reset the amount of times they've killed the player. */
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

//! Feteches the death counter of the player for the specified attacker.
/*! \param this[] A constructed PlayerData object.
	\param iAttacker The client to get the amount of times they've killed the player.
	\return The value of the death counter. */
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

//! Sets the client's credits based off a Set_Operation defined in Escalation.inc.
/*! \param this[] A constructed PlayerData object.
	\param iValue The value to use in the Set_Operation.
	\param Set_Operation:iOperation The operation to do on the variable.
	\return The new value of the client's credits. */
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

//! Gets the client's credits.
/*! \param this[] A constructed PlayerData object.
	\return The value of the client's credits. */
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

//! Sets the client's earned credits based off a Set_Operation defined in Escalation.inc.
/*! \param this[] A constructed PlayerData object.
	\param iValue The value to use in the Set_Operation.
	\param Set_Operation:iOperation The operation to do on the variable.
	\return The new value of the client's credits. */
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

//! Gets the client's earned credits.
/*! \param this[] A constructed PlayerData object.
	\return The value of the client's earned credits. */
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

//! Sets if the client wants objective credits.
/*! \param this[] A constructed PlayerData object.
	\param bValue The value to set it to.
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
//! Gets if the client wants objective credits.
/*! \param this[] A constructed PlayerData object.
	\return True if the client wants objective credits, false if they don't.
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

//! Updates the object's entity references to the player's weapon.
/*! \param this[] A constructed PlayerData object.
	\param iSlot The weapon slot to update.
	\param iEntity The entity of the weapon being cached.
	\param iIndex The item definition index of the weapon in the slot.*/
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

//! Checks if a client's weapons have changed.
/*! \param this[] A constructed PlayerData object.
	\return True if the client's weapons have changed since the function was last called. */
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

//! Gets the item definition index of a client's weapon in iSlot.
/*! \param this[] A constructed PlayerData object.
	\param iSlot The weapon slot to get the item definition index of.
	\return The item definition index of the weapon or -1 if a call to PlayerData_HaveWeaponsChanged has yet to be made */
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

//! Gets the time since the client last started to capture a control point.
/*! \param this[] A constructed PlayerData object.
	\return The time in seconds since the player last started to capture a control point. */
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

//! Sets the time since the client last started to capture a control point.
/*! \param this[] A constructed PlayerData object. */
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

//! Returns the value of m_bHasOpenedMenu.
/*! \param this[] A constructed PlayerData object.
	\return The time in seconds since the player last started to capture a control point. */
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

//! Sets m_bHasOpenedMenu to true.
/*! \param this[] A constructed PlayerData object. */
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

//! Forces a player's credits counter to be redisplayed to them.
/*! \param this[] A constructed PlayerData object. */
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

//! Displays a reminder to open the upgrade menu to the client.
/*! \param this[] A constructed PlayerData object. */
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