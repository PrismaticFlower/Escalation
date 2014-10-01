#if defined _escalation_stocks_included
#endinput
#endif
#define _escalation_stocks_included

#include<SourceMod>
#include<tf2attributes>
//#include<Escalation>

//Define the all class weapon indexes.
#define ALLCLASS_WEAPONS 154,160,199,209,293,357,415,423,474,264,939,954,1013,1071,1101

//! Tests if a weapon is a so called special weapon. (ones with the give while active attribute)
/*! \param iWeaponIndex An item definition index.
	\return True on the weapon being an all class weapon, false on it being a normal weapon. */
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

//! Takes the name of a class and returns the class ID. This function does try to account for common nicknames of classes. 
/*! \param String:string[] The class to fetch the ID of.
	\return The ID of the class. */
TFClassType:GetClassID(const String:string[])
{
	//Giant String Comparision Block!!!!
	if (StrEqual("scout",string,false))
	{
		return TFClass_Scout;
	}
	else if (StrEqual("sniper",string,false))
	{
		return TFClass_Sniper;
	}
	else if (StrEqual("soldier",string,false) || StrEqual("solly",string,false)) //Account for nickname.
	{
		return TFClass_Soldier;
	}
	else if (StrEqual("demoman",string,false) || StrEqual("demo",string,false)) //Also check against the commonly used "demo"
	{
		return TFClass_DemoMan;
	}
	else if (StrEqual("medic",string,false) || StrEqual("med",string,false)) //You should be getting how this works by now...
	{
		return TFClass_Medic;
	}
	else if (StrEqual("heavy",string,false))
	{
		return TFClass_Heavy;
	}
	else if (StrEqual("pyro",string,false))
	{
		return TFClass_Pyro;
	}
	else if (StrEqual("spy",string,false))
	{
		return TFClass_Spy;
	}
	else if (StrEqual("engineer",string,false) || StrEqual("engi",string,false) || StrEqual("engie",string,false))
	{
		return TFClass_Engineer;
	}
	else //Invalid class or typo. So sad.
	{
		return TFClass_Unknown; 
	}
}

//! Takes the ID of a class and stores the name of it an the array provided. Returns the result of strcopy or -1 on invalid class.
/*! \param iClass The class to fetch the name of.
	\param String:string[] The string to store the classname in.
	\param iStringSize The max size of the string.
*/
ClassIDToName(TFClassType:iClass, String:string[], iStringSize)
{
	
	switch(iClass)
	{
		case TFClass_Scout:
		{			
			return strcopy(string, iStringSize, "scout");
		}
		case TFClass_Sniper:
		{
			return strcopy(string, iStringSize, "sniper");
		}
		case TFClass_Soldier:
		{
			return strcopy(string, iStringSize, "soldier");
		}
		case TFClass_DemoMan:
		{
			return strcopy(string, iStringSize, "demoman");
		}
		case TFClass_Medic:
		{
			return strcopy(string, iStringSize, "medic");
		}
		case TFClass_Heavy:
		{
			return strcopy(string, iStringSize, "heavy");
		}
		case TFClass_Pyro:
		{
			return strcopy(string, iStringSize, "pyro");
		}
		case TFClass_Spy:
		{
			return strcopy(string, iStringSize, "spy");
		}
		case TFClass_Engineer:
		{
			return strcopy(string, iStringSize, "engineer");
		}
	}
	
	return -1;
}


//! Finds all the clients on a team and stores them in iClients[]. Returns the size of the array or -1 if no clients exsist on the team.
/*! \param iTeam The team to fetch the clients from.
	\param iClients[] An array to store the clients on the team in. Should be the size of MaxClients
*/
GetClientsOnTeam (iTeam, iClients[])
{

	new iSize = -1;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (! IsClientConnected(i))
			continue;
		
		if (GetClientTeam(i) == iTeam)
		{
			iSize++;
			iClients[iSize] = i;
		}
	}

	return iSize;
}

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

GetClientWearables (client, iWearables[], iSize)
{
	new iWearableCount = 0;
	
	new iEntity = -1;
	
	while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable*")) != -1)
	{
	
		new iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		
		if (iOwner == client)
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