#if defined _escalation_playerattributemanager_included
#endinput
#endif
#define _escalation_playerattributemanager_included

#include<tf2attributes>
#include<Escalation_CustomAttributes>

static iPlayerAttributes[MAXPLAYERS + 1][16];
static Float:fPlayerAttributeValues[MAXPLAYERS + 1][16];
static iPlayerAttributeCount[MAXPLAYERS + 1];

//An add function.
PlayerAttributeManager_AddAttribute	(client, iAttribute, Float:fValue, bool:bIsPercent)
{
	if (iAttribute == INVALID_ATTRIBUTE)
	{
		return;
	}

	new bool:bMerged;

	for (new i = 0; i < iPlayerAttributeCount[client]; i ++)
	{
		if (iPlayerAttributes[client][i] == iAttribute)
		{
			if (bIsPercent)
			{
				fPlayerAttributeValues[client][i] += fValue - 1.0;

				bMerged = true;
				break;
			}
			else
			{
				fPlayerAttributeValues[client][i] += fValue;

				bMerged = true;
				break;
			}
		}
	}
	
	if (! bMerged)
	{
		iPlayerAttributes[client][iPlayerAttributeCount[client]] = iAttribute;
		fPlayerAttributeValues[client][iPlayerAttributeCount[client]] = fValue;
		iPlayerAttributeCount[client] ++;
	}
}

//A clear function.
PlayerAttributeManager_ClearAttributes	(client)
{
	for (new i = 0; i < iPlayerAttributeCount[client]; i ++)
	{
		if (iPlayerAttributes[client][i] > CUSTOM_ATTRIBUTE_OFFSET)
		{
			Esc_RemoveCustomAttribute(client, iPlayerAttributes[client][i]);
		}
		else
		{
			TF2Attrib_RemoveByDefIndex(client, iPlayerAttributes[client][i]);
		}
		
		fPlayerAttributeValues[client][i] = 0.0;
	}
	
	iPlayerAttributeCount[client] = 0;
}

//A apply to player function.
PlayerAttributeManager_ApplyAttributes (client)
{
	for (new i = 0; i < iPlayerAttributeCount[client]; i ++)
	{
		if (iPlayerAttributes[client][i] > CUSTOM_ATTRIBUTE_OFFSET)
		{
			Esc_ApplyCustomAttribute(client, iPlayerAttributes[client][i], fPlayerAttributeValues[client][i], true);
	
			continue;
		}

		TF2Attrib_SetByDefIndex(client, iPlayerAttributes[client][i], fPlayerAttributeValues[client][i]);
	}
	
	TF2Attrib_ClearCache(client);
}