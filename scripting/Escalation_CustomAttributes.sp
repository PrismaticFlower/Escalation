#include<SourceMod>
#include<tf2>
#include<tf2_stocks>
#include<sdkhooks>
#include<sdktools>

#define MAX_ATTRIBUTES 16
#define NULL_VAR -1

//** BE WARNED THIS FILE IS A MESS AND IT'S ON MY TO-DO LIST TO GIVE IT A FACELIFT. **//

public Plugin:myinfo =
{
	name = "Escalation Custom Attributes",
	author = "SleepKiller",
	description = "Provides a library of functions that enable defining and applying of custom attributes to players.",
	version = "0.9.1",
	url = ""
};

enum EventTypes
{
	NULL_EVENT = 0,
	PLAYER_DEATH,
	PLAYER_HURT,
	PLAYER_HURT_SELF,
	PLAYER_JARATED,
	PLAYER_ARROWED,
	SOUND_PLAYED
};

enum ActionTypes
{
	NULL_ACTION = 0,
	HEALTH_ON_KILL, //Gives Health on Kill not matter what weapon the user is wielding.
	MULT_DAMAGE, //Multiplies the damage being dealt based off conditions.
	MULT_DAMAGE_CUSTOM, //Multiplies the damage being dealt if damagecustom equals var1.
	MULT_WORLD_DAMAGE, //Multiplies world damage.
	MULT_DAMAGE_VS_COND, //Multiplies the damage dealt if the victim is under a condition (also includes most conditions from MULT_DAMAGE)
	MULT_DAMAGE_VS_COND_AND_ACTIVE_WEAPON, //Multiplies damage done by V if the victim is under a condition and has the weapon in a slot active.
	MULT_DAMAGE_VS_FLAG, //Multiplies the dame dealt if the damagetype has the specified flag.
	MULT_DAMAGE_VS_ENTFLAG, //Multiplies the damage dealt if the victim had an entflag.
	APPLY_CONDITION, //Applies a condition to the player being damaged.
	APPLY_STUNFLAGS, //Applies stunflags to the player being damaged or you-know-what.
	REAPPLY_CONDITION, //Reapplies a condtion to the player being you-know-what on. (Or damaged, but this is a bit useless for that.)
	REMOVE_CONDITION_DELAYED, //Removes a conditon from a player, waiting 1 frame before doing so.
	NEGATE_DAMAGE, //Negates the damage being done to the player by adding 3x the amount of damage done in health to the player before setting it back down after the damage has been done.
	NEGATE_DAMAGE_PERCENT, //Negates a percentage of damage being done to the player.
	CRIT_VS_CONDS, //Inflict Critical Damage against the other player if they are under up to three conditions.
	NO_CRITS_VS_NOT_CONDS, //Stops Critical Damage against the other player if they are not under up to three conditions.
	IGNITE_PLAYER, //Ignites a player based of conditions.
	REMOVE_CONDITIONS, //Removes up to four conditions from the other player.
	TRACE_AND_REMOVE_CONDS, //Performs a trace ray from the player and removes up to three conditions from the other player. 
	CRIT_TO_MINICRIT, //Crits into mini-crits.
	ADD_COND_ON_KILL //Adds a condition the player when they kill another player.
};

enum AttributeInfo
{
	EventTypes:_Event,
	ActionTypes:_Action,
	_Var1,
	_Var2,
	_Var3,
	_Var4,
	_Var5
};

enum AppliedAttribute
{
	_Attribute,
	Float:_Value
};

static g_iClient_PlayerDeath_Attributes[MAXPLAYERS + 1][MAX_ATTRIBUTES][AppliedAttribute];
static g_iClient_PlayerDeath_AttributeCount[MAXPLAYERS + 1];

static g_iClient_PlayerHurt_Attributes[MAXPLAYERS + 1][MAX_ATTRIBUTES][AppliedAttribute];
static g_iClient_PlayerHurt_AttributeCount[MAXPLAYERS + 1];

static g_iClient_PlayerHurtSelf_Attributes[MAXPLAYERS + 1][MAX_ATTRIBUTES][AppliedAttribute];
static g_iClient_PlayerHurtSelf_AttributeCount[MAXPLAYERS + 1];

static g_iClient_PlayerJarated_Attributes[MAXPLAYERS + 1][MAX_ATTRIBUTES][AppliedAttribute];
static g_iClient_PlayerJarated_AttributeCount[MAXPLAYERS + 1];

static g_iClient_PlayerArrowed_Attributes[MAXPLAYERS + 1][MAX_ATTRIBUTES][AppliedAttribute];
static g_iClient_PlayerArrowed_AttributeCount[MAXPLAYERS + 1];

static g_iClient_SoundPlayed_Attributes[MAXPLAYERS + 1][MAX_ATTRIBUTES][AppliedAttribute];
static g_iClient_SoundPlayed_AttributeCount[MAXPLAYERS + 1];

static Handle:g_AttributeTrie;
static Handle:g_hStringStore;

static bool:g_bSetHealthInPost[MAXPLAYERS + 1];
static g_iHealthInPostAmount[MAXPLAYERS + 1];

static bool:g_bRemoveCondInPost[MAXPLAYERS + 1];
static TFCond:g_iCondRemoveInPos[MAXPLAYERS + 1];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("Esc_ApplyCustomAttribute", Native_Esc_ApplyCustomAttribute);
	CreateNative("Esc_RemoveCustomAttributes", Native_Esc_RemoveCustomAttributes);
	CreateNative("Esc_RemoveCustomAttribute", Native_Esc_RemoveCustomAttribute);
	CreateNative("Esc_LoadCustomAttributeFile", Native_Esc_LoadCustomAttributeFile);
	
	RegPluginLibrary("Escalation_CustomAttributes");
	
	return APLRes_Success;
}


public OnPluginStart ()
{
	CheckStorage();
	
	HookEvent("player_death", Event_PlayerDeath);
	HookUserMessage(GetUserMessageId("PlayerJarated"), Event_PlayerJarated);
	HookEvent("arrow_impact", Event_PlayerArrowed);
	AddNormalSoundHook(SoundHook);
	
	//Catch those pesky already connected players.
	for (new i = 1; i <= MaxClients; i ++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer (client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_PlayerHurt);
	SDKHook(client, SDKHook_OnTakeDamagePost, Event_PlayerHurtPost);
}

public OnClientDisconnect (client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Event_PlayerHurt);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, Event_PlayerHurtPost);
}

//Events

public Event_PlayerDeath (Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client1 = GetClientOfUserId(GetEventInt(event, "attacker"));
	//new Client2 = GetClientOfUserId(GetEventInt(event, "userid"));
	new iDamageCustom  = GetEventInt(event, "customkill");
	
	for (new i = 0; i < g_iClient_PlayerDeath_AttributeCount[Client1]; i ++)
	{	
		decl String:Attribute[8];
		IntToString(g_iClient_PlayerDeath_Attributes[Client1][i][_Attribute], Attribute, sizeof(Attribute));
		
		decl tmpAttribute[AttributeInfo];
		GetTrieArray(g_AttributeTrie, Attribute, tmpAttribute[0], sizeof(tmpAttribute));
	
		switch (tmpAttribute[_Action])
		{
			case HEALTH_ON_KILL:
			{
				new iMaxHealth = GetEntProp(Client1, Prop_Data, "m_iMaxHealth");
				new iHealth = GetEntProp(Client1, Prop_Send, "m_iHealth");
				
				//Check to see if we should be respecting the max health of a player.
				if (bool:tmpAttribute[_Var1] == true)
				{
					//If they're overhealed we continue right away.
					if (iHealth > iMaxHealth)
					{
						continue;
					}
					
					//Increase the health of the player.
					iHealth += RoundFloat(g_iClient_PlayerDeath_Attributes[Client1][i][_Value]);
					
					//If that pushed us over the max health we'll need to set it back down.
					if (iHealth > iMaxHealth)
					{
						iHealth = iMaxHealth;
					}
				}
				else
				{
					//Check for pre-existing overheal.
					if (iHealth > tmpAttribute[_Var2])
					{
						continue;
					}
					
					//Increase the health of the player by the value of the attribute.
					iHealth += RoundFloat(g_iClient_PlayerDeath_Attributes[Client1][i][_Value]);
				
					//Check to see if we're above the limit on the Attribute's overheal.
					if (iHealth > tmpAttribute[_Var2])
					{
						iHealth = tmpAttribute[_Var2]; //If we are we set it back down to the limit.
					}
				}
				
				//Finally we set the health of the player.
				SetEntProp(Client1, Prop_Send, "m_iHealth", iHealth);
				
				continue;
			}
			
			case ADD_COND_ON_KILL:
			{		
				if (tmpAttribute[_Var1] != NULL_VAR)
				{			
					if (tmpAttribute[_Var1] != iDamageCustom)
					{
					
						continue;
					}
				}

				if (tmpAttribute[_Var2] != NULL_VAR)
				{
					TF2_AddCondition(Client1, TFCond:tmpAttribute[_Var2])
				}				

				if (tmpAttribute[_Var3] != NULL_VAR)
				{
					TF2_AddCondition(Client1, TFCond:tmpAttribute[_Var3])
				}

				if (tmpAttribute[_Var4] != NULL_VAR)
				{
					TF2_AddCondition(Client1, TFCond:tmpAttribute[_Var4])
				}

				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					//Create a datapack to hold our lovely data.
					new Handle:hDataPack = CreateDataPack();

					WritePackCell(hDataPack, tmpAttribute[_Var5]);
					WritePackCell(hDataPack, Client1);

					ResetPack(hDataPack);
				
#if (SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 6)
					RequestFrame(RemoveCondition_Delayed, hDataPack);
#else
					if (CreateTimer(0.1, RemoveCondition_Delayed, hDataPack) == INVALID_HANDLE)
					{
						CloseHandle(hDataPack);
						ThrowError("Timer creation failed for some unknown reason. The world is probably going to end now.");
					}
#endif
				}
			}
		}
		
	}
}

public Action:Event_PlayerHurt (victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	//Attacker Attributes
	for (new i = 0; i < g_iClient_PlayerHurt_AttributeCount[attacker]; i ++)
	{
		if (attacker == 0 || attacker > MAXPLAYERS)
		{
			break;
		}
	
		decl String:Attribute[8];
		IntToString(g_iClient_PlayerHurt_Attributes[attacker][i][_Attribute], Attribute, sizeof(Attribute));
		
		decl tmpAttribute[AttributeInfo];
		GetTrieArray(g_AttributeTrie, Attribute, tmpAttribute[0], sizeof(tmpAttribute));
	
		switch (tmpAttribute[_Action])
		{
			case MULT_DAMAGE:
			{
				//Check to see if the damage should only be changed if damagecustom equals _Var1.
				if (tmpAttribute[_Var1] != NULL_VAR)
				{
					if (tmpAttribute[_Var1] != damagecustom)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the item definition index matches.
				if (tmpAttribute[_Var2] != NULL_VAR && IsValidEntity(weapon))
				{
					if (tmpAttribute[_Var2] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the player damaged themself.
				if (bool:tmpAttribute[_Var3] == true)
				{
					if (victim != attacker)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if no weapon caused the damage.
				if (bool:tmpAttribute[_Var4] == true)
				{
					if (weapon != -1)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}
				
				damage *= g_iClient_PlayerHurt_Attributes[attacker][i][_Value];
			}

			case APPLY_CONDITION:
			{
				//If the min damage specified in the config file is greater than the damage being dealt we don't apply the condition.
				if (float(tmpAttribute[_Var2]) > damage)
				{
					continue;
				}
				
				//Check to see if the conditon should only be applied if damagecustom equals _Var3.
				if (tmpAttribute[_Var3] != NULL_VAR)
				{
					if (tmpAttribute[_Var3] != damagecustom)
					{
						continue;
					}
				}

				//Check to see if the conditon should only be applied if the item definition index matches.
				if (tmpAttribute[_Var4] != NULL_VAR && IsValidEntity(weapon))
				{
					
					if (tmpAttribute[_Var4] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}

				//Check to see if the damage should only be changed if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}
				
				if (tmpAttribute[_Var1] < _:TFCond_Slowed || tmpAttribute[_Var1] > _:TFCond)
				{
					LogError("Encountered error processing attributes. Condition %i is out of range.", tmpAttribute[_Var1]);
				}


				TF2_AddCondition(victim, TFCond:tmpAttribute[_Var1], g_iClient_PlayerHurt_Attributes[attacker][i][_Value], inflictor);
			}

			case MULT_DAMAGE_VS_COND:
			{
				//Check to see if the player is actually under the condition.
				if (! TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var1]))
				{
					continue;
				}
				
				//Check to see if the damage should only be changed if the item definition index matches.
				if (tmpAttribute[_Var2] != NULL_VAR && IsValidEntity(weapon))
				{
					if (tmpAttribute[_Var2] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the player damaged themself.
				if (bool:tmpAttribute[_Var3] == true)
				{
					if (victim != attacker)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if no weapon caused the damage.
				if (bool:tmpAttribute[_Var4] == true)
				{
					if (weapon != -1)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}				

				damage *= g_iClient_PlayerHurt_Attributes[attacker][i][_Value];
			}

			case MULT_DAMAGE_VS_FLAG:
			{		
				if (damagetype & (tmpAttribute[_Var1]) != tmpAttribute[_Var1])
				{
					continue;
				}
				
				//Check to see if the damage should only be changed if the item definition index matches.
				if (tmpAttribute[_Var3] != NULL_VAR && IsValidEntity(weapon))
				{
					if (tmpAttribute[_Var3] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if damagecustom equals _Var4.
				if (tmpAttribute[_Var4] != NULL_VAR)
				{
					if (tmpAttribute[_Var4] != damagecustom)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}
				
				damage *= g_iClient_PlayerHurt_Attributes[attacker][i][_Value];
			}

			case MULT_DAMAGE_VS_ENTFLAG:
			{
				new iFlags = GetEntityFlags(victim);
				
				if ((iFlags & tmpAttribute[_Var1]) != tmpAttribute[_Var1])
				{
					continue;
				}
				
				//Check to see if the damage should only be changed if the item definition index matches.
				if (tmpAttribute[_Var3] != NULL_VAR && IsValidEntity(weapon))
				{
					if (tmpAttribute[_Var3] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if damagecustom equals _Var4.
				if (tmpAttribute[_Var4] != NULL_VAR)
				{
					if (tmpAttribute[_Var4] != damagecustom)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}
				
				damage *= g_iClient_PlayerHurt_Attributes[attacker][i][_Value];
			}
		
			case REAPPLY_CONDITION:
			{
				//Check to see if we should be checking to see if the player is in the condition.
				if (bool:tmpAttribute[_Var2] == true)
				{
					if (! TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var1]))
					{
						continue;
					}
				}	
				
				//If the min damage specified in the config file is greater than the damage being dealt we don't apply the condition.
				if (float(tmpAttribute[_Var3]) > damage)
				{
					continue;
				}

				//Check to see if the conditon should only be applied if the item definition index matches.
				if (tmpAttribute[_Var4] != NULL_VAR && IsValidEntity(weapon))
				{
					
					if (tmpAttribute[_Var4] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}

				//Check to see if the conditon should be reapplied if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}
				
				//Remove the condition.
				TF2_RemoveCondition(victim, TFCond:tmpAttribute[_Var1]);
				
				
				//Create a datapack to hold our lovely data.
				new Handle:hDataPack = CreateDataPack();

				WritePackCell(hDataPack, attacker);
				WritePackCell(hDataPack, g_iClient_PlayerJarated_Attributes[attacker][i][_Value]);
				WritePackCell(hDataPack, tmpAttribute[_Var1]);
				WritePackCell(hDataPack, victim);

				ResetPack(hDataPack);
				
#if (SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 6)
				RequestFrame(AddCondition_Delayed, hDataPack);
#else
				if (CreateTimer(0.1, AddCondition_Delayed, hDataPack) == INVALID_HANDLE)
				{
					CloseHandle(hDataPack);
					ThrowError("Timer creation failed for some unknown reason. The world is probably going to end now.");
				}
#endif
			}
		
			case REMOVE_CONDITION_DELAYED:
			{
				//Check to see if we should be checking to see if damagecustom matches.
				if (tmpAttribute[_Var2] != NULL_VAR)
				{
					if (tmpAttribute[_Var2] != damagecustom)
					{
						continue;
					}
				}
				
				//If the min damage specified in the config file is greater than the damage being dealt we don't apply the condition.
				if (float(tmpAttribute[_Var3]) > damage)
				{
					continue;
				}

				//Check to see if the conditon should only be applied if the item definition index matches.
				if (tmpAttribute[_Var4] != NULL_VAR && IsValidEntity(weapon))
				{
					
					if (tmpAttribute[_Var4] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}

				//Check to see if the conditon should be reapplied if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}


				//Create a datapack to hold our lovely data.
				new Handle:hDataPack = CreateDataPack();

				WritePackCell(hDataPack, tmpAttribute[_Var1]);
				WritePackCell(hDataPack, victim);

				ResetPack(hDataPack);
				
#if (SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 6)
				RequestFrame(RemoveCondition_Delayed, hDataPack);
#else
				if (CreateTimer(0.1, RemoveCondition_Delayed, hDataPack) == INVALID_HANDLE)
				{
					CloseHandle(hDataPack);
					ThrowError("Timer creation failed for some unknown reason. The world is probably going to end now.");
				}
#endif
			}

			case CRIT_VS_CONDS:
			{
				//Check to see if the player is under the first conditon.
				if (tmpAttribute[_Var1] != NULL_VAR)
				{
					if (! TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var1]))
					{
						continue;
					}
				}
				
				//Check to see if the player is under the second conditon.
				if (tmpAttribute[_Var2] != NULL_VAR)
				{
					if (! TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var2]))
					{
						continue;
					}
				}
				
				//Check to see if the player is under the third conditon.
				if (tmpAttribute[_Var3] != NULL_VAR)
				{
					if (! TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var3]))
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the item definition index matches.
				if (tmpAttribute[_Var4] != NULL_VAR && IsValidEntity(weapon))
				{
					if (tmpAttribute[_Var4] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}				

				damagetype |= DMG_CRIT;
			}
			
			case NO_CRITS_VS_NOT_CONDS:
			{
				//Check to see if the player is under the first conditon.
				if (tmpAttribute[_Var1] != NULL_VAR)
				{
					if (TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var1]))
					{
						continue;
					}
				}
				
				//Check to see if the player is under the second conditon.
				if (tmpAttribute[_Var2] != NULL_VAR)
				{
					if (TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var2]))
					{
						continue;
					}
				}
				
				//Check to see if the player is under the third conditon.
				if (tmpAttribute[_Var3] != NULL_VAR)
				{
					if (TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var3]))
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the item definition index matches.
				if (tmpAttribute[_Var4] != NULL_VAR && IsValidEntity(weapon))
				{
					if (tmpAttribute[_Var4] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be changed if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}				

				damagetype &= ~DMG_CRIT;
			}

			case IGNITE_PLAYER:
			{
				//If the min damage specified in the config file is greater than the damage being dealt we don't ignite the player.
				if (float(tmpAttribute[_Var1]) > damage)
				{
					continue;
				}
				
				//Check to see if the player should only be ignited if damagecustom equals _Var2.
				if (tmpAttribute[_Var2] != NULL_VAR)
				{
					if (tmpAttribute[_Var2] != damagecustom)
					{
						continue;
					}
				}

				//Check to see if the player should only be ignited if the item definition index matches.
				if (tmpAttribute[_Var3] != NULL_VAR && IsValidEntity(weapon))
				{
					
					if (tmpAttribute[_Var3] != GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						continue;
					}
				}

				//Check to see if the player should only be ignited if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var4] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var5]))
					{
						continue;
					}
				}
				
				TF2_IgnitePlayer(victim, attacker);
			}
		
			case CRIT_TO_MINICRIT:
			{
				if ((damagetype & DMG_CRIT) != DMG_CRIT)
				{
					continue;
				}

				//Check to see if the damage should only be changed if the weapon in this slot inflicted the damage.
				if (tmpAttribute[_Var1] != NULL_VAR)
				{
					if (weapon != GetPlayerWeaponSlot(attacker, tmpAttribute[_Var1]))
					{
						continue;
					}
				}

				if (tmpAttribute[_Var2] != NULL_VAR)
				{
					if (TF2_IsPlayerInCondition(attacker, TFCond:tmpAttribute[_Var2]))
					{
						continue;
					}
				}
				
				if (tmpAttribute[_Var3] != NULL_VAR)
				{
					if (TF2_IsPlayerInCondition(attacker, TFCond:tmpAttribute[_Var3]))
					{
						continue;
					}
				}
				
				if (tmpAttribute[_Var4] != NULL_VAR)
				{
					if (TF2_IsPlayerInCondition(attacker, TFCond:tmpAttribute[_Var4]))
					{
						continue;
					}
				}
				
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (TF2_IsPlayerInCondition(attacker, TFCond:tmpAttribute[_Var5]))
					{
						continue;
					}
				}
				
				//Remove the crit flag.
				damagetype &= ~DMG_CRIT;
				
				if (! TF2_IsPlayerInCondition(attacker, TFCond_CritCola))
				{
					TF2_AddCondition(attacker, TFCond_CritCola, 0.1);
				
					g_bRemoveCondInPost[attacker] = true;
					g_iCondRemoveInPos[attacker] = TFCond_CritCola;
				}
			}
		}
	}
	
	//Victim Attributes
	for (new i = 0; i < g_iClient_PlayerHurtSelf_AttributeCount[victim]; i ++)
	{
		if (victim == 0 || victim > MAXPLAYERS)
		{
			break;
		}

		decl String:Attribute[8];
		IntToString(g_iClient_PlayerHurtSelf_Attributes[victim][i][_Attribute], Attribute, sizeof(Attribute));
		
		decl tmpAttribute[AttributeInfo];
		GetTrieArray(g_AttributeTrie, Attribute, tmpAttribute[0], sizeof(tmpAttribute));	
	
		switch (tmpAttribute[_Action])
		{
			case MULT_WORLD_DAMAGE:
			{
				if (attacker != 0)
				{
					continue;
				}
				
				damage *= g_iClient_PlayerHurtSelf_Attributes[victim][i][_Value];
			}
			
			case MULT_DAMAGE_CUSTOM:
			{
				if (tmpAttribute[_Var1] != damagecustom)
				{
					continue;
				}
				
				damage *= g_iClient_PlayerHurtSelf_Attributes[victim][i][_Value];
			}
		
			case MULT_DAMAGE_VS_COND:
			{
				//Check to see if the player is actually under the condition.
				if (! TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var1]))
				{
					continue;
				}

				damage *= g_iClient_PlayerHurtSelf_Attributes[victim][i][_Value];
			}
			
			case MULT_DAMAGE_VS_COND_AND_ACTIVE_WEAPON:
			{
				//Check to see if the player is actually under the condition.
				if (! TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var1]))
				{
					continue;
				}
				
				
				if (GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon") != GetPlayerWeaponSlot(victim, tmpAttribute[_Var2]))
				{
					continue;
				}
				
				
				damage *= g_iClient_PlayerHurtSelf_Attributes[victim][i][_Value];			

			}

			case MULT_DAMAGE_VS_FLAG:
			{
				if (damagetype & tmpAttribute[_Var1] != tmpAttribute[_Var2])
				{
				
					continue;
				}
				
				damage *= g_iClient_PlayerHurtSelf_Attributes[victim][i][_Value];
			}

			case MULT_DAMAGE_VS_ENTFLAG:
			{
				new iFlags = GetEntityFlags(victim);
				
				if (iFlags & tmpAttribute[_Var1] != tmpAttribute[_Var2])
				{
					continue;
				}
				
				damage *= g_iClient_PlayerHurtSelf_Attributes[victim][i][_Value];
			}
			
			case NEGATE_DAMAGE:
			{
				//Check to see if the damage should only be negated if damagecustom equals _Var1.
				if (tmpAttribute[_Var1] != NULL_VAR)
				{
					if (tmpAttribute[_Var1] != damagecustom)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be negated if the player is under a conditon.
				if (tmpAttribute[_Var2] != NULL_VAR)
					{
					if (! TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var2]))
					{
						continue;
					}
				}

				//Check to see if the damage should only be negated if damagetype has a specific flag set.
				if (tmpAttribute[_Var3] != NULL_VAR)
				{
					if (damagetype & tmpAttribute[_Var1] != 1)
					{
					
						continue;
					}
				}
				
				//Check to see if the damage should only be negated if the client has a specific entflag set.
				if (tmpAttribute[_Var4] != NULL_VAR)
				{
					new iFlags = GetEntityFlags(victim);
				
					if (iFlags & tmpAttribute[_Var4] != tmpAttribute[_Var5])
					{
						continue;
					}
				}
				
				g_iHealthInPostAmount[victim] = GetEntProp(victim, Prop_Send, "m_iHealth");
				g_bSetHealthInPost[victim] = true;
				
				SetEntProp(victim, Prop_Send, "m_iHealth", g_iHealthInPostAmount[victim] + (damage * 3));
			}			
			
			case NEGATE_DAMAGE_PERCENT:
			{
				//Check to see if the damage should only be negated if damagecustom equals _Var1.
				if (tmpAttribute[_Var1] != NULL_VAR)
				{
					if (tmpAttribute[_Var1] != damagecustom)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be negated if the player is under a conditon.
				if (tmpAttribute[_Var2] != NULL_VAR)
				{
					if (! TF2_IsPlayerInCondition(victim, TFCond:tmpAttribute[_Var2]))
					{
						continue;
					}
				}

				//Check to see if the damage should only be negated if damagetype has a specific flag set.
				if (tmpAttribute[_Var3] != NULL_VAR)
				{
					if (damagetype & tmpAttribute[_Var1] != 1)
					{
					
						continue;
					}
				}

				//Check to see if the damage should only be negated if the client has a specific entflag set.
				if (tmpAttribute[_Var4] != NULL_VAR)
				{
					new iFlags = GetEntityFlags(victim);
				
					if (iFlags & tmpAttribute[_Var4] != 1)
					{
						continue;
					}
				}
				
				//Check to see if the damage should only be negated if this is self damage.
				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					if (attacker != victim)
					{
						continue;
					}
				}
				
				g_iHealthInPostAmount[victim] = GetEntProp(victim, Prop_Send, "m_iHealth") - RoundFloat(damage * g_iClient_PlayerHurtSelf_Attributes[victim][i][_Value]);
				g_bSetHealthInPost[victim] = true;
				
				//Check that the playere isn't just going to die.
				if (g_iHealthInPostAmount[victim] <= 0)
				{
					g_iHealthInPostAmount[victim] = 0;
					g_bSetHealthInPost[victim] = false;
					
					continue;
				}
				
				SetEntProp(victim, Prop_Send, "m_iHealth", g_iHealthInPostAmount[victim] + (damage * 3));
			}
		}
	}
	
	return Plugin_Changed;
}

public Event_PlayerHurtPost (victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{		

	if (victim != 0 && victim < MAXPLAYERS)
	{
		if (g_bSetHealthInPost[victim])
		{
			SetEntProp(victim, Prop_Send, "m_iHealth", g_iHealthInPostAmount[victim]);
	
			g_iHealthInPostAmount[victim] = 0;
			g_bSetHealthInPost[victim] = false;
		}

		if (g_bRemoveCondInPost[victim])
		{
			TF2_RemoveCondition(victim, g_iCondRemoveInPos[victim]);
		
			g_bRemoveCondInPost[victim] = false;
			g_iCondRemoveInPos[victim] = TFCond:-1;
		}
	}
	
	if (attacker != 0 && attacker < MAXPLAYERS)
	{
		if (g_bSetHealthInPost[attacker])
		{
			SetEntProp(attacker, Prop_Send, "m_iHealth", g_iHealthInPostAmount[attacker]);
	
			g_iHealthInPostAmount[attacker] = 0;
			g_bSetHealthInPost[attacker] = false;
		}
	
		if (g_bRemoveCondInPost[attacker])
		{
			TF2_RemoveCondition(attacker, g_iCondRemoveInPos[attacker]);
		
			g_bRemoveCondInPost[attacker] = false;
			g_iCondRemoveInPos[attacker] = TFCond:-1;
		}
	}
}

public Action:Event_PlayerJarated (UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new Client1 = BfReadByte(bf);
	new Client2 = BfReadByte(bf);
	
	for (new i = 0; i < g_iClient_PlayerJarated_AttributeCount[Client1]; i ++)
	{	
		decl String:Attribute[8];
		IntToString(g_iClient_PlayerJarated_Attributes[Client1][i][_Attribute], Attribute, sizeof(Attribute));
		
		decl tmpAttribute[AttributeInfo];
		GetTrieArray(g_AttributeTrie, Attribute, tmpAttribute[0], sizeof(tmpAttribute));
	
		switch (tmpAttribute[_Action])
		{
			case APPLY_STUNFLAGS:
			{
				new Float:fTime;
				new Float:fSlowDown;
				
				//If Var2 is true we use the attribute's value as the amount of time to stun the player.
				if (bool:tmpAttribute[_Var2] == true)
				{
					fTime = g_iClient_PlayerJarated_Attributes[Client1][i][_Value];
				}
				//Else we use Var3 as the time and use the attribute value as the slowdown percent.
				else
				{
					fSlowDown = g_iClient_PlayerJarated_Attributes[Client1][i][_Value];
					fTime = float(tmpAttribute[_Var3]);
				}
			
				TF2_StunPlayer(Client2, fTime, fSlowDown, tmpAttribute[_Var1], Client1);
			}

			case REAPPLY_CONDITION:
			{		
				//Check to see if we should be checking to see if the player is in the condition.
				if (bool:tmpAttribute[_Var2] == true)
				{
					if (! TF2_IsPlayerInCondition(Client2, TFCond:tmpAttribute[_Var1]))
					{
						continue;
					}
				}
				
				//Remove the condition.
				TF2_RemoveCondition(Client2, TFCond:tmpAttribute[_Var1]);
				
				//Apply the condition again with the new time.
				//TF2_AddCondition(Client2, TFCond_Milked, g_iClient_PlayerJarated_Attributes[Client1][i][_Value], Client1);
				
				//Create a datapack to hold our lovely data.
				new Handle:hDataPack = CreateDataPack();

				WritePackCell(hDataPack, Client1);
				WritePackCell(hDataPack, g_iClient_PlayerJarated_Attributes[Client1][i][_Value]);
				WritePackCell(hDataPack, tmpAttribute[_Var1]);
				WritePackCell(hDataPack, Client2);

				ResetPack(hDataPack);
				
#if (SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 6)
				RequestFrame(AddCondition_Delayed, hDataPack);
#else
				if (CreateTimer(0.1, AddCondition_Delayed, hDataPack) == INVALID_HANDLE)
				{
					CloseHandle(hDataPack);
					LogError("Timer creation failed for some unknown reason. The world is probably going to end now.");
				}
#endif
			}
		}
	}
}

public Action:Event_PlayerArrowed (Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client1 = GetEventInt(event, "shooter");
	new Client2 = GetEventInt(event, "attachedEntity");

	for (new i = 0; i < g_iClient_PlayerArrowed_AttributeCount[Client1]; i ++)
	{	
		decl String:Attribute[8];
		IntToString(g_iClient_PlayerArrowed_Attributes[Client1][i][_Attribute], Attribute, sizeof(Attribute));
		
		decl tmpAttribute[AttributeInfo];
		GetTrieArray(g_AttributeTrie, Attribute, tmpAttribute[0], sizeof(tmpAttribute));
	
		switch (tmpAttribute[_Action])
		{
			case REMOVE_CONDITIONS:
			{
				if (tmpAttribute[_Var1] == 1)
				{
					if (GetClientTeam(Client1) != GetClientTeam(Client2))
					{
						continue;
					}
				}

				if (tmpAttribute[_Var2] != NULL_VAR)
				{
					TF2_RemoveCondition(Client2, TFCond:tmpAttribute[_Var2]);
				}

				if (tmpAttribute[_Var3] != NULL_VAR)
				{
					TF2_RemoveCondition(Client2, TFCond:tmpAttribute[_Var3]);
				}

				if (tmpAttribute[_Var4] != NULL_VAR)
				{
					TF2_RemoveCondition(Client2, TFCond:tmpAttribute[_Var4]);
				}

				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					TF2_RemoveCondition(Client2, TFCond:tmpAttribute[_Var5]);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:SoundHook (clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (entity > (MAXPLAYERS) || entity < 0)
	{
		return Plugin_Continue;
	}

	//weapons/sniper_sydneysleeper_shoot
	for (new i = 0; i < g_iClient_SoundPlayed_AttributeCount[entity]; i ++)
	{	
		decl String:Attribute[8];
		IntToString(g_iClient_SoundPlayed_Attributes[entity][i][_Attribute], Attribute, sizeof(Attribute));
		
		decl tmpAttribute[AttributeInfo];
		GetTrieArray(g_AttributeTrie, Attribute, tmpAttribute[0], sizeof(tmpAttribute));
	
		switch (tmpAttribute[_Action])
		{
			case TRACE_AND_REMOVE_CONDS:
			{
				decl String:var1_string[64];
				decl String:var3_string[64];
				
				GetArrayString(g_hStringStore, tmpAttribute[_Var1], var1_string, sizeof(var1_string));
				GetArrayString(g_hStringStore, tmpAttribute[_Var3], var3_string, sizeof(var3_string));

				if (StrContains(sample, var1_string) == -1)
				{
					continue;
				}

				new iOtherPlayer = GetClientAimTarget(entity, true);
				
				if (tmpAttribute[_Var2] == 1)
				{
					if (GetClientTeam(entity) != GetClientTeam(iOtherPlayer))
					{
						continue;
					}
				}
				
				if (tmpAttribute[_Var3] != NULL_VAR)
				{
					new iWeapon = GetPlayerWeaponSlot(entity, tmpAttribute[_Var4]);
					
					new Float:fValue = GetEntPropFloat(iWeapon, Prop_Send, var3_string);
					
					if (fValue < g_iClient_SoundPlayed_Attributes[entity][i][_Value])
					{
						continue;
					}
				}

				if (tmpAttribute[_Var5] != NULL_VAR)
				{
					TF2_RemoveCondition(iOtherPlayer, TFCond:tmpAttribute[_Var5]);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

//Internal Functions

#if (SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 6)
public AddCondition_Delayed (any:data)
#else
public AddCondition_Delayed (Handle:timer, any:data)
#endif
{
	TF2_AddCondition(ReadPackCell(data), ReadPackCell(data), ReadPackFloat(data), ReadPackCell(data));
	
	CloseHandle(data);
}

#if (SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 6)
public RemoveCondition_Delayed (any:data)
#else
public RemoveCondition_Delayed (Handle:timer, any:data)
#endif
{
	TF2_RemoveCondition(ReadPackCell(data), ReadPackCell(data));
	
	CloseHandle(data);
}

CheckStorage ()
{
	static bool:g_bStorageReady = false;
	
	if (! g_bStorageReady)
	{
		g_AttributeTrie = CreateTrie();
		g_hStringStore = CreateArray(64);
		
		g_bStorageReady = true;
	}
}

//Native Functions

public Native_Esc_LoadCustomAttributeFile (Handle:plugin, numParams)
{
	CheckStorage();

	new iLen;
	GetNativeStringLength(1, iLen);
	
	if (iLen <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid filename to passed to function.");
	}
	
	decl String:FilePath[iLen + 1];
	GetNativeString(1, FilePath, iLen + 1);
	
	new Handle:hKeyValues = CreateKeyValues("custom_attributes");
	
	if (! FileToKeyValues(hKeyValues, FilePath))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "File \"%s\" does not exist.", FilePath);
	}
	
	KvGotoFirstSubKey(hKeyValues);
	
	do
	{
		new tmpAttribute[AttributeInfo];
	
		decl String:SectionName[64];
		KvGetSectionName(hKeyValues, SectionName, sizeof(SectionName));
		
		decl String:EventName[64];
		KvGetString(hKeyValues, "event", EventName, sizeof(EventName));
		
		decl String:ActionName[64];
		KvGetString(hKeyValues, "action", ActionName, sizeof(ActionName));
		
		tmpAttribute[_Event] = EventStringToEnum(EventName);
		tmpAttribute[_Action] = ActionStringToEnum(ActionName);
		
		if (tmpAttribute[_Event] == NULL_EVENT)
		{
			LogError("Attribute \"%s\" hooks into invalid event \"%s\".", SectionName, EventName);
			
			continue;
		}
		
		if (tmpAttribute[_Action] == NULL_ACTION)
		{
			LogError("Attribute \"%s\" does invalid action \"%s\".", SectionName, ActionName);
			
			continue;
		}
		
		if (! EventSupportsAction(tmpAttribute[_Event], tmpAttribute[_Action]))
		{
			LogError("Attribute \"%s\" attempting to use an upsupported action (\"%s\") on event \"%s\".", SectionName, ActionName, EventName);
			
			continue;
		}
		
		decl String:vars[6][64];
		
		KvGetString(hKeyValues, "var1", vars[1], 64);
		KvGetString(hKeyValues, "var2", vars[2], 64);
		KvGetString(hKeyValues, "var3", vars[3], 64);
		KvGetString(hKeyValues, "var4", vars[4], 64);
		KvGetString(hKeyValues, "var5", vars[5], 64);
		
		for (new i = 1; i <= 5; i ++)
		{
			if (vars[i][0] == '$')
			{
				RemoveCharFromString(0, vars[i]);
				
				tmpAttribute[_:_Action + i] = PushArrayString(g_hStringStore, vars[i]);
				
				continue;
			}
		
			tmpAttribute[_:_Action + i] = VarStringToValue(vars[i]);
			
		}
		
		
		//LogMessage("Attribute - %s Event - %s Action - %s Var1 - %i Var2 - %i Var3 - %i Var4 - %i Var5 - %i", SectionName, EventName, ActionName, tmpAttribute[_Var1], tmpAttribute[_Var2], tmpAttribute[_Var3], tmpAttribute[_Var4], tmpAttribute[_Var5]);
		
		SetTrieArray(g_AttributeTrie, SectionName, tmpAttribute[0], sizeof(tmpAttribute));
		
	}	while(KvGotoNextKey(hKeyValues));
	
	CloseHandle(hKeyValues);
}

public Native_Esc_ApplyCustomAttribute (Handle:plugin, numParams)
{
	CheckStorage();

	new client = GetNativeCell(1);
	new iAttribute = GetNativeCell(2);
	new Float:fValue = GetNativeCell(3);
	new bool:bReplace = GetNativeCell(4);
	
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index \"%i\" passed to function.", client);
	}
	else if (! IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index \"%i\" is not ingame.", client);
	}

	
	decl String:Attribute[8];
	IntToString(iAttribute, Attribute, sizeof(Attribute));
	
	decl tmpAttribute[AttributeInfo];
	if (! GetTrieArray(g_AttributeTrie, Attribute, tmpAttribute[0], sizeof(tmpAttribute)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Attribute index \"%i\" is invalid.", client);
	}
	
	switch (tmpAttribute[_Event])
	{
		case PLAYER_DEATH:
		{
			if (bReplace)
			{
				if (ReplaceAttributeValue(g_iClient_PlayerDeath_Attributes[client], g_iClient_PlayerDeath_AttributeCount[client], iAttribute, fValue))
				{
					return;
				}
			}
		
			if (g_iClient_PlayerDeath_AttributeCount[client] == (MAX_ATTRIBUTES - 1))
			{
				ThrowNativeError(SP_ERROR_NATIVE, "Client \"%i\" is at their limit on player_death attributes.", client);	
			}

			g_iClient_PlayerDeath_Attributes[client][g_iClient_PlayerDeath_AttributeCount[client]][_Attribute] = iAttribute;
			g_iClient_PlayerDeath_Attributes[client][g_iClient_PlayerDeath_AttributeCount[client]][_Value] = fValue;

			g_iClient_PlayerDeath_AttributeCount[client] ++;
		}
		case PLAYER_HURT:
		{
			if (bReplace)
			{
				if (ReplaceAttributeValue(g_iClient_PlayerHurt_Attributes[client], g_iClient_PlayerHurt_AttributeCount[client], iAttribute, fValue))
				{
					return;
				}
			}

			if (g_iClient_PlayerHurt_AttributeCount[client] == (MAX_ATTRIBUTES - 1))
			{
				ThrowNativeError(SP_ERROR_NATIVE, "Client \"%i\" is at their limit on player_hurt attributes.", client);	
			}
		
			g_iClient_PlayerHurt_Attributes[client][g_iClient_PlayerHurt_AttributeCount[client]][_Attribute] = iAttribute;
			g_iClient_PlayerHurt_Attributes[client][g_iClient_PlayerHurt_AttributeCount[client]][_Value] = fValue;
			
			g_iClient_PlayerHurt_AttributeCount[client] ++;		
		}
		case PLAYER_HURT_SELF:
		{
			if (bReplace)
			{
				if (ReplaceAttributeValue(g_iClient_PlayerHurtSelf_Attributes[client], g_iClient_PlayerHurtSelf_AttributeCount[client], iAttribute, fValue))
				{
					return;
				}
			}

			if (g_iClient_PlayerHurtSelf_AttributeCount[client] == (MAX_ATTRIBUTES - 1))
			{
				ThrowNativeError(SP_ERROR_NATIVE, "Client \"%i\" is at their limit on player_hurt_self attributes.", client);	
			}
		
			g_iClient_PlayerHurtSelf_Attributes[client][g_iClient_PlayerHurtSelf_AttributeCount[client]][_Attribute] = iAttribute;
			g_iClient_PlayerHurtSelf_Attributes[client][g_iClient_PlayerHurtSelf_AttributeCount[client]][_Value] = fValue;
			
			g_iClient_PlayerHurtSelf_AttributeCount[client] ++;				
		}
		case PLAYER_JARATED:
		{
			if (bReplace)
			{
				if (ReplaceAttributeValue(g_iClient_PlayerJarated_Attributes[client], g_iClient_PlayerJarated_AttributeCount[client], iAttribute, fValue))
				{
					return;
				}
			}

			if (g_iClient_PlayerJarated_AttributeCount[client] == (MAX_ATTRIBUTES - 1))
			{
				ThrowNativeError(SP_ERROR_NATIVE, "Client \"%i\" is at their limit on player_jarated attributes.", client);	
			}
		
			g_iClient_PlayerJarated_Attributes[client][g_iClient_PlayerJarated_AttributeCount[client]][_Attribute] = iAttribute;
			g_iClient_PlayerJarated_Attributes[client][g_iClient_PlayerJarated_AttributeCount[client]][_Value] = fValue;
			
			g_iClient_PlayerJarated_AttributeCount[client] ++;		
		}
		case PLAYER_ARROWED:
		{
			if (bReplace)
			{
				if (ReplaceAttributeValue(g_iClient_PlayerArrowed_Attributes[client], g_iClient_PlayerArrowed_AttributeCount[client], iAttribute, fValue))
				{
					return;
				}
			}

			if (g_iClient_PlayerArrowed_AttributeCount[client] == (MAX_ATTRIBUTES - 1))
			{
				ThrowNativeError(SP_ERROR_NATIVE, "Client \"%i\" is at their limit on player_arrowed attributes.", client);	
			}
		
			g_iClient_PlayerArrowed_Attributes[client][g_iClient_PlayerArrowed_AttributeCount[client]][_Attribute] = iAttribute;
			g_iClient_PlayerArrowed_Attributes[client][g_iClient_PlayerArrowed_AttributeCount[client]][_Value] = fValue;
			
			g_iClient_PlayerArrowed_AttributeCount[client] ++;	
		}
		case SOUND_PLAYED:
		{
			if (bReplace)
			{
				if (ReplaceAttributeValue(g_iClient_SoundPlayed_Attributes[client], g_iClient_SoundPlayed_AttributeCount[client], iAttribute, fValue))
				{
					return;
				}
			}

			if (g_iClient_SoundPlayed_AttributeCount[client] == (MAX_ATTRIBUTES - 1))
			{
				ThrowNativeError(SP_ERROR_NATIVE, "Client \"%i\" is at their limit on sound_played attributes.", client);	
			}
		
			g_iClient_SoundPlayed_Attributes[client][g_iClient_SoundPlayed_AttributeCount[client]][_Attribute] = iAttribute;
			g_iClient_SoundPlayed_Attributes[client][g_iClient_SoundPlayed_AttributeCount[client]][_Value] = fValue;
			
			g_iClient_SoundPlayed_AttributeCount[client] ++;	
		}
	}
	

}

public Native_Esc_RemoveCustomAttribute (Handle:plugin, numParams)
{
	CheckStorage();

	new client = GetNativeCell(1);
	new iAttribute = GetNativeCell(2);

	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index \"%i\" passed to function.", client);
	}
	else if (! IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index \"%i\" is not ingame.", client);
	}

	decl String:Attribute[8];
	IntToString(iAttribute, Attribute, sizeof(Attribute));

	decl tmpAttribute[AttributeInfo];
	if (! GetTrieArray(g_AttributeTrie, Attribute, tmpAttribute[0], sizeof(tmpAttribute)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Attribute index \"%i\" is invalid.", client);
	}

	switch (tmpAttribute[_Event])
	{
		case PLAYER_DEATH:
		{
			RemoveAttribute(g_iClient_PlayerDeath_Attributes[client], g_iClient_PlayerDeath_AttributeCount[client], iAttribute);
		}
		case PLAYER_HURT:
		{
			RemoveAttribute(g_iClient_PlayerHurt_Attributes[client], g_iClient_PlayerHurt_AttributeCount[client], iAttribute);
		}
		case PLAYER_HURT_SELF:
		{
			RemoveAttribute(g_iClient_PlayerHurtSelf_Attributes[client], g_iClient_PlayerHurtSelf_AttributeCount[client], iAttribute);			
		}
		case PLAYER_JARATED:
		{
			RemoveAttribute(g_iClient_PlayerJarated_Attributes[client], g_iClient_PlayerJarated_AttributeCount[client], iAttribute);
		}
		case PLAYER_ARROWED:
		{
			RemoveAttribute(g_iClient_PlayerArrowed_Attributes[client], g_iClient_PlayerArrowed_AttributeCount[client], iAttribute);
		}
		case SOUND_PLAYED:
		{
			RemoveAttribute(g_iClient_SoundPlayed_Attributes[client], g_iClient_SoundPlayed_AttributeCount[client], iAttribute);
		}
	}
}

public Native_Esc_RemoveCustomAttributes (Handle:plugin, numParams)
{
	CheckStorage();

	new client = GetNativeCell(1);

	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index \"%i\" passed to function.", client);
	}
	else if (! IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index \"%i\" is not ingame.", client);
	}
	
	for (new i = 0; i < g_iClient_PlayerDeath_AttributeCount[client]; i ++)
	{
		g_iClient_PlayerDeath_Attributes[client][i][0] = 0;
		g_iClient_PlayerDeath_Attributes[client][i][1] = 0;
	}
	
	g_iClient_PlayerDeath_AttributeCount[client] = 0;
	
	
	for (new i = 0; i < g_iClient_PlayerHurt_AttributeCount[client]; i ++)
	{
		g_iClient_PlayerHurt_Attributes[client][i][0] = 0;
		g_iClient_PlayerHurt_Attributes[client][i][1] = 0;
	}
	
	g_iClient_PlayerHurt_AttributeCount[client] = 0;
	
	for (new i = 0; i < g_iClient_PlayerHurtSelf_AttributeCount[client]; i ++)
	{
		g_iClient_PlayerHurtSelf_Attributes[client][i][0] = 0;
		g_iClient_PlayerHurtSelf_Attributes[client][i][1] = 0;
	}
	
	g_iClient_PlayerHurtSelf_AttributeCount[client] = 0;
	
	for (new i = 0; i < g_iClient_PlayerJarated_AttributeCount[client]; i ++)
	{
		g_iClient_PlayerJarated_Attributes[client][i][0] = 0;
		g_iClient_PlayerJarated_Attributes[client][i][1] = 0;
	}
	
	g_iClient_PlayerJarated_AttributeCount[client] = 0;
	
	for (new i = 0; i < g_iClient_PlayerArrowed_AttributeCount[client]; i ++)
	{
		g_iClient_PlayerArrowed_Attributes[client][i][0] = 0;
		g_iClient_PlayerArrowed_Attributes[client][i][1] = 0;
	}
	
	g_iClient_PlayerArrowed_AttributeCount[client] = 0;
	
	for (new i = 0; i < g_iClient_SoundPlayed_AttributeCount[client]; i ++)
	{
		g_iClient_SoundPlayed_Attributes[client][i][0] = 0;
		g_iClient_SoundPlayed_Attributes[client][i][1] = 0;
	}
	
	g_iClient_SoundPlayed_AttributeCount[client] = 0;
}


//Attribute Utility

bool:ReplaceAttributeValue (Attributes[MAX_ATTRIBUTES][AppliedAttribute], iCount, iAttribute, Float:fValue)
{
	for (new iIndex; iIndex < iCount; iIndex ++)
	{
		if (Attributes[iIndex][_Attribute] == iAttribute)
		{
			Attributes[iIndex][_Value] = fValue;
			
			return true;
		}
	}
	
	return false;
}

RemoveAttribute (Attributes[MAX_ATTRIBUTES][AppliedAttribute], &iCount, iAttribute)
{
	for (new iIndex; iIndex < iCount; iIndex ++)
	{
		if (Attributes[iIndex][_Attribute] == iAttribute)
		{
			for (new iIndex2 = (iIndex + 1); iIndex2 < iCount; iIndex2 ++)
			{
				Attributes[iIndex2 - 1][_Attribute] = Attributes[iIndex2][_Attribute];
				Attributes[iIndex2 - 1][_Value] = Attributes[iIndex2][_Value];
			}
			
			iCount--;
			
			return;
		}
	}
}


//Utility

RemoveCharFromString(iChar, String:string[])
{
	new iIndex = iChar;
	
	while (string[iIndex] != '\0')
	{
		string[iIndex] = string[iIndex + 1];
	
		iIndex ++;
	}
}

ActionTypes:ActionStringToEnum (const String:action[])
{
	if (StrEqual("health_on_kill", action, false))
	{	
		return HEALTH_ON_KILL;
	}
	else if (StrEqual("mult_damage", action, false))
	{	
		return MULT_DAMAGE;
	}
	else if (StrEqual("mult_world_damage", action, false))
	{
		return MULT_WORLD_DAMAGE;
	}
	else if (StrEqual("mult_damage_custom", action, false))
	{
		return MULT_DAMAGE_CUSTOM;
	}
	else if (StrEqual("mult_damage_vs_cond", action, false))
	{
		return MULT_DAMAGE_VS_COND;
	}
	else if (StrEqual("mult_damage_vs_cond_and_active_weapon", action, false))
	{
		return MULT_DAMAGE_VS_COND_AND_ACTIVE_WEAPON;
	}
	else if (StrEqual("mult_damage_vs_entflag", action, false))
	{
		return MULT_DAMAGE_VS_ENTFLAG;
	}
	else if(StrEqual("mult_damage_vs_flag", action, false))
	{
		return MULT_DAMAGE_VS_FLAG;
	}
	else if (StrEqual("apply_condition", action, false))
	{
		return APPLY_CONDITION;
	}
	else if (StrEqual("apply_stunflags", action, false))
	{
		return APPLY_STUNFLAGS;
	}
	else if (StrEqual("reapply_condition", action, false))
	{
		return REAPPLY_CONDITION;
	}
	else if (StrEqual("remove_condition_delayed", action, false))
	{
		return REMOVE_CONDITION_DELAYED;
	}
	else if (StrEqual("negate_damage", action, false))
	{
		return NEGATE_DAMAGE;
	}
	else if (StrEqual("negate_damage_percent", action, false))
	{
		return NEGATE_DAMAGE_PERCENT;
	}	
	else if (StrEqual("crit_vs_conds", action, false))
	{
		return CRIT_VS_CONDS;
	}
	else if (StrEqual("no_crits_vs_not_conds", action, false))
	{
		return NO_CRITS_VS_NOT_CONDS;
	}
	else if (StrEqual("ignite_player", action, false))
	{
		return IGNITE_PLAYER;
	}
	else if (StrEqual("remove_conditions", action, false))
	{
		return REMOVE_CONDITIONS;
	}
	else if (StrEqual("trace_and_remove_conds", action, false))
	{
		return TRACE_AND_REMOVE_CONDS;
	}
	else if (StrEqual("crit_to_minicrit", action, false))
	{
		return CRIT_TO_MINICRIT;
	}
	else if (StrEqual("add_cond_on_kill", action, false))
	{
		return ADD_COND_ON_KILL;
	}
	
	return NULL_ACTION;
}

EventTypes:EventStringToEnum (const String:event[])
{
	if (StrEqual("player_death", event, false))
	{	
		return PLAYER_DEATH;
	}
	else if (StrEqual("player_hurt", event, false))
	{	
		return PLAYER_HURT;
	}
	else if(StrEqual("player_hurt_self", event, false))
	{
		return PLAYER_HURT_SELF;
	}
	else if (StrEqual("player_jarated", event, false))
	{
		return PLAYER_JARATED;
	}
	else if (StrEqual("player_arrowed", event, false))
	{
		return PLAYER_ARROWED;
	}
	else if (StrEqual("sound_played", event, false))
	{
		return SOUND_PLAYED;
	}
	
	return NULL_EVENT;
}

bool:EventSupportsAction (EventTypes:iEvent, ActionTypes:iAction)
{
	switch (iEvent)
	{
		case PLAYER_DEATH:
		{
			switch (iAction)
			{
				case HEALTH_ON_KILL, ADD_COND_ON_KILL:
				{
					return true;
				}
			}
		}
		case PLAYER_HURT:
		{
			switch (iAction)
			{
				case MULT_DAMAGE, MULT_DAMAGE_VS_COND, MULT_DAMAGE_VS_FLAG, MULT_DAMAGE_VS_ENTFLAG, APPLY_CONDITION, REAPPLY_CONDITION, REMOVE_CONDITION_DELAYED, CRIT_VS_CONDS, NO_CRITS_VS_NOT_CONDS, IGNITE_PLAYER, CRIT_TO_MINICRIT:
				{
					return true;
				}
			}
		}
		case PLAYER_HURT_SELF:
		{
			switch (iAction)
			{
				case MULT_WORLD_DAMAGE, MULT_DAMAGE_VS_COND, MULT_DAMAGE_VS_COND_AND_ACTIVE_WEAPON, MULT_DAMAGE_VS_FLAG, MULT_DAMAGE_VS_ENTFLAG, MULT_DAMAGE_CUSTOM, NEGATE_DAMAGE, NEGATE_DAMAGE_PERCENT:
				{
					return true;
				}
			}
		}
		case PLAYER_JARATED:
		{
			switch (iAction)
			{
				case APPLY_STUNFLAGS, REAPPLY_CONDITION:
				{
					return true;
				}
			}
		}
		case PLAYER_ARROWED:
		{
			switch (iAction)
			{
				case REMOVE_CONDITIONS:
				{
					return true;
				}
			}
		}
		case SOUND_PLAYED:
		{
			switch (iAction)
			{
				case TRACE_AND_REMOVE_CONDS:
				{
					return true;
				}
			}
		}
	}

	return false;
}

//Pay no attention to the massive string comparision block below.
any:VarStringToValue (const String:var[])
{

	if (StrEqual("true", var, false))
	{	
		return 1;
	}
	else if (StrEqual("false", var, false))
	{	
		return 0;
	}
	else if (StrEqual("NULL", var, false))
	{
		return NULL_VAR;
	}
	/* Entity Flags */
	else if (StrEqual("FL_ONGROUND", var, false))
	{
		return FL_ONGROUND;
	}
	else if (StrEqual("FL_DUCKING", var, false))
	{
		return FL_DUCKING;
	}
	else if (StrEqual("FL_WATERJUMP", var, false))
	{
		return FL_WATERJUMP;
	}
	else if (StrEqual("FL_ONTRAIN", var, false))
	{
		return FL_ONTRAIN;
	}
	else if (StrEqual("FL_INRAIN", var, false))
	{
		return FL_INRAIN;
	}
	else if (StrEqual("FL_FROZEN", var, false))
	{
		return FL_FROZEN;
	}
	else if (StrEqual("FL_ATCONTROLS", var, false))
	{
		return FL_ATCONTROLS;
	}
	else if (StrEqual("FL_CLIENT", var, false))
	{
		return FL_CLIENT;
	}
	else if (StrEqual("FL_FAKECLIENT", var, false))
	{
		return FL_FAKECLIENT;
	}
	else if (StrEqual("FL_INWATER", var, false))
	{
		return FL_INWATER;
	}
	else if (StrEqual("FL_FLY", var, false))
	{
		return FL_FLY;
	}
	else if (StrEqual("FL_SWIM", var, false))
	{
		return FL_SWIM;
	}
	else if (StrEqual("FL_CONVEYOR", var, false))
	{
		return FL_CONVEYOR;
	}
	else if (StrEqual("FL_NPC", var, false))
	{
		return FL_NPC;
	}
	else if (StrEqual("FL_GODMODE", var, false))
	{
		return FL_GODMODE;
	}
	else if (StrEqual("FL_NOTARGET", var, false))
	{
		return FL_NOTARGET;
	}
	else if (StrEqual("FL_AIMTARGET", var, false))
	{
		return FL_AIMTARGET;
	}
	else if (StrEqual("FL_PARTIALGROUND", var, false))
	{
		return FL_PARTIALGROUND;
	}
	else if (StrEqual("FL_STATICPROP", var, false))
	{
		return FL_STATICPROP;
	}
	else if (StrEqual("FL_GRAPHED", var, false))
	{
		return FL_GRAPHED;
	}
	else if (StrEqual("FL_GRENADE", var, false))
	{
		return FL_GRENADE;
	}
	else if (StrEqual("FL_STEPMOVEMENT", var, false))
	{
		return FL_STEPMOVEMENT;
	}
	else if (StrEqual("FL_DONTTOUCH", var, false))
	{
		return FL_DONTTOUCH;
	}
	else if (StrEqual("FL_BASEVELOCITY", var, false))
	{
		return FL_BASEVELOCITY;
	}
	else if (StrEqual("FL_WORLDBRUSH", var, false))
	{
		return FL_WORLDBRUSH;
	}
	else if (StrEqual("FL_OBJECT", var, false))
	{
		return FL_OBJECT;
	}
	else if (StrEqual("FL_KILLME", var, false))
	{
		return FL_KILLME;
	}
	else if (StrEqual("FL_ONFIRE", var, false))
	{
		return FL_ONFIRE;
	}
	else if (StrEqual("FL_DISSOLVING", var, false))
	{
		return FL_DISSOLVING;
	}
	else if (StrEqual("FL_TRANSRAGDOLL", var, false))
	{
		return FL_TRANSRAGDOLL;
	}
	else if (StrEqual("FL_UNBLOCKABLE_BY_PLAYER", var, false))
	{
		return FL_UNBLOCKABLE_BY_PLAYER;
	}
	else if (StrEqual("FL_FREEZING", var, false))
	{
		return FL_FREEZING;
	}
	else if (StrEqual("FL_EP2V_UNKNOWN1", var, false))
	{
		return FL_EP2V_UNKNOWN1;
	}
	/* Damage Flags */
	else if (StrEqual("DMG_GENERIC", var, false))
	{
		return DMG_GENERIC;
	}
	else if (StrEqual("DMG_CRUSH", var, false))
	{
		return DMG_CRUSH;
	}
	else if (StrEqual("DMG_BULLET", var, false))
	{
		return DMG_BULLET;
	}
	else if (StrEqual("DMG_BULLET", var, false))
	{
		return DMG_BULLET;
	}
	else if (StrEqual("DMG_SLASH", var, false))
	{
		return DMG_SLASH;
	}
	else if (StrEqual("DMG_BURN", var, false))
	{
		return DMG_BURN;
	}
	else if (StrEqual("DMG_VEHICLE", var, false))
	{
		return DMG_VEHICLE;
	}
	else if (StrEqual("DMG_FALL", var, false))
	{
		return DMG_FALL;
	}
	else if (StrEqual("DMG_BLAST", var, false))
	{
		return DMG_BLAST;
	}
	else if (StrEqual("DMG_CLUB", var, false))
	{
		return DMG_CLUB;
	}
	else if (StrEqual("DMG_SHOCK", var, false))
	{
		return DMG_SHOCK;
	}
	else if (StrEqual("DMG_SONIC", var, false))
	{
		return DMG_SONIC;
	}
	else if (StrEqual("DMG_ENERGYBEAM", var, false))
	{
		return DMG_ENERGYBEAM;
	}
	else if (StrEqual("DMG_PREVENT_PHYSICS_FORCE", var, false))
	{
		return DMG_PREVENT_PHYSICS_FORCE;
	}
	else if (StrEqual("DMG_NEVERGIB", var, false))
	{
		return DMG_NEVERGIB;
	}
	else if (StrEqual("DMG_ALWAYSGIB", var, false))
	{
		return DMG_ALWAYSGIB;
	}
	else if (StrEqual("DMG_DROWN", var, false))
	{
		return DMG_DROWN;
	}
	else if (StrEqual("DMG_PARALYZE", var, false))
	{
		return DMG_PARALYZE;
	}
	else if (StrEqual("DMG_NERVEGAS", var, false))
	{
		return DMG_NERVEGAS;
	}
	else if (StrEqual("DMG_POISON", var, false))
	{
		return DMG_POISON;
	}
	else if (StrEqual("DMG_RADIATION", var, false))
	{
		return DMG_RADIATION;
	}
	else if (StrEqual("DMG_DROWNRECOVER", var, false))
	{
		return DMG_DROWNRECOVER;
	}
	else if (StrEqual("DMG_ACID", var, false))
	{
		return DMG_ACID;
	}
	else if (StrEqual("DMG_SLOWBURN", var, false))
	{
		return DMG_SLOWBURN;
	}
	else if (StrEqual("DMG_REMOVENORAGDOLL", var, false))
	{
		return DMG_REMOVENORAGDOLL;
	}
	else if (StrEqual("DMG_PHYSGUN", var, false))
	{
		return DMG_PHYSGUN;
	}
	else if (StrEqual("DMG_PLASMA", var, false))
	{
		return DMG_PLASMA;
	}
	else if (StrEqual("DMG_AIRBOAT", var, false))
	{
		return DMG_AIRBOAT;
	}
	else if (StrEqual("DMG_DISSOLVE", var, false))
	{
		return DMG_DISSOLVE;
	}
	else if (StrEqual("DMG_BLAST_SURFACE", var, false))
	{
		return DMG_BLAST_SURFACE;
	}
	else if (StrEqual("DMG_DIRECT", var, false))
	{
		return DMG_DIRECT;
	}
	else if (StrEqual("DMG_BUCKSHOT", var, false))
	{
		return DMG_BUCKSHOT;
	}
	else if (StrEqual("DMG_CRIT", var, false))
	{
		return DMG_CRIT;
	}
	/* TF2 Damage Customs */
	else if (StrEqual("TF_CUSTOM_HEADSHOT", var, false))
	{	
		return TF_CUSTOM_HEADSHOT;
	}
	else if (StrEqual("TF_CUSTOM_BACKSTAB", var, false))
	{	
		return TF_CUSTOM_BACKSTAB;
	}
	else if (StrEqual("TF_CUSTOM_BURNING", var, false))
	{	
		return TF_CUSTOM_BURNING;
	}
	else if (StrEqual("TF_CUSTOM_WRENCH_FIX", var, false))
	{	
		return TF_CUSTOM_WRENCH_FIX;
	}
	else if (StrEqual("TF_CUSTOM_MINIGUN", var, false))
	{	
		return TF_CUSTOM_MINIGUN;
	}
	else if (StrEqual("TF_CUSTOM_SUICIDE", var, false))
	{	
		return TF_CUSTOM_SUICIDE;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_HADOUKEN", var, false))
	{	
		return TF_CUSTOM_TAUNT_HADOUKEN;
	}
	else if (StrEqual("TF_CUSTOM_BURNING_FLARE", var, false))
	{	
		return TF_CUSTOM_BURNING_FLARE;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_HIGH_NOON", var, false))
	{	
		return TF_CUSTOM_TAUNT_HIGH_NOON;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_GRAND_SLAM", var, false))
	{	
		return TF_CUSTOM_TAUNT_GRAND_SLAM;
	}
	else if (StrEqual("TF_CUSTOM_PENETRATE_MY_TEAM", var, false))
	{	
		return TF_CUSTOM_PENETRATE_MY_TEAM;
	}
	else if (StrEqual("TF_CUSTOM_PENETRATE_ALL_PLAYERS", var, false))
	{	
		return TF_CUSTOM_PENETRATE_ALL_PLAYERS;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_FENCING", var, false))
	{	
		return TF_CUSTOM_TAUNT_FENCING;
	}
	else if (StrEqual("TF_CUSTOM_PENETRATE_HEADSHOT", var, false))
	{	
		return TF_CUSTOM_PENETRATE_HEADSHOT;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_ARROW_STAB", var, false))
	{	
		return TF_CUSTOM_TAUNT_ARROW_STAB;
	}
	else if (StrEqual("TF_CUSTOM_TELEFRAG", var, false))
	{	
		return TF_CUSTOM_TELEFRAG;
	}
	else if (StrEqual("TF_CUSTOM_BURNING_ARROW", var, false))
	{	
		return TF_CUSTOM_BURNING_ARROW;
	}
	else if (StrEqual("TF_CUSTOM_FLYINGBURN", var, false))
	{	
		return TF_CUSTOM_FLYINGBURN;
	}
	else if (StrEqual("TF_CUSTOM_PUMPKIN_BOMB", var, false))
	{	
		return TF_CUSTOM_PUMPKIN_BOMB;
	}
	else if (StrEqual("TF_CUSTOM_DECAPITATION", var, false))
	{	
		return TF_CUSTOM_DECAPITATION;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_GRENADE", var, false))
	{	
		return TF_CUSTOM_TAUNT_GRENADE;
	}
	else if (StrEqual("TF_CUSTOM_BASEBALL", var, false))
	{	
		return TF_CUSTOM_BASEBALL;
	}
	else if (StrEqual("TF_CUSTOM_CHARGE_IMPACT", var, false))
	{	
		return TF_CUSTOM_CHARGE_IMPACT;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_BARBARIAN_SWING", var, false))
	{	
		return TF_CUSTOM_TAUNT_BARBARIAN_SWING;
	}
	else if (StrEqual("TF_CUSTOM_AIR_STICKY_BURST", var, false))
	{	
		return TF_CUSTOM_AIR_STICKY_BURST;
	}
	else if (StrEqual("TF_CUSTOM_DEFENSIVE_STICKY", var, false))
	{	
		return TF_CUSTOM_DEFENSIVE_STICKY;
	}
	else if (StrEqual("TF_CUSTOM_PICKAXE", var, false))
	{	
		return TF_CUSTOM_PICKAXE;
	}
	else if (StrEqual("TF_CUSTOM_ROCKET_DIRECTHIT", var, false))
	{	
		return TF_CUSTOM_ROCKET_DIRECTHIT;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_UBERSLICE", var, false))
	{	
		return TF_CUSTOM_TAUNT_UBERSLICE;
	}
	else if (StrEqual("TF_CUSTOM_PLAYER_SENTRY", var, false))
	{	
		return TF_CUSTOM_PLAYER_SENTRY;
	}
	else if (StrEqual("TF_CUSTOM_STANDARD_STICKY", var, false))
	{	
		return TF_CUSTOM_STANDARD_STICKY;
	}
	else if (StrEqual("TF_CUSTOM_SHOTGUN_REVENGE_CRIT", var, false))
	{	
		return TF_CUSTOM_SHOTGUN_REVENGE_CRIT;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_ENGINEER_SMASH", var, false))
	{	
		return TF_CUSTOM_TAUNT_ENGINEER_SMASH;
	}
	else if (StrEqual("TF_CUSTOM_BLEEDING", var, false))
	{	
		return TF_CUSTOM_BLEEDING;
	}
	else if (StrEqual("TF_CUSTOM_GOLD_WRENCH", var, false))
	{	
		return TF_CUSTOM_GOLD_WRENCH;
	}
	else if (StrEqual("TF_CUSTOM_CARRIED_BUILDING", var, false))
	{	
		return TF_CUSTOM_CARRIED_BUILDING;
	}
	else if (StrEqual("TF_CUSTOM_COMBO_PUNCH", var, false))
	{	
		return TF_CUSTOM_COMBO_PUNCH;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_ENGINEER_ARM", var, false))
	{	
		return TF_CUSTOM_TAUNT_ENGINEER_ARM;
	}
	else if (StrEqual("TF_CUSTOM_FISH_KILL", var, false))
	{	
		return TF_CUSTOM_FISH_KILL;
	}
	else if (StrEqual("TF_CUSTOM_TRIGGER_HURT", var, false))
	{	
		return TF_CUSTOM_TRIGGER_HURT;
	}
	else if (StrEqual("TF_CUSTOM_DECAPITATION_BOSS", var, false))
	{	
		return TF_CUSTOM_DECAPITATION_BOSS;
	}
	else if (StrEqual("TF_CUSTOM_STICKBOMB_EXPLOSION", var, false))
	{	
		return TF_CUSTOM_STICKBOMB_EXPLOSION;
	}
	else if (StrEqual("TF_CUSTOM_AEGIS_ROUND", var, false))
	{	
		return TF_CUSTOM_AEGIS_ROUND;
	}
	else if (StrEqual("TF_CUSTOM_FLARE_EXPLOSION", var, false))
	{	
		return TF_CUSTOM_FLARE_EXPLOSION;
	}
	else if (StrEqual("TF_CUSTOM_BOOTS_STOMP", var, false))
	{	
		return TF_CUSTOM_BOOTS_STOMP;
	}
	else if (StrEqual("TF_CUSTOM_PLASMA", var, false))
	{	
		return TF_CUSTOM_PLASMA;
	}
	else if (StrEqual("TF_CUSTOM_PLASMA_CHARGED", var, false))
	{	
		return TF_CUSTOM_PLASMA_CHARGED;
	}
	else if (StrEqual("TF_CUSTOM_PLASMA_GIB", var, false))
	{	
		return TF_CUSTOM_PLASMA_GIB;
	}
	else if (StrEqual("TF_CUSTOM_PRACTICE_STICKY", var, false))
	{	
		return TF_CUSTOM_PRACTICE_STICKY;
	}
	else if (StrEqual("TF_CUSTOM_EYEBALL_ROCKET", var, false))
	{	
		return TF_CUSTOM_EYEBALL_ROCKET;
	}
	else if (StrEqual("TF_CUSTOM_HEADSHOT_DECAPITATION", var, false))
	{	
		return TF_CUSTOM_HEADSHOT_DECAPITATION;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_ARMAGEDDON", var, false))
	{	
		return TF_CUSTOM_TAUNT_ARMAGEDDON;
	}
	else if (StrEqual("TF_CUSTOM_FLARE_PELLET", var, false))
	{	
		return TF_CUSTOM_FLARE_PELLET;
	}
	else if (StrEqual("TF_CUSTOM_CLEAVER", var, false))
	{	
		return TF_CUSTOM_CLEAVER;
	}
	else if (StrEqual("TF_CUSTOM_CLEAVER_CRIT", var, false))
	{	
		return TF_CUSTOM_CLEAVER_CRIT;
	}
	else if (StrEqual("TF_CUSTOM_SAPPER_RECORDER_DEATH", var, false))
	{	
		return TF_CUSTOM_SAPPER_RECORDER_DEATH;
	}
	else if (StrEqual("TF_CUSTOM_MERASMUS_PLAYER_BOMB", var, false))
	{	
		return TF_CUSTOM_MERASMUS_PLAYER_BOMB;
	}
	else if (StrEqual("TF_CUSTOM_MERASMUS_GRENADE", var, false))
	{	
		return TF_CUSTOM_MERASMUS_GRENADE;
	}
	else if (StrEqual("TF_CUSTOM_MERASMUS_ZAP", var, false))
	{	
		return TF_CUSTOM_MERASMUS_ZAP;
	}
	else if (StrEqual("TF_CUSTOM_MERASMUS_DECAPITATION", var, false))
	{	
		return TF_CUSTOM_MERASMUS_DECAPITATION;
	}
	else if (StrEqual("TF_CUSTOM_CANNONBALL_PUSH", var, false))
	{	
		return TF_CUSTOM_CANNONBALL_PUSH;
	}
	else if (StrEqual("TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF", var, false))
	{	
		return TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF;
	}
	/* TF2 Conditions */
	else if (StrEqual("TFCond_Slowed", var, false))
	{	
		return TFCond_Slowed;
	}
	else if (StrEqual("TFCond_Zoomed", var, false))
	{	
		return TFCond_Zoomed;
	}
	else if (StrEqual("TFCond_Disguising", var, false))
	{	
		return TFCond_Disguising;
	}
	else if (StrEqual("TFCond_Disguised", var, false))
	{	
		return TFCond_Disguised;
	}
	else if (StrEqual("TFCond_Cloaked", var, false))
	{	
		return TFCond_Cloaked;
	}
	else if (StrEqual("TFCond_Ubercharged", var, false))
	{	
		return TFCond_Ubercharged;
	}
	else if (StrEqual("TFCond_TeleportedGlow", var, false))
	{	
		return TFCond_TeleportedGlow;
	}
	else if (StrEqual("TFCond_Taunting", var, false))
	{	
		return TFCond_Taunting;
	}
	else if (StrEqual("TFCond_UberchargeFading", var, false))
	{	
		return TFCond_UberchargeFading;
	}
	else if (StrEqual("TFCond_Unknown1", var, false))
	{	
		return TFCond_Unknown1;
	}
	else if (StrEqual("TFCond_CloakFlicker", var, false))
	{	
		return TFCond_CloakFlicker;
	}
	else if (StrEqual("TFCond_Teleporting", var, false))
	{	
		return TFCond_Teleporting;
	}
	else if (StrEqual("TFCond_Kritzkrieged", var, false))
	{	
		return TFCond_Kritzkrieged;
	}
	else if (StrEqual("TFCond_Unknown2", var, false))
	{	
		return TFCond_Unknown2;
	}
	else if (StrEqual("TFCond_TmpDamageBonus", var, false))
	{	
		return TFCond_TmpDamageBonus;
	}
	else if (StrEqual("TFCond_DeadRingered", var, false))
	{	
		return TFCond_DeadRingered;
	}
	else if (StrEqual("TFCond_Bonked", var, false))
	{	
		return TFCond_Bonked;
	}
	else if (StrEqual("TFCond_Dazed", var, false))
	{	
		return TFCond_Dazed;
	}
	else if (StrEqual("TFCond_Buffed", var, false))
	{	
		return TFCond_Buffed;
	}
	else if (StrEqual("TFCond_Charging", var, false))
	{	
		return TFCond_Charging;
	}
	else if (StrEqual("TFCond_DemoBuff", var, false))
	{	
		return TFCond_DemoBuff;
	}
	else if (StrEqual("TFCond_CritCola", var, false))
	{	
		return TFCond_CritCola;
	}
	else if (StrEqual("TFCond_InHealRadius", var, false))
	{	
		return TFCond_InHealRadius;
	}
	else if (StrEqual("TFCond_Healing", var, false))
	{	
		return TFCond_Healing;
	}
	else if (StrEqual("TFCond_OnFire", var, false))
	{	
		return TFCond_OnFire;
	}
	else if (StrEqual("TFCond_Overhealed", var, false))
	{	
		return TFCond_Overhealed;
	}
	else if (StrEqual("TFCond_Jarated", var, false))
	{	
		return TFCond_Jarated;
	}
	else if (StrEqual("TFCond_Bleeding", var, false))
	{	
		return TFCond_Bleeding;
	}
	else if (StrEqual("TFCond_DefenseBuffed", var, false))
	{	
		return TFCond_DefenseBuffed;
	}
	else if (StrEqual("TFCond_Milked", var, false))
	{	
		return TFCond_Milked;
	}
	else if (StrEqual("TFCond_MegaHeal", var, false))
	{	
		return TFCond_MegaHeal;
	}
	else if (StrEqual("TFCond_RegenBuffed", var, false))
	{	
		return TFCond_RegenBuffed;
	}
	else if (StrEqual("TFCond_MarkedForDeath", var, false))
	{	
		return TFCond_MarkedForDeath;
	}
	else if (StrEqual("TFCond_NoHealingDamageBuff", var, false))
	{	
		return TFCond_NoHealingDamageBuff;
	}
	else if (StrEqual("TFCond_SpeedBuffAlly", var, false))
	{	
		return TFCond_SpeedBuffAlly;
	}
	else if (StrEqual("TFCond_HalloweenCritCandy", var, false))
	{	
		return TFCond_HalloweenCritCandy;
	}
	else if (StrEqual("TFCond_CritCanteen", var, false))
	{	
		return TFCond_CritCanteen;
	}
	else if (StrEqual("TFCond_CritDemoCharge", var, false))
	{	
		return TFCond_CritDemoCharge;
	}
	else if (StrEqual("TFCond_CritHype", var, false))
	{	
		return TFCond_CritHype;
	}
	else if (StrEqual("TFCond_CritOnFirstBlood", var, false))
	{	
		return TFCond_CritOnFirstBlood;
	}
	else if (StrEqual("TFCond_CritOnWin", var, false))
	{	
		return TFCond_CritOnWin;
	}
	else if (StrEqual("TFCond_CritOnFlagCapture", var, false))
	{	
		return TFCond_CritOnFlagCapture;
	}
	else if (StrEqual("TFCond_CritOnKill", var, false))
	{	
		return TFCond_CritOnKill;
	}
	else if (StrEqual("TFCond_RestrictToMelee", var, false))
	{	
		return TFCond_RestrictToMelee;
	}
	else if (StrEqual("TFCond_DefenseBuffNoCritBlock", var, false))
	{	
		return TFCond_DefenseBuffNoCritBlock;
	}
	else if (StrEqual("TFCond_Reprogrammed", var, false))
	{	
		return TFCond_Reprogrammed;
	}
	else if (StrEqual("TFCond_CritMmmph", var, false))
	{	
		return TFCond_CritMmmph;
	}
	else if (StrEqual("TFCond_DefenseBuffMmmph", var, false))
	{	
		return TFCond_DefenseBuffMmmph;
	}
	else if (StrEqual("TFCond_FocusBuff", var, false))
	{	
		return TFCond_FocusBuff;
	}
	else if (StrEqual("TFCond_DisguiseRemoved", var, false))
	{	
		return TFCond_DisguiseRemoved;
	}
	else if (StrEqual("TFCond_MarkedForDeathSilent", var, false))
	{	
		return TFCond_MarkedForDeathSilent;
	}
	else if (StrEqual("TFCond_DisguisedAsDispenser", var, false))
	{	
		return TFCond_DisguisedAsDispenser;
	}
	else if (StrEqual("TFCond_Sapped", var, false))
	{	
		return TFCond_Sapped;
	}
	else if (StrEqual("TFCond_UberchargedHidden", var, false))
	{	
		return TFCond_UberchargedHidden;
	}
	else if (StrEqual("TFCond_UberchargedCanteen", var, false))
	{	
		return TFCond_UberchargedCanteen;
	}
	else if (StrEqual("TFCond_HalloweenBombHead", var, false))
	{	
		return TFCond_HalloweenBombHead;
	}
	else if (StrEqual("TFCond_HalloweenThriller", var, false))
	{	
		return TFCond_HalloweenThriller;
	}
	else if (StrEqual("TFCond_RadiusHealOnDamage", var, false))
	{	
		return TFCond_RadiusHealOnDamage;
	}
	else if (StrEqual("TFCond_CritOnDamage", var, false))
	{	
		return TFCond_CritOnDamage;
	}
	else if (StrEqual("TFCond_UberchargedOnTakeDamage", var, false))
	{	
		return TFCond_UberchargedOnTakeDamage;
	}
	else if (StrEqual("TFCond_UberBulletResist", var, false))
	{	
		return TFCond_UberBulletResist;
	}
	else if (StrEqual("TFCond_UberBlastResist", var, false))
	{	
		return TFCond_UberBlastResist;
	}
	else if (StrEqual("TFCond_UberFireResist", var, false))
	{	
		return TFCond_UberFireResist;
	}
	else if (StrEqual("TFCond_SmallBulletResist", var, false))
	{	
		return TFCond_SmallBulletResist;
	}
	else if (StrEqual("TFCond_SmallBlastResist", var, false))
	{	
		return TFCond_SmallBlastResist;
	}
	else if (StrEqual("TFCond_SmallFireResist", var, false))
	{	
		return TFCond_SmallFireResist;
	}
	else if (StrEqual("TFCond_Stealthed", var, false))
	{	
		return TFCond_Stealthed;
	}
	else if (StrEqual("TFCond_MedigunDebuff", var, false))
	{	
		return TFCond_MedigunDebuff;
	}
	else if (StrEqual("TFCond_StealthedUserBuffFade", var, false))
	{	
		return TFCond_StealthedUserBuffFade;
	}
	else if (StrEqual("TFCond_BulletImmune", var, false))
	{	
		return TFCond_BulletImmune;
	}
	else if (StrEqual("TFCond_BlastImmune", var, false))
	{	
		return TFCond_BlastImmune;
	}
	else if (StrEqual("TFCond_FireImmune", var, false))
	{	
		return TFCond_FireImmune;
	}
	else if (StrEqual("TFCond_PreventDeath", var, false))
	{	
		return TFCond_PreventDeath;
	}
	else if (StrEqual("TFCond_HalloweenSpeedBoost", var, false))
	{	
		return TFCond_HalloweenSpeedBoost;
	}
	else if (StrEqual("TFCond_HalloweenQuickHeal", var, false))
	{	
		return TFCond_HalloweenQuickHeal;
	}
	else if (StrEqual("TFCond_HalloweenGiant", var, false))
	{	
		return TFCond_HalloweenGiant;
	}
	else if (StrEqual("TFCond_HalloweenTiny", var, false))
	{	
		return TFCond_HalloweenTiny;
	}
	else if (StrEqual("TFCond_HalloweenInHell", var, false))
	{	
		return TFCond_HalloweenInHell;
	}
	else if (StrEqual("TFCond_HalloweenGhostMode", var, false))
	{	
		return TFCond_HalloweenGhostMode;
	}
	/*
	else if (StrEqual("ENUM_GOES_HERE", var, false))
	{	
		return ENUM_GOES_HERE;
	}
	else if (StrEqual("ENUM_GOES_HERE", var, false))
	{	
		return ENUM_GOES_HERE;
	}*/
	
	
	//No Match? What a shame we'll just convert the string to an int then and hope for the best.
	return StringToInt(var);
}	