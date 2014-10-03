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
 * @param iClass				The class whose upgrade queue to push the upgrade onto
 *								or TFClass_Unknown for the client's current class.
 *
 * @error						Client not connected or invalid class.
 * @return						True on the upgrade being pushed onto the client's queue, false on failure.
 */
native bool:Esc_PushUpgradeOntoQueue (iClient, const String:Upgrade[], TFClassType:iClass = TFClass_Unknown);

/**
 * Gets an upgrade from a client's upgrade queue.
 *
 * @param iClient				The index of the client.
 * @param iIndex				The index of the upgrade on the client's queue to fetch.
 * @param iClass				The class whose upgrade queue to get the upgrade from
 *								or TFClass_Unknown for the client's current class.
 * @param UpgradeQueueBuffer	An array to store the UpgradeQueue struct in.
 * @param iMaxSize				The max size of UpgradeQueueBuffer.
 *
 * @error						Client not connected, index out of range, invalid class
 *								or buffer not large enough.
 * @noreturn
 */
native Esc_GetUpgradeFromQueue (iClient, iIndex, TFClassType:iClass, UpgradeQueueBuffer[], iMaxSize);

/**
 * Removes an upgrade from a client's upgrade queue.
 *
 * @param iClient				The index of the client.
 * @param iIndex				The index of the upgrade on the client's queue to remove.
 * @param iClass				The class whose upgrade queue to remove the upgrade from
 *								or TFClass_Unknown for the client's current class.
 *
 * @error						Client not connected, index out of range or invalid class,
 * @noreturn
 */
native Esc_RemoveUpgradeFromQueue (iClient, iIndex, TFClassType:iClass);

/**
 * Gets the size of a client's upgrade queue.
 *
 * @param iClient				The index of the client.
 * @param iClass				The class whose upgrade queue to get the size of
 *								or TFClass_Unknown for the client's current class.
 *
 * @error						Client not connected or invalid class.
 * @return						The size of the client's upgrade queue.
 */
native Esc_GetUpgradeQueueSize (iClient, TFClassType:iClass);

/**
 * Cleans a client's upgrade queue.
 *
 * @param iClient				The index of the client.
 * @param iClass				The class whose upgrade queue to get the size of
 *								or TFClass_Unknown for all the client's classes.
 *
 * @error						Client not connected or invalid class.
 * @noreturn
 */
native Esc_ClearUpgradeQueue (iClient, TFClassType:iClass = TFClass_Unknown);



/**
 * Called whenever a client's credits change.
 *
 * @param iClient				The index of the client whose credits are changing.
 * @param iOperation			The set operation to being taken.
 * @param iFlags				The flags (by beference) containing the reason the client is getting these credits.
 * @param iValue				The value (by beference) to use with the set operation. 
 *
 * @return						The client's new credit count.
 */
forward Esc_ClientCreditsChanged (iClient, Set_Operation:iOperation, &iFlags, &iValue);