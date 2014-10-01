#if defined _escalation_weaponattributes_included
#endinput
#endif
#define _escalation_weaponattributes_included

#include<Escalation>
#include<Escalation_CustomAttributes>
#include<tf2attributes>
#include<sdktools>

static iWeaponAttributes[MAXPLAYERS + 1][UPGRADABLE_SLOTS][ENTITY_MAX_ATTRIBUTES];
static Float:fWeaponAttributeValues[MAXPLAYERS + 1][UPGRADABLE_SLOTS][ENTITY_MAX_ATTRIBUTES];
static iWeaponAttributeCount[MAXPLAYERS + 1][UPGRADABLE_SLOTS];
static iWeaponEntRefs[MAXPLAYERS + 1][UPGRADABLE_SLOTS];

//An add function.
WeaponAttributes_Add (client, iSlot, iAttribute, Float:fValue, bool:bIsPercent)
{
	if (iAttribute == INVALID_ATTRIBUTE)
	{
		return;
	}

	new bool:bMerged;

	for (new i = 0; i < iWeaponAttributeCount[client][iSlot]; i ++)
	{
		if (iWeaponAttributes[client][iSlot][i] == iAttribute)
		{
			if (bIsPercent)
			{
				fWeaponAttributeValues[client][iSlot][i] += fValue - 1.0;

				bMerged = true;
				break;
			}
			else
			{
				fWeaponAttributeValues[client][iSlot][i] += fValue;

				bMerged = true;
				break;
			}
		}
	}
	
	if (! bMerged)
	{
		iWeaponAttributes[client][iSlot][iWeaponAttributeCount[client][iSlot]]= iAttribute;
		fWeaponAttributeValues[client][iSlot][iWeaponAttributeCount[client][iSlot]] = fValue;
		//bAttributeIsPercent[client][iSlot][iWeaponAttributeCount[client][iSlot]] = bIsPercent;

		iWeaponAttributeCount[client][iSlot] ++;
	}
}

//A Set Function
WeaponAttributes_SetAttributes (client, iSlot, const iAttributes[ENTITY_MAX_ATTRIBUTES], const Float:fValues[ENTITY_MAX_ATTRIBUTES])
{
	for (new i = 0; i < ENTITY_MAX_ATTRIBUTES; i ++)
	{	
		if (iAttributes[i] != INVALID_ATTRIBUTE)
		{
			iWeaponAttributeCount[client][iSlot]++;
		}
		else
		{
			break;
		}
		
		iWeaponAttributes[client][iSlot][i]= iAttributes[i];
		fWeaponAttributeValues[client][iSlot][i] = fValues[i];
	}


}

//A clear function.
WeaponAttributes_Clear (client)
{

	for (new iSlot = 0; iSlot < UPGRADABLE_SLOTS; iSlot ++)
	{
		new iWeapon = EntRefToEntIndex(iWeaponEntRefs[client][iSlot]);
		
		if (iWeapon == INVALID_ENT_REFERENCE)
		{
			iWeaponEntRefs[client][iSlot] = INVALID_ENT_REFERENCE;
		
			continue;
		}
	
		for (new i = 0; i < iWeaponAttributeCount[client][iSlot]; i ++)
		{
			if (iWeaponAttributes[client][iSlot][i] > CUSTOM_ATTRIBUTE_OFFSET)
			{
				Esc_RemoveCustomAttribute(client, iWeaponAttributes[client][iSlot][i]);
				
				continue;
			}
			
			if (iWeaponAttributes[client][iSlot][i] == INVALID_ATTRIBUTE)
			{
				continue;
			}
			
			TF2Attrib_RemoveByDefIndex(iWeapon, iWeaponAttributes[client][iSlot][i]);

			iWeaponAttributes[client][iSlot][i] = 0;
			fWeaponAttributeValues[client][iSlot][i] = 0.0;
		}

		iWeaponAttributeCount[client][iSlot] = 0;
	}

}

//A apply to player function.
WeaponAttributes_Apply (client)
{
	for (new iSlot = 0; iSlot < UPGRADABLE_SLOTS; iSlot ++)
	{
		new iWeapon = EntRefToEntIndex(iWeaponEntRefs[client][iSlot]);
		
		if (iWeapon == INVALID_ENT_REFERENCE)
		{
			continue;
		}
	
		for (new i = 0; i < iWeaponAttributeCount[client][iSlot]; i ++)
		{
			if (iWeaponAttributes[client][iSlot][i] > CUSTOM_ATTRIBUTE_OFFSET)
			{
				Esc_ApplyCustomAttribute(client, iWeaponAttributes[client][iSlot][i], fWeaponAttributeValues[client][iSlot][i], true);
				
				continue;
			}
			
			TF2Attrib_SetByDefIndex(iWeapon, iWeaponAttributes[client][iSlot][i], fWeaponAttributeValues[client][iSlot][i]);
		}
	}
}

//An Update Function
WeaponAttributes_UpdateWeaponEnt (client, iSlot, iEntity)
{
	iWeaponEntRefs[client][iSlot] = EntIndexToEntRef(iEntity);
}

//A Reset Function
WeaponAttributes_ResetData (client)
{
	WeaponAttributes_Clear(client);

	for (new iSlot = 0; iSlot < UPGRADABLE_SLOTS; iSlot ++)
	{
		iWeaponEntRefs[client][iSlot] = INVALID_ENT_REFERENCE;
	}
}