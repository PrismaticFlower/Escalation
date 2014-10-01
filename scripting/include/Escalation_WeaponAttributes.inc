#if defined _escalation_weaponattributes_included
#endinput
#endif
#define _escalation_weaponattributes_included

#include<Escalation_Constants>
#include<Escalation_CustomAttributes>
#include<tf2attributes>
#include<sdktools>

static iWeaponAttributes[MAXPLAYERS + 1][UPGRADABLE_SLOTS][ENTITY_MAX_ATTRIBUTES];
static Float:fWeaponAttributeValues[MAXPLAYERS + 1][UPGRADABLE_SLOTS][ENTITY_MAX_ATTRIBUTES];
static iWeaponAttributeCount[MAXPLAYERS + 1][UPGRADABLE_SLOTS];
static iWeaponEntRefs[MAXPLAYERS + 1][UPGRADABLE_SLOTS];

//An add function.
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
		//bAttributeIsPercent[iClient][iSlot][iWeaponAttributeCount[iClient][iSlot]] = bIsPercent;

		iWeaponAttributeCount[iClient][iSlot] ++;
	}
}

//A Set Function
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

//A clear function.
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

//A apply to player function.
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

//An Update Function
WeaponAttributes_UpdateWeaponEnt (iClient, iSlot, iEntity)
{
	iWeaponEntRefs[iClient][iSlot] = EntIndexToEntRef(iEntity);
}

//A Reset Function
WeaponAttributes_ResetData (iClient)
{
	WeaponAttributes_Clear(iClient);

	for (new iSlot = 0; iSlot < UPGRADABLE_SLOTS; iSlot ++)
	{
		iWeaponEntRefs[iClient][iSlot] = INVALID_ENT_REFERENCE;
	}
}