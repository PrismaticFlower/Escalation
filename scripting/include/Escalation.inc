#if defined _escalation_included
#endinput
#endif
#define _escalation_included

#include<escalation_constants>
#include<tf2>

/**
 * Pushes an upgrade onto a client's upgrade queue.
 *
 * @param iClient				The index of the client.
 * @param Upgrade				The name of the upgrade to add to the client's queue.
 * @param iClass				The class whose upgrade queue to push the upgrade onto.
 * @param bRespond				If true the client will be informed of success or failure by chat messages.
 * @param bForce				If true the bypass the check of if the client is allowed the upgrade.
 *								This does not let the client buy the upgrade. Their current class and weapons must still be allowed it.
 *								It is designed to let other plugins add upgrade to the client's queue when their loadout is not yet known.
 *
 * @error						Client not connected, invalid class or plugin not active/ready.
 * @return						True on the upgrade being pushed onto the client's queue, false on failure.
 */
native bool:Esc_PushUpgradeOntoQueue (iClient, const String:Upgrade[UPGRADE_NAME_MAXLENGTH], TFClassType:iClass, bool:bRespond, bool:bForce = false);

/**
 * Gets an upgrade from a client's upgrade queue.
 *
 * @param iClient				The index of the client.
 * @param iIndex				The index of the upgrade on the client's queue to fetch.
 * @param iClass				The class whose upgrade queue to get the upgrade from
 * @param UpgradeQueueBuffer	An array to store the UpgradeQueue struct in.
 * @param iMaxSize				The max size of UpgradeQueueBuffer.
 *
 * @error						Client not connected, index out of range, invalid class,
 *								buffer not large enough or plugin not active/ready
 * @noreturn
 */
native Esc_GetUpgradeFromQueue (iClient, iIndex, TFClassType:iClass, UpgradeQueueBuffer[], iMaxSize);

/**
 * Removes an upgrade from a client's upgrade queue.
 *
 * @param iClient				The index of the client.
 * @param iIndex				The index of the upgrade on the client's queue to remove.
 * @param iClass				The class whose upgrade queue to remove the upgrade from
 * @param bInform				If true inform the client of any action taken.
 *
 * @error						Client not connected,index out of range,
 *								invalid class or plugin not active/ready.
 * @noreturn
 */
native Esc_RemoveUpgradeFromQueue (iClient, iIndex, TFClassType:iClass, bool:bInform);

/**
 * Gets the size of a client's upgrade queue.
 *
 * @param iClient				The index of the client.
 * @param iClass				The class whose upgrade queue to get the size of.
 *
 * @error						Client not connected, invalid class or plugin not active/ready.
 * @return						The size of the client's upgrade queue.
 */
native Esc_GetUpgradeQueueSize (iClient, TFClassType:iClass);

/**
 * Cleans a client's upgrade queue.
 *
 * @param iClient				The index of the client.
 * @param iClass				The class whose upgrade queue to get the size of.
 * @param bInform				If true inform the client of any action taken.
 *
 * @error						Client not connected, invalid class or plugin not active/ready.
 * @noreturn
 */
native Esc_ClearUpgradeQueue (iClient, TFClassType:iClass, bool:bInform);

/**
 * Sets a client's credits.
 *
 * @param iClient				The index of the client whose credits to set.
 * @param iOperation			The set operation to take.
 *								Set Escalation_Constants.inc for a list.
 * @param iFlags				The bit flags containing the reason the client is getting these credits.
 *								Set Escalation_Constants.inc for a list.
 * @param iValue				The value to use with the set operation. 
 *
 * @error						Invalid client, client not connected or plugin not active/ready.
 * @return						The new value of the client's credits.
 */
native Esc_SetClientCredits (iClient, Set_Operation:iOperation, iFlags, iValue);

/**
 * Checks if the plugin is active. (Started and not disabled.)
 *
 * @return						True if the plugin is active, false if it isn't.
 */
native bool:Esc_IsPluginActive ();

/**
 * Checks if a client's data object exists.
 *
 * @param iClient				The client to check the data of.
 *
 * @error						Plugin not active or invalid client.
 * @return						True if the client has data, false if they don't.
 */
native bool:Esc_ClientHasData (iClient);

/**
 * Gets an array filled with the names of Escalation's upgradequeue.
 *
 * @error						Plugin not active/ready.
 * @return						The handle to the array, you must close this once you're done with it.
 */
native Handle:Esc_GetArrayOfUpgrades ();

/**
 * Called when the plugin is started and ready.
 * This exists so you can track when the plugin is 
 * enabled and disabled by the server admin.
 *
 * @noreturn
 */
forward Esc_PluginReady ();

/**
 * Called when the plugin is stopped.
 * This exists so you can track when the plugin is 
 * enabled and disabled by the server admin.
 *
 * @noreturn
 */
forward Esc_PluginStopped ();

/**
 * Called whenever the plugin loads upgrade data, 
 * weapon data and class data. For some reason this doesn't
 * always fire at plugin start. But if Esc_IsPluginActive
 * returns true you can just manually call this yourself safely.
 *
 * @noreturn
 */
forward Esc_CoreConfigsLoaded ();

/**
 * Called when a client's data object has been created.
 * It is unsafe to call functions that do something with a client
 * until after this is called for that client.
 *
 * @param iClient				The index of the client whose PlayerData object is ready.
 *
 * @noreturn
 */
forward Esc_PlayerDataCreated (iClient);

/**
 * Called right before a client's data is going to be destroyed.
 * This is your last chance to fetch information about the client.
 *
 * @param iClient				The index of the client whose PlayerData object is about to be destroyed.
 *
 * @noreturn
 */
forward Esc_PlayerDataDestroy (iClient);

/**
 * Called whenever a client's credits change.
 *
 * @param iClient				The index of the client whose credits are changing.
 * @param iOperation			The set operation (by beference) to being taken.
 * @param iFlags				The  bit flags containing the reason the client is getting these credits.
 * @param iValue				The value (by beference) to use with the set operation. 
 *
 * @noreturn
 */
forward Esc_ClientCreditsChanged (iClient, &Set_Operation:iOperation, iFlags, &iValue);


public SharedPlugin:__pl_Escalation = 
{
	name = "Escalation",
	file = "Escalation.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_Escalation_SetNTVOptional()
{
	MarkNativeAsOptional("Esc_PushUpgradeOntoQueue");
	MarkNativeAsOptional("Esc_GetUpgradeFromQueue");
	MarkNativeAsOptional("Esc_RemoveUpgradeFromQueue");
	MarkNativeAsOptional("Esc_GetUpgradeQueueSize");
	MarkNativeAsOptional("Esc_ClearUpgradeQueue");
	MarkNativeAsOptional("Esc_SetClientCredits");
	MarkNativeAsOptional("Esc_IsPluginActive");
	MarkNativeAsOptional("Esc_GetArrayOfUpgrades");
	MarkNativeAsOptional("Esc_ClientHasData");
}
#endif
