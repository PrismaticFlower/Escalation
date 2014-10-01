#if defined _escalation_stocks_included
#endinput
#endif
#define _escalation_stocks_included

#include<SourceMod>

//Define the all class weapon indexes.
#define ALLCLASS_WEAPONS 154,160,199,209,293,357,415,423,474,264,939,954,1013,1071,1101


/**
 * Checks to see if a weapon is an all class weapon.
 *
 * @param iWeaponIndex					The item definition index of the weapon to check.
 *
 * @return								True if the weapon is an all class weapon, false if it isn't.
 */
bool:IsAllClassWeapon(iWeaponIndex)
{	
	switch (iWeaponIndex)
	{
		case ALLCLASS_WEAPONS:
		{
			return true;
		}
	}	
	return false;
}

/**
 * Takes the name of a class and returns the class ID. This function does try to account for common nicknames of classes. 
 *
 * @param Class							The class to get the ID of.
 *
 * @return								The TFClassType of the class.
 */
TFClassType:GetClassID(const String:Class[])
{
	//Giant String Comparision Block!!!!
	if (StrEqual("scout",Class,false))
	{
		return TFClass_Scout;
	}
	else if (StrEqual("sniper",Class,false))
	{
		return TFClass_Sniper;
	}
	else if (StrEqual("soldier",Class,false) || StrEqual("solly",Class,false)) //Account for nickname.
	{
		return TFClass_Soldier;
	}
	else if (StrEqual("demoman",Class,false) || StrEqual("demo",Class,false)) //Also check against the commonly used "demo"
	{
		return TFClass_DemoMan;
	}
	else if (StrEqual("medic",Class,false) || StrEqual("med",Class,false)) //You should be getting how this works by now...
	{
		return TFClass_Medic;
	}
	else if (StrEqual("heavy",Class,false))
	{
		return TFClass_Heavy;
	}
	else if (StrEqual("pyro",Class,false))
	{
		return TFClass_Pyro;
	}
	else if (StrEqual("spy",Class,false))
	{
		return TFClass_Spy;
	}
	else if (StrEqual("engineer",Class,false) || StrEqual("engi",Class,false) || StrEqual("engie",Class,false))
	{
		return TFClass_Engineer;
	}
	else //Invalid class or typo. So sad.
	{
		return TFClass_Unknown; 
	}
}

/**
 * Takes the ID of a class and stores the name of it in the string buffer provided.
 *
 * @param iClass						The ID of the class to get the name of.
 * @param Class							The buffer to store the class name in.
 * @param iStringSize					The max size of Class.
 *
 * @return								The number of cells written to the buffer or -1 on invalid class.
 */
ClassIDToName(TFClassType:iClass, String:Class[], iStringSize)
{
	
	switch(iClass)
	{
		case TFClass_Scout:
		{			
			return strcopy(Class, iStringSize, "scout");
		}
		case TFClass_Sniper:
		{
			return strcopy(Class, iStringSize, "sniper");
		}
		case TFClass_Soldier:
		{
			return strcopy(Class, iStringSize, "soldier");
		}
		case TFClass_DemoMan:
		{
			return strcopy(Class, iStringSize, "demoman");
		}
		case TFClass_Medic:
		{
			return strcopy(Class, iStringSize, "medic");
		}
		case TFClass_Heavy:
		{
			return strcopy(Class, iStringSize, "heavy");
		}
		case TFClass_Pyro:
		{
			return strcopy(Class, iStringSize, "pyro");
		}
		case TFClass_Spy:
		{
			return strcopy(Class, iStringSize, "spy");
		}
		case TFClass_Engineer:
		{
			return strcopy(Class, iStringSize, "engineer");
		}
	}
	
	return -1;
}


/**
 * Finds all the clients on a team and stores them in iClients[].
 *
 * @param iTeam							The team to get the clients of.
 * @param iClients						The array to store the client indexes in.
 * @param iMaxSize						The max size of iClients.
 *
 * @error								Out of space in iClients.
 * @return								The number of clients on the team.
 */
GetClientsOnTeam (iTeam, iClients[], iMaxSize)
{

	new iSize = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (! IsClientConnected(i))
		{
			continue;
		}

		if (GetClientTeam(i) == iTeam)
		{		
			if (iSize == iMaxSize)
			{
				ThrowError("No space left in iClients.");
			}
			
			iClients[iSize] = i;			
			iSize++;
		}
	}

	return iSize;
}

/**
 * Splits a string in two at a sub-string. 
 *
 * @param Source						The source string.
 * @param iSourceSize					The size of the source string.
 * @param Split							The sub-string to split the string at.
 * @param Part							The buffer to store the second half of the string in.
 * @param iPartSize						The size of the buffer to store the second half of the string in. 
 *
 * @return								The location the string was split at or -1 on failure.
 */
SeperateString (String:Source[], iSourceSize, const String:Split[], String:Part[], iPartSize)
{
	new iIndex;

	if ((iIndex = StrContains(Source, Split)) != -1)
	{
		new iPosition;
		
		for (new i = iIndex + 1; i != iSourceSize; i++)
		{
			if (iPosition == iPartSize - 1)
			{
				break;
			}
			
			Part[iPosition] = Source[i];
			
			iPosition ++;
		}
		
		Part[iPosition] = '\0'
		
		if (iIndex < iSourceSize)
		{
			Source[iIndex] = '\0';
		}
		
		
		return iIndex;
	}
	else
	{
		Part[0] = '\0';
	
		return -1;
	}
}

/**
 * Splits a string in two at a sub-string. 
 *
 * @param iClient						The client to get the wearables of.
 * @param iWearables					An array to store the entity indexes of a client's wearables in.
 * @param iSize							The size of the aforementioned array.
 *
 * @return								The count of wearables on the player.
 */
GetClientWearables (iClient, iWearables[], iSize)
{
	new iWearableCount = 0;
	
	new iEntity = -1;
	
	while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable*")) != -1)
	{
	
		new iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		
		if (iOwner == iClient)
		{
			if (iWearableCount < iSize)
			{
				iWearables[iWearableCount] = iEntity;
				
				iWearableCount++;
			}
			else
			{
				return iWearableCount;
			}
		}
	}

	return iWearableCount;
}

#define VPK2_SIGNATURE 1437209140
#define VPK2_VERSION 2
#define VPK2_TREE_TERMINATOR 65535

/**
 * Extracts a file from a VPK2 file. 
 *
 * @param VPK_File						The name of the VPK file, excluding extension.
 * @param File							The name of the file to extract.
 * @param FileToExtractTo				The name of the file to extract the file to.
 *
 * @return								True if the file was extracted, false if it wasn't.
 */
bool:ExtractFileFromVPK2 (const String:VPK_File[], const String:File[], const String:FileToExtractTo[])
{
	new String:DirFileName[PLATFORM_MAX_PATH];
	
	strcopy(DirFileName, sizeof(DirFileName), VPK_File);
	StrCat(DirFileName, sizeof(DirFileName), "_dir.vpk");
	
	new Handle:DirFile = OpenFile(DirFileName, "r");
	
	if (DirFile == INVALID_HANDLE)
	{
		ThrowError("Unable to open VPK directory file \"%s\".", DirFileName);
	}
	
	new iData;
	
	ReadFileCell(DirFile, iData, 4);
	
	if (iData != VPK2_SIGNATURE)
	{
		CloseHandle(DirFile);
	
		ThrowError("Invalid VPK file specified.");
	}
	
	ReadFileCell(DirFile, iData, 4);
	
	if (iData != VPK2_VERSION)
	{
		CloseHandle(DirFile);
	
		ThrowError("VPK has unsupported version.");
	}

	
	//Discard the information from the rest of the struct
	ReadFileCell(DirFile, iData, 4);
	ReadFileCell(DirFile, iData, 4);
	ReadFileCell(DirFile, iData, 4);
	ReadFileCell(DirFile, iData, 4);
	ReadFileCell(DirFile, iData, 4);

	
	//Iterate through the tree information until we find the file requested.
	while (! IsEndOfFile(DirFile))
	{
		new String:FileExt[PLATFORM_MAX_PATH];
		new String:FilePath[PLATFORM_MAX_PATH];
		new String:FileName[PLATFORM_MAX_PATH];

		ReadFileString(DirFile, FileExt, sizeof(FileExt));
		ReadFileString(DirFile, FilePath, sizeof(FilePath));
		ReadFileString(DirFile, FileName, sizeof(FileName));
		
		new iFileCRC;
		new iPreloadBytes;	
		new iArchiveIndex;
		new iEntryOffset;
		new iEntryLength;
		new iTerminator;
		
		ReadFileCell(DirFile, iFileCRC, 4);
		ReadFileCell(DirFile, iPreloadBytes, 2);
		ReadFileCell(DirFile, iArchiveIndex, 2);
		ReadFileCell(DirFile, iEntryOffset, 4);
		ReadFileCell(DirFile, iEntryLength, 4);
		ReadFileCell(DirFile, iTerminator, 2);
		
		if (iTerminator != VPK2_TREE_TERMINATOR)
		{
			CloseHandle(DirFile);
	
			return false;
		}
		
		new String:CompletePath[PLATFORM_MAX_PATH];
		
		Format(CompletePath, sizeof(CompletePath), "%s/%s.%s", FilePath, FileName, FileExt);
		
		if (StrEqual(File, CompletePath))
		{
			CloseHandle(DirFile);
	
			return ExtractFileFromVPK2_Helper(VPK_File, FileToExtractTo, iArchiveIndex, iEntryOffset, iEntryLength);
		}
	}

	CloseHandle(DirFile);
	
	return true;
}

static bool:ExtractFileFromVPK2_Helper (const String:VPK_File[], const String:FileToExtractTo[], iArchiveIndex, iEntryOffset, iEntryLength)
{
	new String:VPKFileName[PLATFORM_MAX_PATH];

	Format(VPKFileName, sizeof(VPKFileName), "%s_%03i.vpk", VPK_File, iArchiveIndex);

	new Handle:VPKFile = OpenFile(VPKFileName, "r");
	new Handle:ExtractedFile = OpenFile(FileToExtractTo, "w");

	for (new i = 0; i < iEntryOffset; i ++)
	{
		new iData;

		ReadFileCell(VPKFile, iData, 1);
	}
	
	for (new i = 0; i < iEntryLength; i ++)
	{
		new iData;
		
		ReadFileCell(VPKFile, iData, 1);
	
		WriteFileCell(ExtractedFile, iData, 1)
	}
	
	FlushFile(ExtractedFile);
	
	CloseHandle(VPKFile);
	CloseHandle(ExtractedFile);

	return true;
}