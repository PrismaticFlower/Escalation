#if defined _escalation_included
#endinput
#endif
#define _escalation_included


//The bit flags for why a client's credits changed.
//Note that the descriptions below describe the default behaviour in most cases. There is nothing stopping a client from losing credits when they die for instance. 
//You should always check what iOperation contains before assuming that the client is getting credits. Also it doesn't hurt to make sure iValue is positive.
#define ESC_CREDITS_RESET 0 /** The credits of this client are being reset. */
#define ESC_CREDITS_PURCHASE (1 << 0) /** These credits are being taken away to pay for an upgrade. */ 
#define ESC_CREDITS_REFUNDED (1 << 1) /** These credits are from an upgrade being refunded. */
#define ESC_CREDITS_REFUND_FULL (1 << 2) /** These credits are the result of all a clients upgrades for a class (or all of them) being refunded. */
#define ESC_CREDITS_STARTING (1 << 3) /** The client is receiving their base amount of credits. */
#define ESC_CREDITS_COMPENSATE (1 << 4) /** The client is being given credits because they joined midgame */
#define ESC_CREDITS_OBJECTIVE (1 << 5) /** These are objective credits the entire team will/has received. */
#define ESC_CREDITS_TEAMPLAY (1 << 6) /** The client is getting these credits from various actions, defending a control point or medic for instance. */
#define ESC_CREDITS_KILL (1 << 7) /** These credits are the result of the client killing someone. */
#define ESC_CREDITS_KILLED (1 << 8) /** The client just died to another player and is getting these credits as compensation. */
#define ESC_CREDITS_DOMINATION (1 << 9) /** The client just dominated another player and is getting bonus credits. */
#define ESC_CREDITS_DOMINATED (1 << 10) /** The client got dominated and is getting these credits to help him out. */
#define ESC_CREDITS_ASSIST (1 << 11) /** The client is getting these credits because they got an assist. */
#define ESC_CREDITS_HEALED (1 << 12) /** These credits are from healing done in a life for a medic. */

#define ESC_CREDITS_NOAVERAGE (1 << 31) /** Exclude these credits from the average credits counter. */
#define ESC_CREDITS_PLUGIN (1 << 32) /** An external plugin has given these credits. */

//Escalation uses a collection of setter/getter functions to access the majority of it's global variables. 
//When a setter function is called it is called with one of these operations. They are basically an easy way to expose compound operators like *= and +=.
enum Set_Operation
{ 
	SET_ABSOLUTE,
	SET_MULTIPLY,
	SET_DIVIDE,
	SET_ADD,
	SET_SUBTRACT,
	SET_MODULO
};

#define UPGRADE_NAME_MAXLENGTH 32 //I think everything respects this but it was added pretty late into development so some things may break when you change this.

#define INVALID_ATTRIBUTE 0
#define UPGRADABLE_SLOTS 3 //If you change this Menu_UpgradeMenuBase, CreateUpgradeMenuBase and PlayerData will need manual updating.
#define ENTITY_MAX_ATTRIBUTES 16 //The most attributes the plugin will allow applying to each player/weapon, this is hardcoded by Valve to 16.
#define PLAYER_MAX_WEARABLES 8 //The most wearables a player can have on them.
#define CUSTOM_ATTRIBUTE_OFFSET 10000 //If an attribute's index is greater than this it is considered a custom one and a call to Escalation_CustomAttributes for it is made.
#define CLASS_MENU_OFFSET -10 //Used to offset the class IDs in the menu cache so they can be stored alongside the weapons.

#define KRITZKRIEG_INDEXES 35
#define QUICKFIX_INDEXES 411
#define VACCINATOR_INDEXES 998
#define GUNSLINGER_INDEXES 142

#define MENU_DISPLAY_DURATION 10


new const String:WeaponSlotKeys[UPGRADABLE_SLOTS][] = 
{
	"Slot_Primary",
	"Slot_Secondary",
	"Slot_Melee"
};

forward Esc_ClientCreditsChanged(client, Set_Operation:iOperation, &iFlags, &iValue);