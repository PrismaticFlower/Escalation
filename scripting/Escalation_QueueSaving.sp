#include<Escalation>
#include<Escalation_Stocks>

#include<SourceMod>

#define AUTHID_SIZE 64
#define QUERY_SIZE 16392 //7 byte per upgrade * 256 * 9 classes + 64 for the SteamID + 200 for the query commands


public Plugin:myinfo =
{
	name = "Escalation Upgrade Queue Saving",
	author = "SleepKiller",
	description = "Enables the saving of a client's upgrade queue when they're disconnected, optionally saving it to an SQL database.",
	version = "1.0.0",
	url = ""
};

static bool:g_bClientAuthed[MAXPLAYERS + 1];
static bool:g_bClientDataReady[MAXPLAYERS + 1];
static bool:g_bClientHadSQLData[MAXPLAYERS + 1];

static String:g_AuthIDs[MAXPLAYERS + 1][AUTHID_SIZE];

static Handle:g_hQueueCache = INVALID_HANDLE;
static Handle:g_hUpgradeNames = INVALID_HANDLE;

static Handle:g_hDatabase = INVALID_HANDLE;

static Handle:g_hCVAR_UseSQL = INVALID_HANDLE;
static bool:g_bUseSQL;

static String:g_QueryBuffer[QUERY_SIZE];

public OnPluginStart ()
{
	g_hQueueCache = CreateTrie();

	g_hCVAR_UseSQL = CreateConVar("escalation_queuesaving_usesql", "1", "Set to 1 if you're a fan of using SQL to save your clients upgrade queues. Set to 0 if you don't like SQL or can't use it.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "Escalation_QueueSaving_Config");
	
	g_bUseSQL = GetConVarBool(g_hCVAR_UseSQL);

	if (g_bUseSQL)
	{
		decl String:Error[256];
		g_hDatabase = SQL_DefConnect(Error, sizeof(Error));

		if (g_hDatabase == INVALID_HANDLE)
		{
			LogError("Database Error: %s", Error);
			LogError("Attempting to fallback on SQLite.");

			g_hDatabase = SQLite_UseDatabase("sourcemod-local", Error, sizeof(Error));
			
			if (g_hDatabase == INVALID_HANDLE)
			{
				LogError("SQLite Database Error: %s", Error);
				g_bUseSQL = false;	
			}
		}
	
		if (g_bUseSQL)
		{
			decl String:Driver[32];

			SQL_ReadDriver(g_hDatabase, Driver, sizeof(Driver));
		
			if (! SQL_FastQuery(g_hDatabase, "CREATE TABLE IF NOT EXISTS Escalation_UpgradeQueues (SteamID varchar[64],Scout_Queue varchar[1792],Sniper_Queue varchar[1792],Soldier_Queue varchar[1792],DemoMan_Queue varchar[1792],Medic_Queue varchar[1792],Heavy_Queue varchar[1792],Pyro_Queue varchar[1792],Spy_Queue varchar[1792],Engineer_Queue varchar[1792]);"))
			{
				SQL_GetError(g_hDatabase, Error, sizeof(Error));

				LogError("Database Error: %s", Error);
			}
		}
	}

	if (Esc_IsPluginActive())
	{
		Esc_CoreConfigsLoaded();
	}
}

/************************CLIENT FUNCTIONS************************/

public OnClientAuthorized (iClient, const String:Auth[])
{
	g_bClientAuthed[iClient] = true;
	
	GetClientAuthId(iClient, AuthId_Steam3, g_AuthIDs[iClient], AUTHID_SIZE);
	
	if (g_bClientDataReady[iClient])
	{
		if (g_bUseSQL)
		{
			FetchClientSQLQueues(iClient);
		}

		RestoreCachedQueues(iClient);
	}
}

public Esc_PlayerDataCreated (iClient)
{
	g_bClientDataReady[iClient] = true;

	if (g_bClientAuthed[iClient])
	{
		if (g_bUseSQL)
		{
			FetchClientSQLQueues(iClient);
		}

		RestoreCachedQueues(iClient);
	}
}

public Esc_PlayerDataDestroy (iClient)
{
	if (! g_bClientAuthed[iClient])
	{
		return;
	}

	CacheQueues(iClient)
	
	if (g_bUseSQL)
	{
		SaveClientQueuesToSQL(iClient);
		
		ClearCachedQueues(iClient);
	}
	
	g_bClientDataReady[iClient] = false;
	g_bClientHadSQLData[iClient] = false;
}

public OnClientDisconnect_Post (iClient)
{
	g_bClientAuthed[iClient] = false;

	g_AuthIDs[iClient][0] = '\0';
}

CacheQueues (iClient)
{
	SetTrieValue(g_hQueueCache, g_AuthIDs[iClient], true);

	for (new TFClassType:iClass = TFClassType:1; iClass <= TFClassType:9; iClass ++)
	{
		decl String:Class[32];
		ClassIDToName(iClass, Class, sizeof(Class));
	
		decl String:QueueIndex[32 + AUTHID_SIZE];
		strcopy(QueueIndex, sizeof(QueueIndex), g_AuthIDs[iClient]);
		StrCat(QueueIndex, sizeof(QueueIndex), Class);

		new iQueueSize = Esc_GetUpgradeQueueSize(iClient, iClass);

		new Handle:hArray = INVALID_HANDLE;
		
		if (! GetTrieValue(g_hQueueCache, QueueIndex, hArray))
		{
			hArray = CreateArray(UPGRADE_NAME_MAXLENGTH / 4, iQueueSize);
		}
		else if (iQueueSize == 0)
		{
			return;
		}
		else
		{
			ResizeArray(hArray, iQueueSize);
		}
		
		for (new iIndex = 0; iIndex < iQueueSize; iIndex ++)
		{
			decl tmpUpgradeQueue[UpgradeQueue];
		
			Esc_GetUpgradeFromQueue(iClient, iIndex, iClass, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
			
			SetArrayString(hArray, iIndex, tmpUpgradeQueue[_Upgrade]);
		}

		SetTrieValue(g_hQueueCache, QueueIndex, hArray);
	}
}

ClearCachedQueues (iClient)
{
	new bool:bHasCachedQueues;

	if (! GetTrieValue(g_hQueueCache, g_AuthIDs[iClient], bHasCachedQueues))
	{
		return;
	}

	for (new TFClassType:iClass = TFClassType:1; iClass <= TFClassType:9; iClass ++)
	{
		Esc_ClearUpgradeQueue(iClient, iClass, false);
	
		decl String:Class[32];
		ClassIDToName(iClass, Class, sizeof(Class));
	
		decl String:QueueIndex[32 + AUTHID_SIZE];
		strcopy(QueueIndex, sizeof(QueueIndex), g_AuthIDs[iClient]);
		StrCat(QueueIndex, sizeof(QueueIndex), Class);	
		
		new Handle:hArray = INVALID_HANDLE;
		
		if (! GetTrieValue(g_hQueueCache, QueueIndex, hArray))
		{
			ThrowError("Attempt to fetch non-existent cached queue.")
		}
		
		CloseHandle(hArray);
		
		RemoveFromTrie(g_hQueueCache, QueueIndex);
	}
	
	RemoveFromTrie(g_hQueueCache, g_AuthIDs[iClient]);
}

RestoreCachedQueues (iClient)
{
	new bool:bHasCachedQueues;

	if (! GetTrieValue(g_hQueueCache, g_AuthIDs[iClient], bHasCachedQueues))
	{
		return;
	}

	for (new TFClassType:iClass = TFClassType:1; iClass <= TFClassType:9; iClass ++)
	{
		Esc_ClearUpgradeQueue(iClient, iClass, false);
	
		decl String:Class[32];
		ClassIDToName(iClass, Class, sizeof(Class));
	
		decl String:QueueIndex[32 + AUTHID_SIZE];
		strcopy(QueueIndex, sizeof(QueueIndex), g_AuthIDs[iClient]);
		StrCat(QueueIndex, sizeof(QueueIndex), Class);	
		
		new Handle:hArray = INVALID_HANDLE;
		
		if (! GetTrieValue(g_hQueueCache, QueueIndex, hArray))
		{
			ThrowError("Attempt to fetch non-existent cached queue.")
		}

		new iQueueSize = GetArraySize(hArray);

		for (new iIndex = 0; iIndex < iQueueSize; iIndex ++)
		{
			decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];
	
			GetArrayString(hArray, iIndex, Upgrade, sizeof(Upgrade));
			
			Esc_PushUpgradeOntoQueue(iClient, Upgrade, iClass, false, true);
		}
	}
}

/************************SQL FUNCTIONS************************/

FetchClientSQLQueues(iClient)
{
	if (! g_bUseSQL)
	{
		ThrowError("Attempt to fetch an client's queue from a database when SQL is disabled.");
	}
	
	g_QueryBuffer[0] = '\0';

	FormatEx(g_QueryBuffer, sizeof(g_QueryBuffer), "SELECT * FROM Escalation_UpgradeQueues WHERE SteamID = '%s';", g_AuthIDs[iClient]);
	
	SQL_TQuery(g_hDatabase, Callback_FetchQueue, g_QueryBuffer, GetClientUserId(iClient));

	g_QueryBuffer[0] = '\0';
}

SaveClientQueuesToSQL(iClient)
{
	decl String:QueueStrings[9][1792];
	
	for (new i = 0; i < 9; i ++)
	{
		QueueStrings[i][0] = '\0';
	}
	
	for (new TFClassType:iClass = TFClassType:1; iClass <= TFClassType:9; iClass ++)
	{
		decl String:Class[32];
		ClassIDToName(iClass, Class, sizeof(Class));
	
		decl String:QueueIndex[32 + AUTHID_SIZE];
		strcopy(QueueIndex, sizeof(QueueIndex), g_AuthIDs[iClient]);
		StrCat(QueueIndex, sizeof(QueueIndex), Class);

		new Handle:hArray = INVALID_HANDLE;
		
		if (! GetTrieValue(g_hQueueCache, QueueIndex, hArray))
		{
			ThrowError("SaveClientQueuesToSQL called before CacheQueues. No upgrade queues to save.")
		}
		
		new iQueueSize = GetArraySize(hArray);
		
		decl String:QueueBase36[iQueueSize + 1][7];
		
		for (new iIndex = 0; iIndex < iQueueSize; iIndex ++)
		{
			QueueBase36[iIndex][0] = '\0';
		
			decl String:Upgrade[UPGRADE_NAME_MAXLENGTH]
			GetArrayString(hArray, iIndex, Upgrade, sizeof(Upgrade));
			
			new iHashValue = FNV1a_Hash31(Upgrade);

			Base36_Encode(iHashValue, QueueBase36[iIndex], 7);			
		}
		
		ImplodeStrings(QueueBase36, iQueueSize, ",", QueueStrings[iClass - TFClassType:1], 1792);
	}

	
	g_QueryBuffer[0] = '\0';

	if (! g_bClientHadSQLData[iClient])
	{
		FormatEx(g_QueryBuffer, sizeof(g_QueryBuffer), "INSERT INTO Escalation_UpgradeQueues (SteamID, scout_queue, sniper_queue, soldier_queue, demoman_queue, medic_queue, heavy_queue, pyro_queue, spy_queue, engineer_queue) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s');",
		g_AuthIDs[iClient],
		QueueStrings[0],
		QueueStrings[1],
		QueueStrings[2],
		QueueStrings[3],
		QueueStrings[4],
		QueueStrings[5],
		QueueStrings[6],
		QueueStrings[7],
		QueueStrings[8]);
	}
	else
	{
		FormatEx(g_QueryBuffer, sizeof(g_QueryBuffer), "UPDATE Escalation_UpgradeQueues SET scout_queue='%s',sniper_queue='%s',soldier_queue='%s',demoman_queue='%s',medic_queue='%s',heavy_queue='%s',pyro_queue='%s',spy_queue='%s',engineer_queue='%s' WHERE SteamID = '%s';",
		QueueStrings[0],
		QueueStrings[1],
		QueueStrings[2],
		QueueStrings[3],
		QueueStrings[4],
		QueueStrings[5],
		QueueStrings[6],
		QueueStrings[7],
		QueueStrings[8],
		g_AuthIDs[iClient]);
	}
	
	SQL_TQuery(g_hDatabase, Callback_StoreQueue, g_QueryBuffer, 0);
	
	g_QueryBuffer[0] = '\0';
}


public Callback_FetchQueue(Handle:hOwner, Handle:Hndl, const String:Error[], any:aData)
{
	new iClient = GetClientOfUserId(aData);

	if (Hndl == INVALID_HANDLE)
	{
		LogError("Query Failed! %s", Error);
	}
	
	if (! SQL_FetchRow(Hndl))
	{
		g_bClientHadSQLData[iClient] = false;
		
		return;
	}

	g_bClientHadSQLData[iClient] = true;
	
	SetTrieValue(g_hQueueCache, g_AuthIDs[iClient], true);
	
	for (new TFClassType:iClass = TFClassType:1; iClass <= TFClassType:9; iClass ++)
	{
		decl String:Class[32];
		ClassIDToName(iClass, Class, sizeof(Class));
	
		decl String:QueueIndex[32 + AUTHID_SIZE];
		strcopy(QueueIndex, sizeof(QueueIndex), g_AuthIDs[iClient]);
		StrCat(QueueIndex, sizeof(QueueIndex), Class);

		new Handle:hArray = INVALID_HANDLE;

		if (! GetTrieValue(g_hQueueCache, QueueIndex, hArray))
		{
			hArray = CreateArray(UPGRADE_NAME_MAXLENGTH / 4);
		}

		decl String:QueueString[1792];
		
		SQL_FetchString(Hndl, _:iClass, QueueString, sizeof(QueueString));
		
		ProcessSQLQueueString(QueueString, hArray);

		SetTrieValue(g_hQueueCache, QueueIndex, hArray);
	}
	
	RestoreCachedQueues(iClient);
}

public Callback_StoreQueue(Handle:hOwner, Handle:Hndl, const String:Error[], any:aData)
{
	if (Hndl == INVALID_HANDLE)
	{
		LogError("Query Failed! %s", Error);
	}
}

/************************OTHER STUFF FUNCTIONS************************/

public Esc_CoreConfigsLoaded ()
{
	CheckUpgradeNamesMap();

	new Handle:hArray = Esc_GetArrayOfUpgrades();

	for (new i = 0; i < GetArraySize(hArray); i ++)
	{
		decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];
		GetArrayString(hArray, i, Upgrade, sizeof(Upgrade));

		new iHashValue = FNV1a_Hash31(Upgrade);

		decl String:Base36Val[7];
		Base36_Encode(iHashValue, Base36Val, sizeof(Base36Val));

		SetTrieString(g_hUpgradeNames, Base36Val, Upgrade);
	}
}

CheckUpgradeNamesMap ()
{
	if (g_hUpgradeNames != INVALID_HANDLE)
	{
		CloseHandle(g_hUpgradeNames);
	}

	g_hUpgradeNames = CreateTrie();
}

ProcessSQLQueueString (const String:Queue[], Handle:hArray)
{
	if (Queue[0] == '\0')
	{
		return;
	}
	
	ClearArray(hArray);
	
	new iIndex = -1;

	decl String:Base36Val[7];
	Base36Val[0] = '\0';

	new iOffset = 0;

	do
	{
		iIndex ++;

		if (Queue[iIndex] == ',' || Queue[iIndex] == '\0')
		{
			decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];
			Upgrade[0] = '\0';

			Base36Val[iOffset] = '\0';

			GetTrieString(g_hUpgradeNames, Base36Val, Upgrade, sizeof(Upgrade));
			
			PushArrayString(hArray, Upgrade);

			Base36Val[0] = '\0';

			iOffset = 0;
		}
		else
		{
			Base36Val[iOffset] = Queue[iIndex];
			
			iOffset ++;
		}

	} while (Queue[iIndex] != '\0')

}

/************************UTILITY FUNCTIONS************************/

Base36_Encode (iValue, String:Base36Val[], iSize)
{
	if (iValue > 2147483647 || iValue < 1)
	{
		ThrowError("iValue (%i) is out of supported range.", iValue);
	}

	static const String:Base36[37] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	new String:Buffer[7];

	new iOffset = 0;

	do
	{
		Buffer[iOffset] = Base36[iValue % 36];

		iOffset ++;

	} while (iValue /= 36);
	
	Buffer[iOffset] = '\0';
	
	return strcopy(Base36Val, iSize, Buffer);
}

//http://www.isthe.com/chongo/tech/comp/fnv/
FNV1a_Hash32 (const String:Buffer[])
{
	static const OFFSET_BASIS = 2166136261;
	static const FNV_PRIME = 16777619;
	
	new iHash = OFFSET_BASIS;
	
	for (new i; Buffer[i] != '\0'; i++)
	{
		iHash ^= Buffer[i];
		iHash *= FNV_PRIME;
	}
	
	return iHash;
}

FNV1a_Hash31 (const String:Buffer[])
{	
	new iHash = FNV1a_Hash32(Buffer);

	if (iHash < 0)
	{
		iHash *= -1;
	}

	return iHash;
}