#if defined _escalation_customattributes_included
#endinput
#endif
#define _escalation_customattributes_included

 

 /**
 * Loads up a keyvalue file containing custom attribute definitions.
 *
 * @param File		The name of the file including the path to it.
 *
 * @noreturn		
 * @error			Unable to open the file or unable to read the keyvalues from the file.
 */
native Esc_LoadCustomAttributeFile (const String:File[]);


/**
 * Applies a custom attribute to a client.
 *
 * @param client		The client index to apply the attribute to.
 * @param iAttribute	The attribute ID to apply to the player. (Must be one already defined and loaded up using Esc_LoadCustomAttributeFile)
 * @param fValue		The value of the attribute to be applied to the player.
 * @param bReplace		If true the attribute's value will be replaced with the new one if it is already present on the player.
 *
 * @noreturn
 * @error				Invalid attribute or invalid client..
 */
native Esc_ApplyCustomAttribute (client, iAttribute, Float:fValue, bool:bReplace = false);


/**
 * Removess the first instance of a custom attribute from a client.
 *
 * @param client		The client to remove the attribute from.
 * @param iAttribute	The attribute to remove from the client.
 *
 * @noreturn			
 * @error				Invalid client, invalid attribute or the attribute did not exist on the client.
 */
native Esc_RemoveCustomAttribute (client, iAttribute); 


/**
 * Removes all custom attributes from a client.
 *
 * @param client	The client to remove the attributes from.
 * @param iSlot		The slot to remove the attributes from.
 *
 * @noreturn		
 * @error			Invalid client.
 */
native Esc_RemoveCustomAttributes (client);