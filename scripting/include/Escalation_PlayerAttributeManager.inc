#if defined _escalation_playerattributemanager_included
#endinput
#endif
#define _escalation_playerattributemanager_included

#include<tf2attributes>
#include<Escalation_CustomAttributes>
#include<Escalation_Constants>

/**
 * Manages attributes that are applied to the player's entity.
 */ 

static iPlayerAttributes[MAXPLAYERS + 1][ENTITY_MAX_ATTRIBUTES];  /**< Stores the indexes of a player's attributes. */
static Float:fPlayerAttributeValues[MAXPLAYERS + 1][ENTITY_MAX_ATTRIBUTES];/**< Stores the values of a player's attributes. */
static iPlayerAttributeCount[MAXPLAYERS + 1]; /**< Stores how many attributes each player has. */

/**
 * Adds an attribute to the player, this does not add it to the client's entity.
 * You must call PlayerAttributeManager_ApplyAttributes for that.
 *
 * @param iClient				The client to add the attribute to.
 * @param iAttribute			The index of the attribute to add to the client.
 * @param fValue				The value of the attribute to add to the client. 
 *								(Will be merged with any existing attribute of the same index.)
 * @param bIsPercent			Controls the way the attribute is merged with an existing one. 
 *								If false the values will be added together, if true the values will be added together and have 1 subtracted from them.
 *
 * @noreturn
 */
PlayerAttributeManager_AddAttribute	(iClient, iAttribute, Float:fValue, bool:bIsPercent)
{
	if (iAttribute == INVALID_ATTRIBUTE)
	{
		return;
	}

	new bool:bMerged;

	for (new i = 0; i < iPlayerAttributeCount[iClient]; i ++)
	{
		if (iPlayerAttributes[iClient][i] == iAttribute)
		{
			if (bIsPercent)
			{
				fPlayerAttributeValues[iClient][i] += fValue - 1.0;

				bMerged = true;
				break;
			}
			else
			{
				fPlayerAttributeValues[iClient][i] += fValue;

				bMerged = true;
				break;
			}
		}
	}
	
	if (! bMerged)
	{
		iPlayerAttributes[iClient][iPlayerAttributeCount[iClient]] = iAttribute;
		fPlayerAttributeValues[iClient][iPlayerAttributeCount[iClient]] = fValue;
		iPlayerAttributeCount[iClient] ++;
	}
}

/**
 * Clears a client's attributes.
 *
 * @param iClient				The client to clear the attributes of.
 *
 * @noreturn
 */
PlayerAttributeManager_ClearAttributes	(iClient)
{
	for (new i = 0; i < iPlayerAttributeCount[iClient]; i ++)
	{
		if (iPlayerAttributes[iClient][i] > CUSTOM_ATTRIBUTE_OFFSET)
		{
			Esc_RemoveCustomAttribute(iClient, iPlayerAttributes[iClient][i]);
		}
		else
		{
			TF2Attrib_RemoveByDefIndex(iClient, iPlayerAttributes[iClient][i]);
		}
		
		fPlayerAttributeValues[iClient][i] = 0.0;
	}
	
	iPlayerAttributeCount[iClient] = 0;
}

/**
 * Applies a client's attributes to their entity.
 *
 * @param iClient				The client to apply the attributes of.
 *
 * @noreturn
 */
PlayerAttributeManager_ApplyAttributes (iClient)
{
	for (new i = 0; i < iPlayerAttributeCount[iClient]; i ++)
	{
		if (iPlayerAttributes[iClient][i] > CUSTOM_ATTRIBUTE_OFFSET)
		{
			Esc_ApplyCustomAttribute(iClient, iPlayerAttributes[iClient][i], fPlayerAttributeValues[iClient][i], true);
	
			continue;
		}

		TF2Attrib_SetByDefIndex(iClient, iPlayerAttributes[iClient][i], fPlayerAttributeValues[iClient][i]);
	}
	
	TF2Attrib_ClearCache(iClient);
}