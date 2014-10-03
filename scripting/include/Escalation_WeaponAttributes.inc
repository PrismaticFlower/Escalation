#if defined _escalation_weaponattributes_included
#endinput
#endif
#define _escalation_weaponattributes_included

#include<Escalation_Constants>
#include<Escalation_CustomAttributes>
#include<tf2attributes>
#include<sdktools>

/**
 * Manages attributes that are applied to the player's weapons.
 */ 

static iWeaponAttributes[MAXPLAYERS + 1][UPGRADABLE_SLOTS][ENTITY_MAX_ATTRIBUTES]; /**< Stores the indexes of each weapon's attributes. */
static Float:fWeaponAttributeValues[MAXPLAYERS + 1][UPGRADABLE_SLOTS][ENTITY_MAX_ATTRIBUTES]; /**< Stores the values of each weapon's attributes. */
static iWeaponAttributeCount[MAXPLAYERS + 1][UPGRADABLE_SLOTS]; /**< Stores how many attributes each weapon has. */
static iWeaponEntRefs[MAXPLAYERS + 1][UPGRADABLE_SLOTS]; /**< Stores entity references to a player's weapons. */

/**
 * Adds an attribute to a player's weapon, this does not add it to the client's entity.
 * You must call WeaponAttributes_Apply for that.
 *
 * @param iClient				The client to add the attribute to.
 * @param iSlot					The weapon in this slot will have the attribute added.
 * @param iAttribute			The index of the attribute to add to the weapon.
 * @param fValue				The value of the attribute to add to the weapon. 
 *								(Will be merged with any existing attribute of the same index.)
 * @param bIsPercent			Controls the way the attribute is merged with an existing one. 
 *								If false the values will be added together, if true the values will be added together and have 1 subtracted from them.
 *
 * @noreturn
 */
WeaponAttributes_Add (iClient, iSlot, iAttribute, Float:fValue, bool:bIsPercent)
{
	if (iAttribute == INVALID_ATTRIBUTE)
	{
		return;
	}

	new bool:bMerged;

	for (new i = 0; i < iWeaponAttributeCount[iClient][iSlot]; i ++)
	{
		if (iWeaponAttributes[iClient][iSlot][i] == iAttribute)
		{
			if (bIsPercent)
			{
				fWeaponAttributeValues[iClient][iSlot][i] += fValue - 1.0;

				bMerged = true;
				break;
			}
			else
			{
				fWeaponAttributeValues[iClient][iSlot][i] += fValue;

				bMerged = true;
				break;
			}
		}
	}
	
	if (! bMerged)
	{
		iWeaponAttributes[iClient][iSlot][iWeaponAttributeCount[iClient][iSlot]]= iAttribute;
		fWeaponAttributeValues[iClient][iSlot][iWeaponAttributeCount[iClient][iSlot]] = fValue;

		iWeaponAttributeCount[iClient][iSlot] ++;
	}
}

/**
 * Sets the attributes of a player's weapon.
 *
 * @param iClient				The client to sets the attributes of.
 * @param iSlot					The weapon in this slot will have the attributes set.
 * @param iAttributes			The indexes of the attributes to set the weapon to.
 * @param fValues				The values of the attributes to set the weapon to.
 *
 * @noreturn
 */
WeaponAttributes_SetAttributes (iClient, iSlot, const iAttributes[ENTITY_MAX_ATTRIBUTES], const Float:fValues[ENTITY_MAX_ATTRIBUTES])
{
	for (new i = 0; i < ENTITY_MAX_ATTRIBUTES; i ++)
	{	
		if (iAttributes[i] != INVALID_ATTRIBUTE)
		{
			iWeaponAttributeCount[iClient][iSlot]++;
		}
		else
		{
			break;
		}
		
		iWeaponAttributes[iClient][iSlot][i]= iAttributes[i];
		fWeaponAttributeValues[iClient][iSlot][i] = fValues[i];
	}
}

/**
 * Clears the attributes of a player's weapons.
 *
 * @param iClient				The client to clear the attributes of.
 *
 * @noreturn
 */
WeaponAttributes_Clear (iClient)
{

	for (new iSlot = 0; iSlot < UPGRADABLE_SLOTS; iSlot ++)
	{
		new iWeapon = EntRefToEntIndex(iWeaponEntRefs[iClient][iSlot]);
		
		if (iWeapon == INVALID_ENT_REFERENCE)
		{
			iWeaponEntRefs[iClient][iSlot] = INVALID_ENT_REFERENCE;
		
			continue;
		}
	
		for (new i = 0; i < iWeaponAttributeCount[iClient][iSlot]; i ++)
		{
			if (iWeaponAttributes[iClient][iSlot][i] > CUSTOM_ATTRIBUTE_OFFSET)
			{
				Esc_RemoveCustomAttribute(iClient, iWeaponAttributes[iClient][iSlot][i]);
				
				continue;
			}
			
			if (iWeaponAttributes[iClient][iSlot][i] == INVALID_ATTRIBUTE)
			{
				continue;
			}
			
			TF2Attrib_RemoveByDefIndex(iWeapon, iWeaponAttributes[iClient][iSlot][i]);

			iWeaponAttributes[iClient][iSlot][i] = 0;
			fWeaponAttributeValues[iClient][iSlot][i] = 0.0;
		}

		iWeaponAttributeCount[iClient][iSlot] = 0;
	}

}

/**
 * Applies the attributes of a player's weapons.
 *
 * @param iClient				The client to apply the attributes of.
 *
 * @noreturn
 */
WeaponAttributes_Apply (iClient)
{
	for (new iSlot = 0; iSlot < UPGRADABLE_SLOTS; iSlot ++)
	{
		new iWeapon = EntRefToEntIndex(iWeaponEntRefs[iClient][iSlot]);
		
		if (iWeapon == INVALID_ENT_REFERENCE)
		{
			continue;
		}
	
		for (new i = 0; i < iWeaponAttributeCount[iClient][iSlot]; i ++)
		{
			if (iWeaponAttributes[iClient][iSlot][i] > CUSTOM_ATTRIBUTE_OFFSET)
			{
				Esc_ApplyCustomAttribute(iClient, iWeaponAttributes[iClient][iSlot][i], fWeaponAttributeValues[iClient][iSlot][i], true);
				
				continue;
			}
			
			TF2Attrib_SetByDefIndex(iWeapon, iWeaponAttributes[iClient][iSlot][i], fWeaponAttributeValues[iClient][iSlot][i]);
		}
	}
}

/**
 * Updates the cached weapon entity for a client's slot.
 *
 * @param iClient				The client to update the weapon of.
 * @param iSlot					The slot to update the weapon of.
 * @param iEntity				The entity index of the weapon in the slot.
 *
 * @noreturn
 */
WeaponAttributes_UpdateWeaponEnt (iClient, iSlot, iEntity)
{
	iWeaponEntRefs[iClient][iSlot] = EntIndexToEntRef(iEntity);
}

/**
 * Resets all a client's attributes and cached weapon entities.
 *
 * @param iClient				The client to reset the data of.
 *
 * @noreturn
 */
WeaponAttributes_ResetData (iClient)
{
	WeaponAttributes_Clear(iClient);

	for (new iSlot = 0; iSlot < UPGRADABLE_SLOTS; iSlot ++)
	{
		iWeaponEntRefs[iClient][iSlot] = INVALID_ENT_REFERENCE;
	}
}