#include<sourcemod>
#include<sdktools>

#include<tf2>
#include<tf2_stocks>
#include<tf2attributes>

#include<clientprefs>

#undef REQUIRE_EXTENSIONS
#include<tf2items>
#include<steamtools>
#undef REQUIRE_PLUGIN
#include<adminmenu>

#include<morecolors>
#include<Escalation_Constants>
#include<Escalation_Stocks>
#include<Escalation_Objects>

#define REQUIRE_PLUGIN
#include<Escalation_CustomAttributes>

#define PLUGIN_NAME "Escalation"
#define PLUGIN_VERSION "1.0.0"


public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "SleepKiller",
	description = "A custom gamemode (of sorts) centered around weapon upgrading as the game goes on. Earn credits by playing for the objectives and being a team player.",
	version = PLUGIN_VERSION,
	url = ""
};

/************************CREDIT VARIABLES************************/

/**
 * The amount of objective credits earned by each team. 
 * Use the setter/getter function to access this or I'll destroy you.
 * Get_iObjectiveCredits, Set_iObjectiveCredits
 */
static g_iObjectiveCredits[4]; 

/************************MENU VARIABLES************************/

static Handle:g_hUpgradeMenuBase = INVALID_HANDLE; /**< The base menu handle for all the other menus. */

static Handle:g_hClearMenu = INVALID_HANDLE; /**< The handle to the menu that a client can clear their upgrade queue. */

/************************UTILITY VARIABLES************************/

static bool:g_bClientHasData[MAXPLAYERS + 1]; /**< Used to keep track of if a player has had their data object created for them. */

static bool:g_bPluginDisabledForMap; /**< When set to true the plugin is disabled for the rest of the map. */

static bool:g_bPluginDisabledAdmin; /**< When set to true the plugin is disabled. When set to false the plugin is disabled, amazing! */

static bool:g_bPluginStarted; /**< Set to true once StartPlugin has been called, it is set to false when the plugin is disabled for any reason. */

static Handle:g_hPointOwner = INVALID_HANDLE; /**< Enabled the plugin to know who previously owned a control point. */

static bool:g_bBuyUpgrades; /**< When set to true the plugin will buy upgrades, when set to false it won't. */

static bool:g_bGiveCredits; /**< When set to true the plugin will give players credits for doing stuff, when set to false it won't. */

static bool:g_bHUDReminder = true; /**< When set to true the plugin will display a HUD reminder to new players. */

static bool:g_bChatReminder = true; /**< When set to true the plugin will display a chat reminder to new players. */

/************************LIBRARY VARIABLES************************/

static bool:g_bTF2ItemsBackupHooked; /**< Used to keep track of if the TF2Items fallback event has been hooked. */
static bool:g_bSteamTools; /**< Used to keep track of if SteamTools is available. */

/************************FORWARD VARIABLES************************/

static Handle:g_hCoreConfigsLoaded = INVALID_HANDLE; /**< Handle to the forward that is called when the plugin loads it's core config files. */
static Handle:g_hPluginReady = INVALID_HANDLE; /**< Handle to the forward that is called when the plugin is started and ready. */
static Handle:g_hPluginStopped = INVALID_HANDLE; /**< Handle to the forward that is called when the plugin is stopped. */
static Handle:g_hClientDataReady = INVALID_HANDLE; /**< Handle to the forward that is called when a client's data is created. */
static Handle:g_hClientDataDestroy = INVALID_HANDLE; /**< Handle to the forward that is called before a client's data is destroyed. */
static Handle:g_hClientCreditsChanged = INVALID_HANDLE; /**< Handle to the forward that is called when a client's credits change. */

/************************CVAR VARIABLES************************/

static Handle:CVar_Enabled = INVALID_HANDLE; /**< A handle to the cvar the server admin can use to disable the plugin. */
static Handle:CVar_HUD_Reminder = INVALID_HANDLE; /**< A handle to the cvar the server admin can use to disable the HUD reminder. */
static Handle:CVar_Chat_Reminder = INVALID_HANDLE; /**< A handle to the cvar the server admin can use to disable the chat reminder. */

/************************OBJECTS************************/

/**
 * Holds and manages all information about a weapon.
 * Includeing the upgrades it is allowed and the weapon slot it takes up.
 */
static g_WeaponInfoManager[WeaponInfoManager];

/**
 * Stores the upgrade menus for each weapon.
 * This will hopefully be replaced with code that generates the menus on demand,
 * at some point in the future.
 */
static g_UpgradeMenuCache[MenuCache];

/**
 * Handles almost all the information about a player, 
 * such as their upgrade queue and credit count.
 */
static g_PlayerData[MAXPLAYERS + 1][PlayerData];

/**
 * Stores the data about each upgrade,
 * except for descriptions which are owned by g_UpgradeDescriptions. 
 */
static g_UpgradeDataStore[UpgradeDataStore];

/**
 * Stores which upgrades each class is allowed. 
 */
static g_ClassInfoStore[ClassInfoStore];

/**
 * Stores the translation keys for each upgrades descriptions. 
 */
static g_UpgradeDescriptions[UpgradeDescriptions];

/**
 * Stores which upgrades have been banned, both by config files
 * and admins. 
 */
static g_BannedUpgrades[BannedUpgrades];

/**
 * Stores the stock attributes of each weapon in the game.
 */
static g_StockAttributes[StockAttributes];

/**
 * Stores the current gamemode information.
 */
static g_GameInfo[KVMap];

/************************ADMIN MENU VARIABLES************************/

static Handle:g_hAdminMenu = INVALID_HANDLE; /**< A handle to the SourceMod admin menu. */
static TopMenuObject:g_AdminMenuCommands;
static TopMenuObject:g_AdminMenuBanUpgrades;
static TopMenuObject:g_AdminMenuUnbanUpgrades;
static TopMenuObject:g_AdminMenuResetBannedUpgrades;

/************************CLIENT COOKIE VARIABLES************************/

static Handle:g_hMenuOpenedCookie = INVALID_HANDLE; /**< A handle to the cookie for a client has opened the upgrade menu. */

/************************CORE PLUGIN FUNCTIONS************************/

/**
 * Creates all of the lovely natives for the API.
 *
 * @param hMyself	Handle to the plugin.
 * @param bLate		Whether or not the plugin was late loaded.
 * @param Error		Buffer for an optional error message in event of load failure.
 * @param iErr_max	The max size of the above buffer.
 *
 * @return			APLRes status.				
 */
public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:Error[], iErr_max)
{
	CreateNative("Esc_PushUpgradeOntoQueue", Native_Esc_PushUpgradeOntoQueue);
	CreateNative("Esc_GetUpgradeFromQueue", Native_Esc_GetUpgradeFromQueue);
	CreateNative("Esc_RemoveUpgradeFromQueue", Native_Esc_RemoveUpgradeFromQueue);
	CreateNative("Esc_GetUpgradeQueueSize", Native_Esc_GetUpgradeQueueSize);
	CreateNative("Esc_ClearUpgradeQueue", Native_Esc_ClearUpgradeQueue);
	CreateNative("Esc_SetClientCredits", Native_Esc_SetClientCredits);
	CreateNative("Esc_IsPluginActive", Native_Esc_IsPluginActive);
	CreateNative("Esc_GetArrayOfUpgrades", Native_Esc_GetArrayOfUpgrades);
	CreateNative("Esc_ClientHasData", Native_Esc_ClientHasData);
	
	RegPluginLibrary("Escalation");
	
	return APLRes_Success;
}

/**
 * Does pretty much what you would expect OnPluginStart to do, loads up the translations, creates convars, 
 * console commands, constructs a couple objects and calls StartPlugin.
 *
 * @noreturn
 */
public OnPluginStart()
{
	//First up we load dem translations.
	LoadTranslations("Escalation.phrases");
	LoadTranslations("escalation_upgrade.phrases");
	LoadTranslations("Escalation_AttrDescriptions.phrases");
	
	CreateConVar("escalation_version", PLUGIN_VERSION, "The version of the plugin you're running, not much else to say really.", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY | FCVAR_PLUGIN);
	CVar_Enabled = CreateConVar("escalation_enabled", "1", "When set to 1 the plugin is enabled! When set to 0 the plugin is disabled, amazing!", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CVar_HUD_Reminder = CreateConVar("escalation_hudreminder", "1", "If 1 a HUD reminder tells players to open the upgrade menu will be displayed to players connecting to the server for the first time.",  FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	CVar_Chat_Reminder = CreateConVar("escalation_chatreminder", "1", "If 1 a chat reminder tells players to open the upgrade menu will be displayed to players connecting to the server for the first time.",  FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "Escalation_Config"); //Execute the config.
	
	HookConVarChange(CVar_Enabled, CVar_Enable_Changed);
	HookConVarChange(CVar_HUD_Reminder, CVar_Misc_Changed);
	HookConVarChange(CVar_Chat_Reminder, CVar_Misc_Changed);
	
	g_hMenuOpenedCookie = RegClientCookie("escalation_menuopened", "", CookieAccess_Private);

	//Create the forwards.
	g_hClientCreditsChanged = CreateGlobalForward("Esc_ClientCreditsChanged", ET_Ignore, Param_Cell, Param_CellByRef, Param_Cell, Param_CellByRef);
	g_hClientDataReady = CreateGlobalForward("Esc_PlayerDataCreated", ET_Ignore, Param_Cell);
	g_hClientDataDestroy = CreateGlobalForward("Esc_PlayerDataDestroy", ET_Ignore, Param_Cell);
	g_hPluginReady = CreateGlobalForward("Esc_PluginReady", ET_Ignore);
	g_hPluginStopped = CreateGlobalForward("Esc_PluginStopped", ET_Ignore);
	g_hCoreConfigsLoaded = CreateGlobalForward("Esc_CoreConfigsLoaded", ET_Ignore);
	
	//Create the Menus
	CreateBaseMenus();

	//Public Commands
	RegConsoleCmd("credits", Command_MyCredits, "Tells you how many credits you've earned.");
	RegConsoleCmd("upgrade", Command_UpgradeMenu, "Buy an upgrade using your credits through a menu! It's pretty snazzy.");
	RegConsoleCmd("buyupgrade", Command_Upgrade, "A command for the poweruser in need. Use this to create binds that buy your favourite upgrades. (Really just an old and deprecate command left in because it does have some functionalty that some people may find useful.)");
	RegConsoleCmd("clearupgrades", Command_ClearUpgrades, "Resets your upgrade queue for a specific class or all of them. This also has the effect of refunding all your upgrades.");

	//Admin Only Commands	
	RegAdminCmd("sm_reloadconfigs", Command_ReloadConfigs, ADMFLAG_CONVARS, "Reloads all of Escalation's config files. Be warned this may stall your server for a tiny bit.");
	RegAdminCmd("sm_banupgrade", Command_BanUpgrade, ADMFLAG_BAN, "Bans an upgrade, preventing it from being purchased.");
	RegAdminCmd("sm_bancombo", Command_BanCombo, ADMFLAG_BAN, "Bans an upgrade and weapon combination.");
	RegAdminCmd("sm_unbanupgrade", Command_UnbanUpgrade, ADMFLAG_BAN, "Unbans an upgrade, allowing clients to buy it again.");
	RegAdminCmd("sm_unbancombo", Command_UnbanCombo, ADMFLAG_BAN, "Unbans an upgrade and weapon combination.");
	RegAdminCmd("sm_reset_bannedupgrades", Command_ResetBannedUpgrades, ADMFLAG_BAN, "Resets all banned upgrades.");
	RegAdminCmd("sm_reset_bannedcombos", Command_ResetBannedCombos, ADMFLAG_BAN, "Resets all banned upgrade and weapon combinations.");
	RegAdminCmd("sm_menu_banupgrade", Command_BanUpgradeMenu, ADMFLAG_BAN, "Allows you to ban an upgrade through a menu.");
	RegAdminCmd("sm_menu_unbanupgrade", Command_UnbanUpgradeMenu, ADMFLAG_BAN, "Allows you to ban an upgrade through a menu.");
	RegAdminCmd("sm_setgameinfo", Command_SetGameInfo, ADMFLAG_CHEATS, "Sets a game info variable. (The starting credits of a client for instance.)");

	//Developer Commands
	#if defined DEV_BUILD
		RegConsoleCmd("sm_givecredits", Command_GiveCredits, "Gives you X amount of credits.", FCVAR_UNREGISTERED | FCVAR_CHEAT);
		RegConsoleCmd("sm_forceupgrade", Command_ForceUpgrade, "Forces an upgrade to be put onto a client's upgrade queue.", FCVAR_UNREGISTERED | FCVAR_CHEAT);
		RegConsoleCmd("sm_printcredits", Command_PrintCredits, "Prints out all connected client's credits to the console.", FCVAR_UNREGISTERED | FCVAR_CHEAT);
		RegConsoleCmd("sm_printteamcredits", Command_PrintTeamCredits, "Prints out the credits of all clients on the team.", FCVAR_UNREGISTERED | FCVAR_CHEAT);
		RegConsoleCmd("sm_printearnedcredits", Command_PrintTotalCredits, "Prints out the total earned credits of all clients.", FCVAR_UNREGISTERED | FCVAR_CHEAT);
		RegConsoleCmd("sm_forcemenu", Command_ForceMenuDisplay, "Forces an upgrade menu to be displayed", FCVAR_UNREGISTERED | FCVAR_CHEAT);
		RegConsoleCmd("sm_forceattribute", Command_ForceAttribute, "Forces a custom attribute onto a client.", FCVAR_UNREGISTERED | FCVAR_CHEAT);
		RegConsoleCmd("sm_forcesupport", Command_ForceSupport, "Forces the plugin to support the plugin to think the map is supported.", FCVAR_UNREGISTERED | FCVAR_CHEAT);
		RegConsoleCmd("sm_destroyobjects", Command_DestroyObjects, "Destroys all global objects in order to test for memory leaks. This breaks the plugin.", FCVAR_UNREGISTERED | FCVAR_CHEAT);
	#endif

	BannedUpgrades_Construct(g_BannedUpgrades[0]);
	KVMap_Construct(g_GameInfo[0]);
	StockAttributes_ConstructFull(g_StockAttributes[0], "scripts/items/items_game.txt");

	if (! LibraryExists("TF2Items") && ! g_bTF2ItemsBackupHooked)
	{
		HookEvent("post_inventory_application", Event_PlayerInventoryCheck, EventHookMode_Pre);
	}

	new Handle:hTopMenu;

	if (LibraryExists("adminmenu") && (hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE)
	{
		OnAdminMenuReady(hTopMenu);
	}

	//Cache Initial Cvar values
	g_bPluginDisabledAdmin = ! GetConVarBool(CVar_Enabled);
	g_bHUDReminder = GetConVarBool(CVar_HUD_Reminder);
	g_bChatReminder = GetConVarBool(CVar_Chat_Reminder);
	
	//Start The Plugin!
	if (! g_bPluginDisabledAdmin)
	{
		StartPlugin();
	}
}

/**
 * Calls StopPlugin so the plugin can clean up itself before being unloaded.
 *
 * @noreturn
 */
public OnPluginEnd()
{
	if (g_bPluginStarted)
	{
		StopPlugin();
	}
}

/**
 * Changes the description of the game back to Team Fortress if the plugin is paused.
 *
 * @param bPause	True if the plugin is being paused.
 *
 * @noreturn
 */
public OnPluginPauseChange(bool:bPause)
{
	if (g_bSteamTools)
	{
		if (bPause)
		{
			Steam_SetGameDescription("Team Fortress");
		}
		else
		{
			decl String:FormattedString[256];
			Format(FormattedString, sizeof(FormattedString), "%s (%s)", PLUGIN_NAME, PLUGIN_VERSION);
	
			Steam_SetGameDescription(FormattedString);
		}
	}
}

/**
 * Creates the base menus for the plugin that have their contents defined at compile time.
 *
 * @noreturn
 */
CreateBaseMenus()
{
	//Create the menu.
	g_hUpgradeMenuBase = CreateMenu(Menu_UpgradeMenuBase, MenuAction_Select | MenuAction_DisplayItem);
	
	//Set the title.
	SetMenuTitle(g_hUpgradeMenuBase, "%T", "Select_Menu_Action", LANG_SERVER); 
	
	//Add all the options.
	AddMenuItem(g_hUpgradeMenuBase, "Upgrade_Class", "Upgrade Class");
	AddMenuItem(g_hUpgradeMenuBase, "Upgrade_Slot_0", "Upgrade Primary Weapon");
	AddMenuItem(g_hUpgradeMenuBase, "Upgrade_Slot_1", "Upgrade Secondary Weapon");
	AddMenuItem(g_hUpgradeMenuBase, "Upgrade_Slot_2", "Upgrade Melee Weapon");
	AddMenuItem(g_hUpgradeMenuBase, "Menu_Action_EditQueue", "Edit Upgrade Queue");
	AddMenuItem(g_hUpgradeMenuBase, "Menu_Action_RemoveQueue", "Remove an Upgrade From Your Queue");
	AddMenuItem(g_hUpgradeMenuBase, "Menu_Action_Clear", "Clear Upgrade Queue");		
	
	//Set this to true even though it is true by default.
	SetMenuExitButton(g_hUpgradeMenuBase, true);
	
	g_hClearMenu = CreateMenu(Menu_ClearUpgrades, MenuAction_Select|MenuAction_Cancel|MenuAction_DisplayItem);

	SetMenuTitle(g_hClearMenu, "%T", "Select_Class", LANG_SERVER);
	
	AddMenuItem(g_hClearMenu, "Select_Class_All", "All Classes");
	AddMenuItem(g_hClearMenu, "Select_Class_Scout", "Scout");
	AddMenuItem(g_hClearMenu, "Select_Class_Soldier", "Soldier");
	AddMenuItem(g_hClearMenu, "Select_Class_Pyro", "Pyro");
	AddMenuItem(g_hClearMenu, "Select_Class_Demoman", "Demoman");
	AddMenuItem(g_hClearMenu, "Select_Class_Heavy", "Heavy");
	AddMenuItem(g_hClearMenu, "Select_Class_Engineer", "Engineer");
	AddMenuItem(g_hClearMenu, "Select_Class_Medic", "Medic");
	AddMenuItem(g_hClearMenu, "Select_Class_Spy", "Spy");
	AddMenuItem(g_hClearMenu, "Select_Class_Sniper", "Sniper");
	
	SetMenuExitBackButton(g_hClearMenu, true);
	
}

/**
 * Executes the plugin's config files, hooks events and handles already connected players.
 *
 * @noreturn
 * @error			Plugin already started.
 */
StartPlugin ()
{
	//Make sure we're not about to do something silly like leak memory here.
	if (g_bPluginStarted)
	{
		ThrowError("StartPlugin is being called after the plugin has been started.")
	
		return;
	}

	//Enable the plugin
	g_bPluginStarted = true;

	//Construct the objects.
	WeaponInfoManager_Construct(g_WeaponInfoManager[0]);
	MenuCache_Construct(g_UpgradeMenuCache[0]);
	UpgradeDataStore_Construct(g_UpgradeDataStore[0]);
	ClassInfoStore_Construct(g_ClassInfoStore[0]);
	UpgradeDescriptions_Construct(g_UpgradeDescriptions[0]);

	//Execute The Configs
	ExecuteConfigs();

	//Catch those pesky already connected players.
	new bool:bClientWasConnected;

	for (new iClient = 1; iClient <= MaxClients; iClient ++)
	{
		if (IsClientValid(iClient))
		{
			OnClientConnected(iClient);
			
			bClientWasConnected = true;
			
			//Cache Those Weapon Thingys
			if (IsClientInGame(iClient) && ! IsClientSpectator(iClient))
			{
				ForceCachedLoadoutRefresh(iClient);
			}
		}
	}

	if (bClientWasConnected)
	{
		ServerCommand("mp_restartgame_immediate 1");
	}

	//Player Core Events
	HookEvent("player_team", Event_PlayerChangeTeam);
	HookEvent("player_changeclass", Event_PlayerChangeClass);		
	HookEvent("post_inventory_application", Event_PlayerResupply);
	HookEvent("player_spawn", Event_PlayerSpawn);

	//Round Events
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("teamplay_round_stalemate", Event_RoundEnd);

	//Player Events
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("medic_death", Event_MedicDeath);
	HookEvent("medic_defended", Event_MedicDefended);
	HookEvent("player_teleported", Event_PlayerTeleported);
	HookEvent("player_upgradedobject", Event_PlayerUpgradedBuilding);
	HookEvent("player_chargedeployed", Event_ChargeDeployed);
	HookEvent("player_extinguished", Event_PlayerExtinguished);
	HookEvent("object_destroyed", Event_ObjectDestroyed);

	//Team Events
	HookEvent("teamplay_flag_event", Event_FlagEvent);
	HookEvent("teamplay_point_startcapture", Event_PointContested);
	HookEvent("teamplay_point_captured", Event_CapturedPoint);
	HookEvent("teamplay_capture_blocked", Event_CaptureBlocked);

	CPrintToChatAll("%t %t", "Escalation_Tag", "Plugin_Started");

	if (g_bSteamTools)
	{
		decl String:FormattedString[256];
		Format(FormattedString, sizeof(FormattedString), "%s (%s)", PLUGIN_NAME, PLUGIN_VERSION);
	
		Steam_SetGameDescription(FormattedString);
	}

	//Call the Forward notifying other plugins that the plugin is ready.
	Call_StartForward(g_hPluginReady); //Esc_PluginReady
	Call_Finish();
}

/**
 * Cleans up the plugin's objects and unhooks events.
 *
 * @noreturn
 * @error			Plugin not running/disabled.
 */
StopPlugin ()
{
	if (! g_bPluginStarted)
	{
		ThrowError("Attempt to stop plugin when it was not running.")
	
		return;
	}

	//Destroy the objects.
	WeaponInfoManager_Destroy(g_WeaponInfoManager[0]);
	MenuCache_Destroy(g_UpgradeMenuCache[0]);
	UpgradeDataStore_Destroy(g_UpgradeDataStore[0]);
	ClassInfoStore_Destroy(g_ClassInfoStore[0]);
	UpgradeDescriptions_Destroy(g_UpgradeDescriptions[0]);

	//"Disconnect" all the connected players.
	for (new iClient = 1; iClient <= MaxClients; iClient ++)
	{
		if (IsClientValid(iClient) && g_bClientHasData[iClient])
		{
			OnClientDisconnect(iClient);
		}
	}

	//Round Events
	UnhookEvent("teamplay_round_start", Event_RoundStart);
	UnhookEvent("teamplay_round_win", Event_RoundEnd);
	UnhookEvent("teamplay_round_stalemate", Event_RoundEnd);

	//Player Events
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("medic_death", Event_MedicDeath);
	UnhookEvent("medic_defended", Event_MedicDefended);
	UnhookEvent("player_teleported", Event_PlayerTeleported);
	UnhookEvent("player_upgradedobject", Event_PlayerUpgradedBuilding);
	UnhookEvent("player_chargedeployed", Event_ChargeDeployed);
	UnhookEvent("player_extinguished", Event_PlayerExtinguished);
	UnhookEvent("object_destroyed", Event_ObjectDestroyed);

	UnhookEvent("player_team", Event_PlayerChangeTeam);
	UnhookEvent("player_changeclass", Event_PlayerChangeClass);		
	UnhookEvent("post_inventory_application", Event_PlayerResupply);
	UnhookEvent("player_spawn", Event_PlayerSpawn);

	//Team Events
	UnhookEvent("teamplay_flag_event", Event_FlagEvent);
	UnhookEvent("teamplay_point_startcapture", Event_PointContested);
	UnhookEvent("teamplay_point_captured", Event_CapturedPoint);
	UnhookEvent("teamplay_capture_blocked", Event_CaptureBlocked);

	g_bPluginStarted = false;
	g_bBuyUpgrades = false;
	g_bGiveCredits = false;

	if (g_bSteamTools)
	{
		Steam_SetGameDescription("Team Fortress");
	}


	//Call the Forward notifying other plugins that the plugin has been stopped.
	Call_StartForward(g_hPluginStopped); //Esc_PluginStopped
	Call_Finish();
}

/**
 * Helps keeps track of Escalation's optional dependencies. And takes measures if one is late loaded.
 *
 * @param Name		The name of the library that got added.
 *
 * @noreturn
 */
public OnLibraryAdded (const String:Name[])
{
	if (StrEqual(Name, "TF2Items"))
	{
		if (g_bTF2ItemsBackupHooked)
		{
			UnhookEvent("post_inventory_application", Event_PlayerInventoryCheck, EventHookMode_Pre);
			
			for (new iClient = 1; iClient <= MaxClients; iClient ++)
			{
	
				if (IsClientInGame(iClient) && ! IsClientSpectator(iClient))
				{
					ForceCachedLoadoutRefresh(iClient);
				}
			}
		}
	}
	else if (StrEqual(Name, "steamtools"))
	{
		g_bSteamTools = true;
	}
}

/**
 * Keeps track of Escalation's dependencies. And takes measures if one is unloaded.
 *
 * @param Name		The name of the library that got removed.
 *
 * @noreturn
 */
public OnLibraryRemoved (const String:Name[])
{
	if (StrEqual(Name, "Escalation_CustomAttributes"))
	{
		SetFailState("Escalation_CustomAttributes has been unloaded, the plugin can not continue operation.")

	}
	else if (StrEqual(Name, "TF2Attributes"))
	{
		SetFailState("TF2Attributes has been unloaded, the plugin can not continue operation.")

	}
	else if (StrEqual(Name, "TF2Items"))
	{
		if (! g_bTF2ItemsBackupHooked)
		{
			HookEvent("post_inventory_application", Event_PlayerInventoryCheck, EventHookMode_Pre);
		}
	}
	else if (StrEqual(Name, "steamtools", false))
	{
		g_bSteamTools = false;
	}
	else if (StrEqual(Name, "adminmenu"))
	{
		g_hAdminMenu = INVALID_HANDLE;
	}
}

/**
 * Sets the game's description once SteamTools is ready to do it.
 *
 * @noreturn
 */
public Steam_FullyLoaded ()
{
	decl String:FormattedString[256];
	Format(FormattedString, sizeof(FormattedString), "%s (%s)", PLUGIN_NAME, PLUGIN_VERSION);
	
	Steam_SetGameDescription(FormattedString);
}

/**
 * Checks if the plugin is disabled.
 *
 * @return True if the plugin is disabled, false if it enabled.
 */
bool:IsPluginDisabled ()
{
	if  (g_bPluginDisabledForMap || g_bPluginDisabledAdmin)
	{
		return true;
	}
	else
	{
		return false;
	}
}


/************************CONFIG LOADING FUNCTIONS************************/

/**
 * Reads and loads up Escalation's base config files.
 *
 * @noreturn
 */
ExecuteConfigs ()
{
	new Handle:hUpgrades = CreateKeyValues("escalation_upgradeinfo");
	new Handle:hUpgradeWeaponInfo = CreateKeyValues("escalation_weaponinfo");
	new Handle:hUpgradeClassInfo = CreateKeyValues("escalation_classinfo");
	
	decl String:UpgradesPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, UpgradesPath, sizeof(UpgradesPath), "configs/escalation/escalation_upgrades.cfg");
	
	decl String:WeaponInfoPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, WeaponInfoPath, sizeof(WeaponInfoPath), "configs/escalation/escalation_weaponinfo.cfg");

	decl String:ClassInfoPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ClassInfoPath, sizeof(ClassInfoPath), "configs/escalation/escalation_classinfo.cfg");

	decl String:CustomAttributesPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, CustomAttributesPath, sizeof(CustomAttributesPath), "configs/escalation/Escalation_CustomAttributes.cfg");
	
	if (! FileToKeyValues(hUpgrades, UpgradesPath))
	{
		SetFailState("Unable to open config file for upgrades: escalation_upgrades.cfg");
	}
	if (! FileToKeyValues(hUpgradeWeaponInfo, WeaponInfoPath))
	{
		SetFailState("Unable to open config file for upgrades: escalation_weaponinfo.cfg");
	}
	
	if (! FileToKeyValues(hUpgradeClassInfo, ClassInfoPath))
	{
		SetFailState("Unable to open config file for upgrades: escalation_classinfo.cfg");
	}

	Esc_LoadCustomAttributeFile(CustomAttributesPath);
	
	WeaponInfoManager_Destroy(g_WeaponInfoManager[0]);
	WeaponInfoManager_Construct(g_WeaponInfoManager[0]);
	
	MenuCache_Destroy(g_UpgradeMenuCache[0]);
	MenuCache_Construct(g_UpgradeMenuCache[0]);
	
	UpgradeDataStore_Destroy(g_UpgradeDataStore[0]);
	UpgradeDataStore_Construct(g_UpgradeDataStore[0]);
	
	ClassInfoStore_Destroy(g_ClassInfoStore[0]);
	ClassInfoStore_Construct(g_ClassInfoStore[0]);
	
	UpgradeDescriptions_Destroy(g_UpgradeDescriptions[0]);
	UpgradeDescriptions_Construct(g_UpgradeDescriptions[0]);
	
	BannedUpgrades_ResetBannedCombos(g_BannedUpgrades[0]);
	
	LoadWeaponInfo(hUpgradeWeaponInfo);
	LoadClassInfo(hUpgradeClassInfo);
	LoadUpgradeInfo(hUpgrades);
	BuildUpgradeMenus(hUpgradeWeaponInfo);
	BuildClassUpgradeMenus(hUpgradeClassInfo);
	
	CloseHandle(hUpgrades);
	CloseHandle(hUpgradeWeaponInfo);
	CloseHandle(hUpgradeClassInfo);
	
	//Call the Forward notifying other plugins that the core configs are ready.
	Call_StartForward(g_hCoreConfigsLoaded); //Esc_CoreConfigsLoaded
	Call_Finish();
}

/**
 * Loads a WeaponInfo KeyValue file into memory. (See escalation_weaponinfo.cfg for how the file is structured.)
 *
 * @param hWeaponInfo		A handle to a KeyValue structure to load.
 *
 * @noreturn
 */
LoadWeaponInfo (Handle:hWeaponInfo)
{
	KvRewind(hWeaponInfo); //You never know, this may be handy for catching an error some day...
	
	KvGotoFirstSubKey(hWeaponInfo);
	
	do
	{
		decl String:SectionName[32];
		decl String:ClassName[32];
		KvGetSectionName(hWeaponInfo, SectionName, sizeof(SectionName));

		SeperateString(SectionName, sizeof(SectionName), "@", ClassName, sizeof(ClassName));
		
		//Fetch the weapon's parent, slot and class.
		new iParent = KvGetNum(hWeaponInfo, "useparent", WEAPONINFO_NO_PARENT);
		new iSlot = KvGetNum(hWeaponInfo, "slot", WEAPONINFO_INVALID_SLOT);
		new TFClassType:iClass = GetClassID(ClassName);
		
		WeaponInfoManager_AddWeapon(g_WeaponInfoManager[0], StringToInt(SectionName), iParent, iSlot, iClass);
	
		//Go through the values of this key.
		KvGotoFirstSubKey(hWeaponInfo, false);		
		do
		{
			decl String:ValueName[UPGRADE_NAME_MAXLENGTH];
			new iValue;
			KvGetSectionName(hWeaponInfo, ValueName, sizeof(ValueName));
			
			if (StrEqual(ValueName, "useparent") || StrEqual(ValueName, "slot"))
			{
				continue;
			}
			else if (StrEqual(ValueName, "banupgrade"))
			{
				decl String:BannedUpgrade[UPGRADE_NAME_MAXLENGTH];
			
				KvGetString(hWeaponInfo, NULL_STRING, BannedUpgrade, sizeof(BannedUpgrade));
			
				BannedUpgrades_BanCombo(g_BannedUpgrades[0], StringToInt(SectionName), BannedUpgrade);
			}
			
			iValue = KvGetNum(hWeaponInfo, NULL_STRING);
			
			
			WeaponInfoManager_SetWeaponPermissions(g_WeaponInfoManager[0], StringToInt(SectionName), ValueName, WeaponUpgradePermissions:iValue, iClass);
			
		} while (KvGotoNextKey(hWeaponInfo, false));
		
		KvGoBack(hWeaponInfo);
		
	} while (KvGotoNextKey(hWeaponInfo));
	

	KvRewind(hWeaponInfo);
}

/**
 * Loads a ClassInfo KeyValue file into memory. (See escalation_classinfo.cfg for how the file is structured.)
 *
 * @param hClassInfo		A handle to a KeyValue structure to load.
 *
 * @noreturn
 */
LoadClassInfo (Handle:hClassInfo)
{
	for	(new iClass = 1; iClass <= 9; iClass++)
	{
		decl String:ClassName[32];		
		ClassIDToName(TFClassType:iClass, ClassName, sizeof(ClassName));
			
		KvJumpToKey(hClassInfo, ClassName);
		
		KvGotoFirstSubKey(hClassInfo, false);
		do
		{
			decl String:ValueName[32];
			KvGetSectionName(hClassInfo, ValueName, sizeof(ValueName));
			
			ClassInfoStore_SetUpgradeAllowed(g_ClassInfoStore[0], TFClassType:iClass, ValueName);
			
		} while (KvGotoNextKey(hClassInfo, false));
		
		KvRewind(hClassInfo);
	}
}

/**
 * Loads a UpgradeInfo KeyValue file into memory. (See escalation_upgrades.cfg for how the file is structured.)
 *
 * @param hUpgradeInfo		A handle to a KeyValue structure to load.
 *
 * @noreturn
 */
LoadUpgradeInfo (Handle:hUpgradeInfo)
{
	KvRewind(hUpgradeInfo);
	
	KvGotoFirstSubKey(hUpgradeInfo);	
	
	do
	{
		decl String:SectionName[UPGRADE_NAME_MAXLENGTH];
		KvGetSectionName(hUpgradeInfo, SectionName, sizeof(SectionName));

		new tmpUpgradeData[UpgradeData];
		UpgradeData_Construct(tmpUpgradeData[0], KvGetNum(hUpgradeInfo, "cost"), KvGetNum(hUpgradeInfo, "slot"), bool:KvGetNum(hUpgradeInfo, "passive"));
		
		KvJumpToKey(hUpgradeInfo, "levels");
		
		KvGotoFirstSubKey(hUpgradeInfo);
		
		do
		{
			new tmpLevelData[LevelData];
			
			LevelData_Construct(tmpLevelData[0]);
			
			KvGotoFirstSubKey(hUpgradeInfo);

			do
			{
				LevelData_AddAttribute(tmpLevelData[0], KvGetNum(hUpgradeInfo, "attribute"), KvGetFloat(hUpgradeInfo, "value"), bool:KvGetNum(hUpgradeInfo, "ispercent"));	
			} while (KvGotoNextKey(hUpgradeInfo));

			KvGoBack(hUpgradeInfo);
			
			UpgradeData_AddLevel(tmpUpgradeData[0], tmpLevelData[0]);
			
		} while (KvGotoNextKey(hUpgradeInfo));
		
		KvGoBack(hUpgradeInfo);
		KvGoBack(hUpgradeInfo);
		
		UpgradeDataStore_AddUpgrade(g_UpgradeDataStore[0], SectionName, tmpUpgradeData[0], sizeof(tmpUpgradeData));
		
		KvJumpToKey(hUpgradeInfo, "description_information");
		
		new iIndex;
		
		KvGotoFirstSubKey(hUpgradeInfo);
		do
		{
			new iLevel;
		
			++ iIndex;
		
			decl String:TranslationString[128];
			KvGetString(hUpgradeInfo, "translation_string", TranslationString, sizeof(TranslationString));
			
			UpgradeDescriptions_AddDescription(g_UpgradeDescriptions[0], SectionName, iIndex, TranslationString);
			
			KvGotoFirstSubKey(hUpgradeInfo);
			do
			{
				++ iLevel;
			
				new iValue;
				
				iValue = KvGetNum(hUpgradeInfo, "value");
				
				UpgradeDescriptions_AddValue(g_UpgradeDescriptions[0], SectionName, iIndex, iLevel, iValue);
				
			} while(KvGotoNextKey(hUpgradeInfo));
			
			KvGoBack(hUpgradeInfo);
			
		} while(KvGotoNextKey(hUpgradeInfo));
		
		KvGoBack(hUpgradeInfo);
		KvGoBack(hUpgradeInfo);
		
	}  while (KvGotoNextKey(hUpgradeInfo)); 
	
	KvGoBack(hUpgradeInfo);
}

/**
 * Builds upgrade menus for weapons from a WeaponInfo KV file.
 *
 * @param hWeaponInfo		A handle to a KeyValue structure to build the menus from.
 *
 * @noreturn
 */
BuildUpgradeMenus (Handle:hWeaponInfo)
{
	KvRewind(hWeaponInfo); //You never know, this may be handy for catching an error some day...
	
	KvGotoFirstSubKey(hWeaponInfo);

	new iContinueAt = -1;
	
	do
	{
		
		if (iContinueAt != -1)
		{
			KvRewind(hWeaponInfo);
			
			if (! KvJumpToKeySymbol(hWeaponInfo, iContinueAt))
			{			
				ThrowError("Attempt to jump to invalid section. %i - iContinueAt", iContinueAt);
			}
			
			if (! KvGotoNextKey(hWeaponInfo))
			{
				break;
			}	
			
			iContinueAt = -1;
		}
		
		
		decl String:SectionName[32];
		decl String:ClassName[32];
		KvGetSectionName(hWeaponInfo, SectionName, sizeof(SectionName));

		SeperateString(SectionName, sizeof(SectionName), "@", ClassName, sizeof(ClassName));

		new TFClassType:iClass = GetClassID(ClassName);
		
		//Create the menu.
		new Handle:menu = CreateMenu(Menu_UpgradeHandler, MenuAction_Select | MenuAction_Cancel | MenuAction_DisplayItem | MenuAction_DrawItem);
		new Handle:hBannedUpgrades = CreateArray(UPGRADE_NAME_MAXLENGTH / 4); //An ADT array used to keep track of which upgrades are banned by a child of a weapon or have already been added.
		new Handle:hAllowedUpgrades = CreateArray(UPGRADE_NAME_MAXLENGTH / 4);


		
		//Set the title.
		SetMenuTitle(menu, "%T", "Select_Upgrade", LANG_SERVER); 
		
		//Go through the values of this key.
		KvGotoFirstSubKey(hWeaponInfo, false);
		for ( ; ; ) //This loop is a bit more hacky than the other ones due to the inheritance system of the weapons in the keyvalue file.
		{
			decl String:ValueName[UPGRADE_NAME_MAXLENGTH];
			new WeaponUpgradePermissions:iValue = WeaponUpgradePermissions:KvGetNum(hWeaponInfo, NULL_STRING);
			KvGetSectionName(hWeaponInfo, ValueName, sizeof(ValueName));

			//Handle the parenting system.
			if (StrEqual(ValueName, "useparent"))
			{
				KvGoBack(hWeaponInfo);
			
				if (iContinueAt == -1)
				{
					if (! KvGetSectionSymbol(hWeaponInfo, iContinueAt)) //Save where to continue the iteration at.
					{
						CloseHandle(menu);
						CloseHandle(hBannedUpgrades);
						CloseHandle(hAllowedUpgrades);
					
						LogError("Unable to get section symbol in keyvalue structure. Current Section - %s Current Key - %s", SectionName, ValueName);
						
						return;
					}
				}
				
				KvRewind(hWeaponInfo);

				
				decl String:parent[8];
				IntToString(_:iValue, parent, sizeof(parent));
				
				KvJumpToKey(hWeaponInfo, parent);
				KvGotoFirstSubKey(hWeaponInfo, false);
				
				continue;
			}

			if (StrEqual(ValueName, "slot"))
			{
				if (! KvGotoNextKey(hWeaponInfo, false))
				{
					break;
				}
			}
			
			if (iValue == Upgrade_Not_Allowed || iValue == Upgrade_Allowed_Hidden)
			{
				PushArrayString(hBannedUpgrades, ValueName);
			}
			
			if (FindStringInArray(hBannedUpgrades, ValueName) == -1)
			{
				PushArrayString(hAllowedUpgrades, ValueName);
				PushArrayString(hBannedUpgrades, ValueName);
			}
			
			if (! KvGotoNextKey(hWeaponInfo, false))
			{
				break;
			}
		}
		
		KvGoBack(hWeaponInfo);
		
		new iWeaponID = StringToInt(SectionName) + (_:iClass * ALL_CLASS_WEAPON_OFFSET);

		SortADTArray(hAllowedUpgrades, Sort_Ascending, Sort_String);
		
		for (new i = 0; i < GetArraySize(hAllowedUpgrades); i ++)
		{
			decl String:UpgradeName[UPGRADE_NAME_MAXLENGTH];

			GetArrayString(hAllowedUpgrades, i, UpgradeName, sizeof(UpgradeName));

			AddMenuItem(menu, UpgradeName, "UNFORMATTED_UPGRADE_TEXT");
			AddMenuItem(menu, "Menu_Level", "UNFORMATTED_LEVEL_TEXT", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "Menu_Cost", "UNFORMATTED_COST_TEXT", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "UPGRADE_DESC_1", "UNFORMATTER_DESCRIPTION", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "UPGRADE_DESC_2", "UNFORMATTED_DESCRIPTION", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "NODRAW", "", ITEMDRAW_SPACER);
			AddMenuItem(menu, "NODRAW", "", ITEMDRAW_SPACER);
		}
		
		//Add the back button.
		SetMenuExitBackButton(menu, true);

		//Store the menu in the cache.
		MenuCache_AddMenu(g_UpgradeMenuCache[0], menu, iWeaponID);
		
		CloseHandle(hAllowedUpgrades);
		CloseHandle(hBannedUpgrades);
		
	} while (KvGotoNextKey(hWeaponInfo));
	

	KvRewind(hWeaponInfo);
}

/**
 * Builds upgrade menus for classes from a ClassInfo KV file.
 *
 * @param hClassInfo		A handle to a KeyValue structure to build the menus from.
 *
 * @noreturn
 */
BuildClassUpgradeMenus (Handle:hClassInfo)
{
	KvRewind(hClassInfo);

	for	(new iClass = 1; iClass <= 9; iClass++)
	{
		new Handle:menu = CreateMenu(Menu_UpgradeHandler, MenuAction_Select | MenuAction_Cancel | MenuAction_DisplayItem | MenuAction_DrawItem);

		//Set the title.
		SetMenuTitle(menu, "%T", "Select_Upgrade", LANG_SERVER);
	
		decl String:ClassName[32];		
		ClassIDToName(TFClassType:iClass, ClassName, sizeof(ClassName));
			
		KvJumpToKey(hClassInfo, ClassName);
		
		KvGotoFirstSubKey(hClassInfo, false);
		do
		{
			decl String:ValueName[32];
			KvGetSectionName(hClassInfo, ValueName, sizeof(ValueName));
			
			//decl String:DefaultName[128];	
			//Format(DefaultName, sizeof(DefaultName), "%T", ValueName, LANG_SERVER);
			
			AddMenuItem(menu, ValueName, "UNFORMATTED_UPGRADE_TEXT");
			AddMenuItem(menu, "Menu_Level", "UNFORMATTED_LEVEL_TEXT", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "Menu_Cost", "UNFORMATTED_COST_TEXT", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "UPGRADE_DESC_1", "UNFORMATTER_DESCRIPTION", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "UPGRADE_DESC_2", "UNFORMATTED_DESCRIPTION", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "NODRAW", "", ITEMDRAW_SPACER);
			AddMenuItem(menu, "NODRAW", "", ITEMDRAW_SPACER);
		} while (KvGotoNextKey(hClassInfo, false));
		
		//Add the back button.
		SetMenuExitBackButton(menu, true);
		
		//Store the menu in the cache.
		MenuCache_AddMenu(g_UpgradeMenuCache[0], menu, iClass * CLASS_MENU_OFFSET);
		
		KvRewind(hClassInfo);
	}
}

/************************MAP EVENTS************************/

/**
 * Prepares Escalation for the map and gamemode.
 *
 * @noreturn
 */
public OnMapStart()
{
	//Create our trie for tracking CP ownership.
	g_hPointOwner = CreateTrie();

	//Reset this here.
	g_bPluginDisabledForMap = false;
	
	new Handle:hGameInfo = CreateKeyValues("escalation_gameinfo");
	
	decl String:GameInfoPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, GameInfoPath, sizeof(GameInfoPath), "configs/escalation/escalation_gameinfo.cfg");

	if (! FileToKeyValues(hGameInfo, GameInfoPath))
	{
		SetFailState("Unable to open config file for escalation_gameinfo: escalation_gameinfo.cfg");
	}

	ExecuteGameInfoConfig(hGameInfo);
	
	CloseHandle(hGameInfo);
	
	if (! IsPluginDisabled() &&  ! g_bPluginStarted)
	{
		StartPlugin();
	}
	else if (IsPluginDisabled() && g_bPluginStarted)
	{
		LogMessage("%T", "Plugin_Disabled_Nosupport", LANG_SERVER);
		
		CPrintToChatAll("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
	}
	
	for (new iTeam = 0; iTeam < 4; iTeam++) //We reset the objective credits for all the teams.
	{
		Set_iObjectiveCredits(0, SET_ABSOLUTE, iTeam);		
	}
}

/**
 * Cleans up handles made by OnMapStart.
 *
 * @noreturn
 */
public OnMapEnd()
{
	CloseHandle(g_hPointOwner);
	g_hPointOwner = INVALID_HANDLE;
}

/**
 * Used by OnMapStart to read escalation_gameinfo.cfg
 *
 * @param hGameInfo		A handle to a KeyValue structure to get the config information from.
 *
 * @error Missing keyvalue sections.
 * @noreturn
 */
ExecuteGameInfoConfig(Handle:hGameInfo)
{
	decl String:Map[64]; //Stores the name of the map.
	decl String:Gamemode[32]; //Stores the name of the gamemode config to use.
	decl String:Prefix[32]; //Stores the prefix of the map if needed.
	
	GetCurrentMap(Map, sizeof(Map));

	ReadGameConfigSection(hGameInfo, "*"); //Execute the base config.
	
	//TODO: Insert string to lower here.
	
	if (! (KvJumpToKey(hGameInfo, "map_configss") || KvJumpToKey(hGameInfo, "map_configs")))
	{
		LogError("Failure to find \"map_configs\" section in Escalation's gamemode config. The plugin will fall back to the default values for all gamemode settings.");
		
		return;
	}
	
	KvGetString(hGameInfo, Map, Gamemode, sizeof(Gamemode));
	
	//If the map wasn't specified in the config file we fall back to using it's prefix. If this fails the plugin will just use the default config values.
	if (Gamemode[0] == 0)
	{
		if (! KvJumpToKey(hGameInfo, "prefixes"))
		{
			LogError("Failure to find \"prefixes\" section in Escalation's gamemode config. The plugin will fall back to the default values for all gamemode settings.");
			
			return;
		}
		
		SplitString(Map, "_", Prefix, sizeof(Prefix));		
		KvGetString(hGameInfo, Prefix, Gamemode, sizeof(Gamemode));
		
		if (Gamemode[0] == 0)
		{
			LogError("Failure to find gamemode define for map prefix %s section in Escalation's gamemode config. The plugin will fall back to the default values for all gamemode settings.", Prefix);
	
			return;
		}
	}
	
	if (StrEqual(Gamemode, "NOSUPPORT")) //No support for this gamemode? Shame, we'll just have to disable the plugin for the map.
	{
		g_bPluginDisabledForMap = true;
	
		return;
	}

	ReadGameConfigSection(hGameInfo, Gamemode);
}

/**
 * Used by ExecuteGameInfoConfig to read sub-sections in escalation_gameinfo.cfg.
 *
 * @param hGameInfo		A handle to a KeyValue structure to get the config information from.
 *
 * @noreturn
 */
ReadGameConfigSection(Handle:hGameInfo, const String:ConfigName[])
{
	KvRewind(hGameInfo); //Reset this before trying to continue.
	
	if (! KvJumpToKey(hGameInfo, ConfigName))
	{
		return;
	}

	KvGotoFirstSubKey(hGameInfo);
	
	do
	{
		decl String:SectionName[SECTION_NAME_MAX_LENGTH];	
		KvGetSectionName(hGameInfo, SectionName, sizeof(SectionName));

		KvGotoFirstSubKey(hGameInfo, false);

		do
		{
			new bool:bIsFloat = false;

			decl String:ValueName[VALUE_NAME_MAX_LENGTH];
			decl String:Value[32];

			KvGetSectionName(hGameInfo, ValueName, sizeof(ValueName));
			KvGetString(hGameInfo, NULL_STRING, Value, sizeof(Value));

			if (Value[0] == 'f')
			{
				bIsFloat = true;
				ReplaceStringEx(ValueName, sizeof(ValueName), "f", "", -1, -1, false);
			}

			new any:Cell;
			
			if (bIsFloat)
			{
				Cell = StringToFloat(Value);
			}
			else
			{
				Cell = StringToInt(Value);
			}

			KVMap_SetCell(g_GameInfo[0], SectionName, ValueName, Cell);

		} while (KvGotoNextKey(hGameInfo, false))

		KvGoBack(hGameInfo);

	} while (KvGotoNextKey(hGameInfo))

	KvRewind(hGameInfo);
}

/************************CVAR EVENTS************************/

/**
 * Disables/Enables the plugin based off the cvar. (Just a normal CVar hook, see console.inc for information on the arguments.)
 *
 * @noreturn
 */
public CVar_Enable_Changed (Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:bNewValue = ! bool:StringToInt(newVal);
	
	if (bNewValue == true)
	{
		if (g_bPluginStarted)
		{
			StopPlugin();
		}

		CPrintToChatAll("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");

		g_bPluginDisabledAdmin = true;
	}
	else if (bNewValue == false)
	{
		g_bPluginDisabledAdmin = false;

		if (! IsPluginDisabled() && ! g_bPluginStarted)
		{
			StartPlugin();

			for (new team = 0; team < 4; team++) //We reset the objective credits for all the teams.
			{
				Set_iObjectiveCredits(0, SET_ABSOLUTE, team);		
			}
		}
	}
}

/**
 * Handles most CVar changes.
 *
 * @noreturn
 */
public CVar_Misc_Changed (Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == CVar_HUD_Reminder)
	{
		g_bHUDReminder = bool:StringToInt(newVal);
	}
	else if (cvar == CVar_Chat_Reminder)
	{
		g_bChatReminder = bool:StringToInt(newVal);
	}
}

/************************CORE PLAYER EVENTS************************/

/**
 * Creates a PlayerData object for newly connected players and creates timers for reminding the player to open the upgrade menu.
 *
 * @param iClient		The index of the client connecting.
 *
 * @noreturn
 */
public OnClientConnected (iClient)
{
	if (IsPluginDisabled() || ! g_bPluginStarted)
	{
		return;
	}

	if (! IsClientValid(iClient))
	{
		return;
	}
	
	//Create the client's data object.
	PlayerData_ConstructFull(g_PlayerData[iClient][0], iClient);

	g_bClientHasData[iClient] = true;
	
	//Call the Forward Notifying Other Plugins that the client's data is ready.
	Call_StartForward(g_hClientDataReady); //Esc_PlayerDataCreated
	Call_PushCell(iClient);
	Call_Finish();
	
	new iStartingCredits;
	new iCompensateCredits;
	new bool:bCompensateObjectiveCredits;

	KVMap_IndexGetCell(g_GameInfo[0], "ClientConnected.StartingCredits", iStartingCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "ClientConnected.CompensateCredits", iCompensateCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "PlayerChangeTeam.CompensateObjectiveCredits", bCompensateObjectiveCredits);

	//Set their starting credits.
	Set_iClientCredits(iStartingCredits, SET_ABSOLUTE, iClient, ESC_CREDITS_STARTING);

	if (bCompensateObjectiveCredits)
	{
		PlayerData_SetGiveObjectiveCredits(g_PlayerData[iClient][0], true);
	}

	if (iCompensateCredits == 1)
	{
		Set_iClientCredits(GetAverageCredits(iClient), SET_ADD, iClient, ESC_CREDITS_COMPENSATE);
	}
	else if (iCompensateCredits == 2)
	{
		new iAverage = GetAverageCredits(iClient);
		Set_iClientCredits(iAverage - (iAverage/4), SET_ADD, iClient, ESC_CREDITS_COMPENSATE);
	}

	if (g_bChatReminder)
	{
		CreateTimer(15.0, Timer_MenuReminder, GetClientUserId(iClient), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}

	if (g_bHUDReminder)
	{
		CreateTimer(60.0, Timer_AnnoyingMenuReminder, GetClientUserId(iClient), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}

	if (! PlayerData_GetReadCookies(g_PlayerData[iClient][0]) && AreClientCookiesCached(iClient))
	{
		decl String:CookieValue[32];
		GetClientCookie(iClient, g_hMenuOpenedCookie, CookieValue, sizeof(CookieValue));

		new bool:bValue = bool:StringToInt(CookieValue);

		if (bValue)
		{
			PlayerData_SetHasOpenedMenu(g_PlayerData[iClient][0]);
		}
		
		PlayerData_SetCookiesRead(g_PlayerData[iClient][0]);
	}
}

/**
 * Cleans up a player's data when they disconnect.
 *
 * @param iClient		The index of the client disconnecting.
 *
 * @noreturn
 */
public OnClientDisconnect (iClient)
{
	if (IsPluginDisabled() || ! g_bPluginStarted)
	{
		return;	
	}

	if (! IsClientValid(iClient))
	{
		return;
	}
	
	//Call the Forward Notifying Other Plugins that the client's data is about to be destroyed.
	Call_StartForward(g_hClientDataDestroy); //Esc_PlayerDataCreated
	Call_PushCell(iClient);
	Call_Finish();

	//Save any cookie values.
	new String:MenuOpened[4];
	IntToString(PlayerData_GetHasOpenedMenu(g_PlayerData[iClient][0]), MenuOpened, sizeof(MenuOpened));

	SetClientCookie(iClient, g_hMenuOpenedCookie, MenuOpened);
	
	//Destroy the client's data object.
	PlayerData_Destroy(g_PlayerData[iClient][0]);
	
	g_bClientHasData[iClient] = false;
	
	//Clear the attributes.
	PlayerAttributeManager_ClearAttributes(iClient);
	WeaponAttributes_ResetData(iClient);

	//Reset the death counters of the other clients.
	for (new i = 1; i <= MaxClients; i++)
	{
		//Reset the death trackers.
		if (i != iClient && IsClientValid(i) && g_bClientHasData[i])
		{
			PlayerData_ResetDeathCounter(g_PlayerData[i][0], iClient);
		}
	}


}

/**
 * Reads in a client's cookies.
 *
 * @param iClient		The index of the client whose cookies are cached.
 *
 * @noreturn
 */
public OnClientCookiesCached (iClient)
{
	if (! g_bClientHasData[iClient] || PlayerData_GetReadCookies(g_PlayerData[iClient][0]))
	{
		return;
	}
	
	decl String:CookieValue[32];
	GetClientCookie(iClient, g_hMenuOpenedCookie, CookieValue, sizeof(CookieValue));
	
	new bool:bValue = bool:StringToInt(CookieValue);
	
	if (bValue)
	{
		PlayerData_SetHasOpenedMenu(g_PlayerData[iClient][0]);
	}
	
	PlayerData_SetCookiesRead(g_PlayerData[iClient][0]);
}

/**
 * Handles the various chat triggers for the upgrade menu.
 *
 * @param iClient		The index of the client saying the chat message.
 * @param Command		The command being executed.
 * @param Args			Chat argument string.
 *
 * @noreturn
 */
public Action:OnClientSayCommand(iClient, const String:Command[], const String:Args[])
{
	static const String:ChatTriggers[4][] = 
	{
		"upgrade",
		"upgrades",
		"!upgrade",
		"!upgrades"
	};

	static const String:SilentTriggers[2][] =
	{
		"/upgrade",
		"/upgrades"
	};

	for (new i = 0; i < 4; i ++)
	{
		if (StrEqual(ChatTriggers[i], Args, false))
		{
			Command_UpgradeMenu(iClient, 0);
			
			return Plugin_Continue;
		}
	}

	for (new i = 0; i < 2; i ++)
	{
		if (StrEqual(SilentTriggers[i], Args, false))
		{
			Command_UpgradeMenu(iClient, 0);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

/**
 * Processes a client's upgrade queue when they resupply. (Just a normal event hook, see events.inc for information on the arguments.)
 *
 * @noreturn
 */
public Event_PlayerResupply (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (iClient == 0)
	{
		return;
	}

	ProcessUpgradeQueue(iClient);
}

/**
 * Handles giving a client their team's objective credits when they join it. 
 *
 * @noreturn
 */
public Event_PlayerChangeTeam (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserID = GetEventInt(event, "userid");
	new iClient = GetClientOfUserId(iClient);
	new iTeam = GetEventInt(event, "team");
	new iOldTeam = GetEventInt(event, "oldteam");
	new bool:bClientDisconnected = GetEventBool(event, "disconnect");

	new bool:bSwapObjectiveCredits;	
	KVMap_IndexGetCell(g_GameInfo[0], "PlayerChangeTeam.SwapObjectiveCredits", bSwapObjectiveCredits);

	//Safety shibboleth to make sure stuff stays securely snug.
	if (bClientDisconnected || iClient == 0)
	{
		return;
	}

	if (PlayerData_GetGiveObjectiveCredits(g_PlayerData[iClient][0]))
	{
		Set_iClientCredits(Get_iObjectiveCredits(iTeam), SET_ADD, iClient, ESC_CREDITS_OBJECTIVE);
		PlayerData_SetGiveObjectiveCredits(g_PlayerData[iClient][0], true);
	}
	else if (bSwapObjectiveCredits)
	{	
		RefundUpgrades(iClient);
		Set_iClientCredits(Get_iObjectiveCredits(iOldTeam), SET_SUBTRACT, iClient, ESC_CREDITS_OBJECTIVE);
		Set_iClientCredits(Get_iObjectiveCredits(iTeam), SET_ADD, iClient, ESC_CREDITS_OBJECTIVE);
	}

	CreateTimer(0.25, Timer_ForceHUDTextUpdate, iUserID);
}

/**
 * Refunds a client's upgrades when they change class, processes their upgrade queue and forces their credit counter on their HUD to update.
 *
 * @noreturn
 */
public Event_PlayerChangeClass (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserID = GetEventInt(event, "userid");
	new iClient = GetClientOfUserId(iUserID);

	if (iClient == 0)
	{
		return;
	}

	RefundUpgrades(iClient);

	if (IsPlayerAlive(iClient))
	{
		ProcessUpgradeQueue(iClient);
	}

	CreateTimer(0.25, Timer_ForceHUDTextUpdate, iUserID);
}

/**
 * Forces the client's credit counter on their HUD to update.
 *
 * @noreturn
 */
public Event_PlayerSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserID = GetEventInt(event, "userid");
	new iClient = GetClientOfUserId(iUserID);
	
	if (iClient == 0)
	{
		return;
	}
	
	CreateTimer(0.25, Timer_ForceHUDTextUpdate, iUserID);
}

/************************PLAYER TIMERS************************/

/**
 * Displays a reminder the client to open the upgrade menu. (Just a normal timer callback, see timers.inc for information on the arguments.)
 *
 * @noreturn
 */
public Action:Timer_MenuReminder (Handle:timer, any:data)
{
	new iClient = GetClientOfUserId(data);

	if (iClient == 0 || ! g_bClientHasData[iClient] || IsPluginDisabled() || ! g_bChatReminder)
	{
		return Plugin_Stop;
	}

	if (! IsClientInGame(iClient))
	{
		return Plugin_Continue;
	}

	if (PlayerData_GetHasOpenedMenu(g_PlayerData[iClient][0]))
	{
		return Plugin_Stop;
	}
	else
	{
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Open_Menu_Reminder");

		return Plugin_Continue;
	}
}

/**
 * Displays an annoying reminder on the client's HUD to open the upgrade menu.
 *
 * @noreturn
 */
public Action:Timer_AnnoyingMenuReminder (Handle:timer, any:data)
{
	new iClient = GetClientOfUserId(data);

	if (iClient == 0 || ! g_bClientHasData[iClient] || IsPluginDisabled() || ! g_bHUDReminder)
	{
		return Plugin_Stop;
	}
	
	if (! IsClientInGame(iClient))
	{
		return Plugin_Continue;
	}

	if (PlayerData_GetHasOpenedMenu(g_PlayerData[iClient][0]))
	{
		return Plugin_Stop;
	}
	else
	{
		PlayerData_DisplayHudReminder(g_PlayerData[iClient][0]);

		return Plugin_Continue;
	}
}

/**
 * Forces a client's credit counter on their HUD to update.
 *
 * @noreturn
 */
public Action:Timer_ForceHUDTextUpdate (Handle:timer, any:data)
{
	new iClient = GetClientOfUserId(data);

	if (iClient != 0 && g_bClientHasData[iClient] && ! IsPluginDisabled())
	{
		PlayerData_ForceHudTextUpdate(g_PlayerData[iClient][0]);
	}
	else
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

/************************PLAYER LOADOUT EVENTS************************/

/**
 * Updates a client's cached weapon entities and item definition indexes.
 *
 * @param iClient				The index of the client that got the item.
 * @param ClassName				The classname of the item the client was just given.
 * @param iItemDefinitionIndex	The item definition index of the item the client was given.
 * @param iItemLevel			The level of the item the client was just given.
 * @param iItemQuality			The quality of the item the client was just given.
 * @param iEntityIndex			The entity index of the item the client was given.
 *
 * @noreturn
 */
public TF2Items_OnGiveNamedItem_Post (iClient, String:ClassName[], iItemDefinitionIndex, iItemLevel, iItemQuality, iEntityIndex)
{
	if (IsPluginDisabled())
	{
		return;
	}

	new Handle:hStack = CreateStack();

	PushStackCell(hStack, EntIndexToEntRef(iEntityIndex));
	PushStackCell(hStack, iItemDefinitionIndex);
	PushStackCell(hStack, iClient);
	
	RequestFrame(FrameCallback_GiveNamedItem, hStack);
}

/**
 * Updates a client's cached weapon entities and item definition indexes when TF2Items is not available.
 *
 * @noreturn
 */
public Event_PlayerInventoryCheck (Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (iClient == 0)
	{
		return;
	}

	new bool:bHandledWearables;
	
	for (new i = 0; i < UPGRADABLE_SLOTS; i++)
	{
		new iEntity = GetPlayerWeaponSlot(iClient, i);
		
		//Handle the wearables.
		if (! IsValidEntity(iEntity) && ! bHandledWearables)
		{
			decl iWearables[PLAYER_MAX_WEARABLES];

			new iWearableCount = GetClientWearables(iClient, iWearables, sizeof(iWearables));
			
			for (new iWearableIndex = 0; iWearableIndex < iWearableCount; iWearableIndex ++)
			{
				if (IsDisguiseEntity(iWearables[iWearableIndex]))
				{
					continue;
				}
			
				new iItemDefinitionIndex = GetEntProp(iWearables[iWearableIndex], Prop_Send, "m_iItemDefinitionIndex");
				
				new iSlot = WeaponInfoManager_GetSlot(g_WeaponInfoManager[0], iItemDefinitionIndex, TF2_GetPlayerClass(iClient));
		
				if (iSlot != WEAPONINFO_INVALID_SLOT)
				{
					PlayerData_UpdateWeapon(g_PlayerData[iClient][0], iSlot, iItemDefinitionIndex);
					WeaponAttributes_UpdateWeaponEnt(iClient, iSlot, iWearables[iWearableIndex]);
				}
			}
			
			bHandledWearables = true;
			
			continue;
		}
		
		if (IsDisguiseEntity(iEntity))
		{
			continue;
		}
				
		new iItemDefinitionIndex = GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
		
		new iSlot = WeaponInfoManager_GetSlot(g_WeaponInfoManager[0], iItemDefinitionIndex, TF2_GetPlayerClass(iClient));
		
		if (iSlot != WEAPONINFO_INVALID_SLOT)
		{
			PlayerData_UpdateWeapon(g_PlayerData[iClient][0], iSlot, iItemDefinitionIndex);
			WeaponAttributes_UpdateWeaponEnt(iClient, iSlot, iEntity);
		}
	}
}

/**
 * Callback for updating a client's cached weapon entities and item definition indexes.
 *
 * @noreturn
 */
public FrameCallback_GiveNamedItem (any:aData)
{
	if (IsPluginDisabled())
	{
		return;
	}

	new iClient;
	new iItemDefinitionIndex;
	new iEntity;

	PopStackCell(aData, iClient);
	PopStackCell(aData, iItemDefinitionIndex);
	PopStackCell(aData, iEntity);

	iEntity = EntRefToEntIndex(iEntity);
	
	if (iEntity == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	if (IsDisguiseEntity(iEntity))
	{
		return;
	}
	
	new iSlot = WeaponInfoManager_GetSlot(g_WeaponInfoManager[0], iItemDefinitionIndex, TF2_GetPlayerClass(iClient));

	if (iSlot != WEAPONINFO_INVALID_SLOT)
	{
		PlayerData_UpdateWeapon(g_PlayerData[iClient][0], iSlot, iItemDefinitionIndex);
		WeaponAttributes_UpdateWeaponEnt(iClient, iSlot, iEntity);
	}
	
	CloseHandle(aData);
}

/************************ROUND & SUCH EVENTS************************/

/**
 * Handles giving a client their starting credits.
 * And setting g_bBuyUpgrades and g_bGiveCredits to true.
 *
 * @noreturn
 */
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	
	if (GameRules_GetProp("m_bInWaitingForPlayers"))
	{
		g_bBuyUpgrades = false;
		g_bGiveCredits = false;
	}
	else
	{
		g_bBuyUpgrades = true;
		g_bGiveCredits = true;
	}
	
	new bool:bFullReset = GetEventBool(event, "full_reset");

	new bool:bForceResetOutcome;
	new bool:bForceResetCredits;
	new iStartingCredits;
	
	KVMap_IndexGetCell(g_GameInfo[0], "RoundEvents.ForceResetOutcome", bForceResetOutcome);
	KVMap_IndexGetCell(g_GameInfo[0], "RoundEvents.ResetCredits", bForceResetCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "ClientConnected.StartingCredits", iStartingCredits);
	
	if (bForceResetOutcome)
	{
		bFullReset = bForceResetCredits;
	}
	
	if (bFullReset)
	{
		for (new iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (! IsClientValid(iClient))
			{
				continue;
			}

			Set_iClientCredits(iStartingCredits, SET_ABSOLUTE, iClient, ESC_CREDITS_STARTING | ESC_CREDITS_RESET);
		}
	}

	for (new iClient = 1; iClient <= MaxClients; iClient ++)
	{
		if (IsClientInGame(iClient))
		{
			CreateTimer(0.5, Timer_ForceHUDTextUpdate, GetClientUserId(iClient));
			
			if (! IsClientSpectator(iClient))
			{
				ProcessUpgradeQueue(iClient);
			}
		}
	}
}

/**
 * Handles resetting a client their starting credits.
 * And setting g_bBuyUpgrades and g_bGiveCredits to false.
 *
 * @noreturn
 */
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	new bool:bResetCredits;
	
	if (StrEqual("teamplay_round_stalemate", name, false))
	{
		bResetCredits = true;
	}
	else
	{
		if (GetEventInt(event, "full_round"))
		{
			bResetCredits = true;
		}
	}
	
	new bool:bForceResetOutcome;
	new bool:bForceResetCredits;
	new iStartingCredits;
	
	KVMap_IndexGetCell(g_GameInfo[0], "RoundEvents.ForceResetOutcome", bForceResetOutcome);
	KVMap_IndexGetCell(g_GameInfo[0], "RoundEvents.ResetCredits", bForceResetCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "ClientConnected.StartingCredits", iStartingCredits);

	if (bForceResetOutcome)
	{
		bResetCredits = bForceResetCredits;
	}
	
	if (bResetCredits)
	{
		for (new iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (! IsClientValid(iClient))
			{
				continue;
			}
			
			Set_iClientCredits(iStartingCredits, SET_ABSOLUTE, iClient, ESC_CREDITS_STARTING | ESC_CREDITS_RESET);
		
			for (new TFClassType:iClass = TFClassType:1; iClass <= TFClassType:9; iClass ++) 
			{
				for (new iIndex = 0; iIndex < PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], iClass); iIndex++)
				{
					decl tmpUpgradeQueue[UpgradeQueue];
					PlayerData_GetUpgradeOnQueue(g_PlayerData[iClient][0], iClass, iIndex,  tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
					
					tmpUpgradeQueue[_bOwned] = false;
					
					PlayerData_SetUpgradeOnQueue(g_PlayerData[iClient][0], iClass, iIndex, tmpUpgradeQueue[0]);
				}
			}
		}

		for (new team = 0; team < 4; team++)
		{
			Set_iObjectiveCredits(0, SET_ABSOLUTE, team);
		}
	}
	
	g_bBuyUpgrades = false;
	g_bGiveCredits = false;
}

/************************PLAYER OBJECTIVE EVENTS************************/

/**
 * Gives credits to players when they murder each other and stuff.
 *
 * @noreturn
 */
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}

	new iCreditsOnDeath;
	new iCreditsOnKill;	
	new iDeathMaxStreak;
	new iKillMaxStreak;
	new iDominatedCredits;
	new iDominationCredits;
	new iAssistCredits;
	
	KVMap_IndexGetCell(g_GameInfo[0], "OnDeath.Credits", iCreditsOnDeath);
	KVMap_IndexGetCell(g_GameInfo[0], "OnKill.Credits", iCreditsOnKill);
	KVMap_IndexGetCell(g_GameInfo[0], "OnDeath.MaxStreak", iDeathMaxStreak);
	KVMap_IndexGetCell(g_GameInfo[0], "OnKill.MaxStreak", iKillMaxStreak);
	KVMap_IndexGetCell(g_GameInfo[0], "OnDominated.Credits", iDominatedCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "OnDomination.Credits", iDominationCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "OnAssist.Credits", iAssistCredits);
	
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new iFlags =  GetEventInt(event, "death_flags");
	
	//Increase the death counter count on the client.
	PlayerData_IncrementDeathCounter(g_PlayerData[iClient][0], attacker);
	//Also reset the attacker's death counter on the client.
	PlayerData_ResetDeathCounter(g_PlayerData[attacker][0], iClient);
	
	//Even though these share the same values at the start they can have a different limit set in escalation_gameinfo. For the sake of clean code we store them separately to account for this.
	new iDeathCount = PlayerData_GetDeathCounter(g_PlayerData[iClient][0], attacker);
	new iKillCount = iDeathCount;
	
	if (iClient == 0 || attacker == 0 || iClient == attacker) //Invalid iClient, killed by the world or themself? No reason to continue.
		return;

	//Check to see if we're at the limit on the amount of times a person will get extra credits from dying to someone else.
	if (iDeathCount >= iDeathMaxStreak)
		iDeathCount = iDeathMaxStreak; //If we are we set iDeathCount to the limit defined in escalation_gameinfo.
	//Same thing as above only for the attacker.
	if (iKillCount >= iKillMaxStreak)
		iKillCount = iKillMaxStreak;

	//Grab the name of the client that died.		
	decl String:clientName[MAX_NAME_LENGTH];
	GetClientName(iClient, clientName, sizeof(clientName));		
	//Same for the attacker.
	decl String:attackerName[MAX_NAME_LENGTH];
	GetClientName(attacker, attackerName, sizeof(attackerName));
	
	
	//Store the old credit count of both players. 
	new iOldCreditsClient = PlayerData_GetCredits(g_PlayerData[iClient][0]);
	new iOldCreditsAttacker = PlayerData_GetCredits(g_PlayerData[attacker][0]);
	
	//Determine how much to scale the amount of credits being given to the client.
	new Float:fScaleClient = 1.0 / iDeathMaxStreak * iDeathCount;
	new Float:fScaleAttacker = (iKillMaxStreak - (iKillCount - 1.0)) / iKillMaxStreak;
	
	//Finally we figure out how many credits to give each iClient.
	new iCreditsForClient = RoundFloat(float(iCreditsOnDeath) * fScaleClient);
	new iCreditsForAttacker = RoundFloat(float(iCreditsOnKill) * fScaleAttacker);
	
	//Increase the credits of the player.
	new iNewCreditsClient = Set_iClientCredits(iCreditsForClient, SET_ADD, iClient, ESC_CREDITS_KILLED);
	new iNewCreditsAttacker = Set_iClientCredits(iCreditsForAttacker, SET_ADD, attacker, ESC_CREDITS_KILL);
	
	//If the players earned some credits we inform them of it.
	
	//Was this a domination kill?
	if (iFlags & TF_DEATHFLAG_KILLERDOMINATION != 0)
	{
		Set_iClientCredits(iDominatedCredits, SET_ADD, iClient, ESC_CREDITS_DOMINATED);
		Set_iClientCredits(iDominationCredits, SET_ADD, attacker, ESC_CREDITS_DOMINATION);
	
		CPrintToChatEx(iClient, attacker, "%t %t", "Escalation_Tag", "Credits_From_Dominated", iDominatedCredits, attackerName);
		CPrintToChatEx(attacker, iClient, "%t %t", "Escalation_Tag", "Credits_From_Domination", iDominationCredits, clientName);
	}
	
	if (iOldCreditsClient != iNewCreditsClient)
	{
		CPrintToChatEx(iClient, attacker, "%t %t", "Escalation_Tag", "Credits_From_Death", (iNewCreditsClient-iOldCreditsClient), attackerName, iNewCreditsClient);
		
	}
	
	if (iOldCreditsAttacker != iNewCreditsAttacker)
	{
		CPrintToChatEx(attacker, iClient, "%t %t", "Escalation_Tag", "Credits_From_Kill", (iNewCreditsAttacker-iOldCreditsAttacker), clientName, iNewCreditsAttacker);

	}
	
	//Handle the assistor now.
	
	new iAssister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	//Check to see if someone assisted in this kill, if not return from this function.
	if (iAssister == 0)
	{
		return; 
	}

	//Get the name of the assister.
	decl String:assisterName[MAX_NAME_LENGTH];
	GetClientName(iAssister, assisterName, sizeof(assisterName));
	
	if (iFlags & TF_DEATHFLAG_ASSISTERDOMINATION != 0)
	{
		Set_iClientCredits(iDominatedCredits, SET_ADD, iClient, ESC_CREDITS_DOMINATED);
		Set_iClientCredits(iDominationCredits, SET_ADD, iAssister, ESC_CREDITS_DOMINATION);
	
		CPrintToChatEx(iClient, iAssister, "%t %t", "Escalation_Tag", "Credits_From_Dominated", iDominatedCredits, assisterName);
		CPrintToChatEx(iAssister, iClient, "%t %t", "Escalation_Tag", "Credits_From_Domination", iDominationCredits, clientName);
	}
	
	new iOldAssisterCredits = PlayerData_GetCredits(g_PlayerData[iAssister][0]);
	
	if (iOldAssisterCredits != Set_iClientCredits(iAssistCredits, SET_ADD, iAssister, ESC_CREDITS_ASSIST))
	{
		CPrintToChatEx(iAssister, attacker, "%t %t", "Escalation_Tag", "Credits_From_Assist", iAssistCredits, attackerName);
	}
}

/**
 * Gives credits to a medic when they die for the healing they did in that life.
 * Also gives bonus credits to the player that killed them.
 *
 * @noreturn
 */
public Event_MedicDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}
	
	new iBonusCredits;
	new iUberDroppedCredits;
	new iAmountHealedPacketSize;
	new iCreditsPerAmountHealed;
	
	KVMap_IndexGetCell(g_GameInfo[0], "OnMedicKilled.BonusCredits", iBonusCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "OnMedicKilled.UberDroppedCredits", iUberDroppedCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "OnMedicDeath.AmountHealed", iAmountHealedPacketSize);
	KVMap_IndexGetCell(g_GameInfo[0], "OnMedicDeath.CreditsPerAmountHealed", iCreditsPerAmountHealed);
	
	
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new iAmountHealed = GetEventInt(event, "healing");
	new bool:bHadCharge = GetEventBool(event, "charged");
	
	//Make sure the person will be gaining credits and that the client is valid.
	if (iBonusCredits > 0 && attacker != 0 && attacker != iClient)
	{
		Set_iClientCredits(iBonusCredits, SET_ADD, attacker, ESC_CREDITS_KILL | ESC_CREDITS_TEAMPLAY);
		
		CPrintToChat(attacker, "%t %t", "Escalation_Tag", "Credits_From_MedicKilled", iBonusCredits);
	}
	
	//Same as above.
	if (bHadCharge && iUberDroppedCredits > 0 && attacker != 0 && attacker != iClient)
	{
		Set_iClientCredits(iUberDroppedCredits, SET_ADD, attacker, ESC_CREDITS_KILL | ESC_CREDITS_TEAMPLAY);
		
		CPrintToChat(attacker, "%t %t", "Escalation_Tag", "Credits_From_UberDropped", iUberDroppedCredits);
	}
	
	if (iAmountHealed >= iAmountHealedPacketSize && iCreditsPerAmountHealed > 0 && iClient != 0)
	{
		new iCreditPackects = iAmountHealed / iAmountHealedPacketSize;
		new iCreditsGiven = iCreditPackects * iCreditsPerAmountHealed;
		
		Set_iClientCredits(iCreditsGiven, SET_ADD, iClient, ESC_CREDITS_HEALED);
		
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_AmountHealed", iCreditsGiven, iAmountHealed);
	}
	
	
}

/**
 * Gives credits to a player when they defend a medic.
 *
 * @noreturn
 */
public Event_MedicDefended(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}
	
	new iCredits;

	KVMap_IndexGetCell(g_GameInfo[0], "OnMedicDefended.Credits", iCredits);

	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));	
	
	if (iCredits > 0 && iClient != 0)
	{
		Set_iClientCredits(iCredits, SET_ADD, iClient, ESC_CREDITS_TEAMPLAY);
		
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_MedicDefended", iCredits);		
	}
}

/**
 * Gives bonus credits to a player when they block a capture.
 *
 * @noreturn
 */
public Event_CaptureBlocked(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}

	new iCredits;

	KVMap_IndexGetCell(g_GameInfo[0], "OnDefendedPoint.Credits", iCredits);
	
	new iClient = GetEventInt(event, "blocker");
	
	if (iClient == 0)
	{
		return;
	}

	Set_iClientCredits(iCredits, SET_ADD, iClient, ESC_CREDITS_TEAMPLAY);
	CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_CaptureBlocked", iCredits);
}

/**
 * Gives bonus credits to a player when they teleport another player.
 *
 * @noreturn
 */
public Event_PlayerTeleported(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}

	new iCredits;

	KVMap_IndexGetCell(g_GameInfo[0], "PlayerTeleported.Credits", iCredits);

	new iClient = GetClientOfUserId(GetEventInt(event, "builderid"));
	
	if (iClient == 0)
	{
		return;
	}

	
	Set_iClientCredits(iCredits, SET_ADD, iClient, ESC_CREDITS_TEAMPLAY);
	CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_Teleport", iCredits);
}

/**
 * Gives credits to a player when they upgrade a building.
 *
 * @noreturn
 */
public Event_PlayerUpgradedBuilding(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}

	new iCredits;
	new iCreditsOther;

	KVMap_IndexGetCell(g_GameInfo[0], "UpgradedBuilding.Credits", iCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "UpgradedBuilding.OtherCredits", iCreditsOther);
	
	
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:bIsBuilder = GetEventBool(event, "isbuilder");
	
	if (iClient == 0)
	{
		return;
	}
	
	if (bIsBuilder)
	{
		Set_iClientCredits(iCredits, SET_ADD, iClient, ESC_CREDITS_TEAMPLAY);
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_BuildingUpgrade", iCredits);
	}
	else
	{
		Set_iClientCredits(iCreditsOther, SET_ADD, iClient, ESC_CREDITS_TEAMPLAY);
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_BuildingUpgradeOther", iCreditsOther);
	}
}

/**
 * Gives credits to a player when they deploy an ubercharge.
 *
 * @noreturn
 */
public Event_ChargeDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}

	if (! g_bGiveCredits)
	{
		return;
	}

	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (iClient == 0)
	{
		return;
	}

	new iCredits;
	new Float:fKritzScale;
	new Float:fQFScale;
	new Float:fVaccScale;

	KVMap_IndexGetCell(g_GameInfo[0], "ChargeDeployed.Credits", iCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "ChargeDeployed.KritzScale", fKritzScale);
	KVMap_IndexGetCell(g_GameInfo[0], "ChargeDeployed.QFScale", fQFScale);
	KVMap_IndexGetCell(g_GameInfo[0], "ChargeDeployed.VaccScale", fVaccScale);

	new Float:fCreditsToGive = float(iCredits);
	new iMediGunIndex = PlayerData_GetWeaponID(g_PlayerData[iClient][0], 1);
	
	switch (iMediGunIndex)
	{
		case KRITZKRIEG_INDEXES:
		{
			fCreditsToGive *= fKritzScale;
		}
		case QUICKFIX_INDEXES:
		{
			fCreditsToGive *= fQFScale;
		}
		case VACCINATOR_INDEXES:
		{
			fCreditsToGive *= fVaccScale;
		}
	}
	
	Set_iClientCredits(RoundFloat(fCreditsToGive), SET_ADD, iClient, ESC_CREDITS_TEAMPLAY);
	CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_UberPopped", RoundFloat(fCreditsToGive));
}

/**
 * Gives credits to a player when they extinguish.
 *
 * @noreturn
 */
public Event_PlayerExtinguished(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}

	if (! g_bGiveCredits)
	{
		return;
	}

	new iCredits;

	KVMap_IndexGetCell(g_GameInfo[0], "PlayerExtinguished.Credits", iCredits);

	new healer = GetEventInt(event, "healer");

	if (! IsClientValid(healer) || ! IsClientInGame(healer))
	{
		return;
	}

	Set_iClientCredits(iCredits, SET_ADD, healer, ESC_CREDITS_TEAMPLAY);
	CPrintToChat(healer, "%t %t", "Escalation_Tag", "Credits_From_Extinguished", iCredits);
}

/**
 * Gives credits to a player when they destroy a building.
 *
 * @noreturn
 */
public Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}

	new iSentryCredits;
	new Float:fMinScale;
	new Float:fWasBuildingScale;
	new iDispenserCredits;
	new iTeleporterCredits;
	new iSapperCredits;
	
	KVMap_IndexGetCell(g_GameInfo[0], "ObjectDestroyed.SentryCredits", iSentryCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "ObjectDestroyed.MiniScale", fMinScale);
	KVMap_IndexGetCell(g_GameInfo[0], "ObjectDestroyed.WasBuildingScale", fWasBuildingScale);
	KVMap_IndexGetCell(g_GameInfo[0], "ObjectDestroyed.DispenserCredits", iDispenserCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "ObjectDestroyed.TeleporterCredits", iTeleporterCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "ObjectDestroyed.SapperCredits", iSapperCredits);

	new iBuilder = GetClientOfUserId(GetEventInt(event, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new iAssister = GetClientOfUserId(GetEventInt(event, "assister"));

	new TFObjectType:iObjectType = TFObjectType:GetEventInt(event, "objecttype");
	new bool:bWasBuilding = GetEventBool(event, "was_building");

	if (iAttacker != 0)
	{
		if (iObjectType == TFObject_Sentry)
		{
			new Float:fCreditsToGive = float(iSentryCredits);
		
			if (PlayerData_GetWeaponID(g_PlayerData[iBuilder][0], 2) == GUNSLINGER_INDEXES)
			{
				fCreditsToGive *= fMinScale;
			}
		
			if (bWasBuilding)
			{
				fCreditsToGive *= fWasBuildingScale;
			}
		
			Set_iClientCredits(RoundFloat(fCreditsToGive), SET_ADD, iAttacker, ESC_CREDITS_TEAMPLAY);
			CPrintToChat(iAttacker, "%t %t", "Escalation_Tag", "Credits_From_SentryDestroyed", RoundFloat(fCreditsToGive));
		}
		else if (iObjectType == TFObject_Dispenser)
		{
			new Float:fCreditsToGive = float(iDispenserCredits);
		
			if (bWasBuilding)
			{
				fCreditsToGive *= fWasBuildingScale;
			}
		
			Set_iClientCredits(RoundFloat(fCreditsToGive), SET_ADD, iAttacker, ESC_CREDITS_TEAMPLAY);
			CPrintToChat(iAttacker, "%t %t", "Escalation_Tag", "Credits_From_DispenserDestroyed", RoundFloat(fCreditsToGive));
		}
		else if (iObjectType == TFObject_Teleporter)
		{
			new Float:fCreditsToGive = float(iTeleporterCredits);
		
			if (bWasBuilding)
			{
				fCreditsToGive *= fWasBuildingScale;
			}
		
			Set_iClientCredits(RoundFloat(fCreditsToGive), SET_ADD, iAttacker, ESC_CREDITS_TEAMPLAY);
			CPrintToChat(iAttacker, "%t %t", "Escalation_Tag", "Credits_From_TeleporterDestroyed", RoundFloat(fCreditsToGive));
		}
		else if (iObjectType == TFObject_Sapper)
		{
			Set_iClientCredits(iSapperCredits, SET_ADD, iAttacker, ESC_CREDITS_TEAMPLAY);
			CPrintToChat(iAttacker, "%t %t", "Escalation_Tag", "Credits_From_SapperDestroyed", iSapperCredits);
		}
	}

	if (iAssister != 0)
	{
		if (iObjectType == TFObject_Sentry)
		{
			new Float:fCreditsToGive = float(iSentryCredits);
		
			if (PlayerData_GetWeaponID(g_PlayerData[iBuilder][0], 2) == GUNSLINGER_INDEXES)
			{
				fCreditsToGive *= fMinScale;
			}
		
			if (bWasBuilding)
			{
				fCreditsToGive *= fWasBuildingScale;
			}
		
			Set_iClientCredits(RoundFloat(fCreditsToGive), SET_ADD, iAssister, ESC_CREDITS_TEAMPLAY);
			CPrintToChat(iAssister, "%t %t", "Escalation_Tag", "Credits_From_HelpedSentryDestroyed", RoundFloat(fCreditsToGive));
		}
		else if (iObjectType == TFObject_Dispenser)
		{
			new Float:fCreditsToGive = float(iDispenserCredits);
		
			if (bWasBuilding)
			{
				fCreditsToGive *= fWasBuildingScale;
			}
		
			Set_iClientCredits(RoundFloat(fCreditsToGive), SET_ADD, iAssister, ESC_CREDITS_TEAMPLAY);
			CPrintToChat(iAssister, "%t %t", "Escalation_Tag", "Credits_From_HelpedDispenserDestroyed", RoundFloat(fCreditsToGive));
		}
		else if (iObjectType == TFObject_Teleporter)
		{
			new Float:fCreditsToGive = float(iTeleporterCredits);
		
			if (bWasBuilding)
			{
				fCreditsToGive *= fWasBuildingScale;
			}
		
			Set_iClientCredits(RoundFloat(fCreditsToGive), SET_ADD, iAssister, ESC_CREDITS_TEAMPLAY);
			CPrintToChat(iAssister, "%t %t", "Escalation_Tag", "Credits_From_HelpedTeleporterDestroyed", RoundFloat(fCreditsToGive));
		}
		else if (iObjectType == TFObject_Sapper)
		{
			Set_iClientCredits(iSapperCredits, SET_ADD, iAssister, ESC_CREDITS_TEAMPLAY);
			CPrintToChat(iAssister, "%t %t", "Escalation_Tag", "Credits_From_HelpedSapperDestroyed", iSapperCredits);
		}
	}
}

/************************TEAM OBJECTIVE EVENTS************************/

/**
 * Handles giving credits to players when flag events occur.
 *
 * @noreturn
 */
public Event_FlagEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}

	new iPickupCredits;
	new iWasHomeBonus;
	new iPickupTimeout;
	new iDefendedCredits;
	new iCaptureCredits;
	new iCompensateCredits;
	
	KVMap_IndexGetCell(g_GameInfo[0], "FlagEvent.PickupCredits", iPickupCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "FlagEvent.WasHomeBonus", iWasHomeBonus);
	KVMap_IndexGetCell(g_GameInfo[0], "FlagEvent.PickupTimeout", iPickupTimeout);
	KVMap_IndexGetCell(g_GameInfo[0], "FlagEvent.DefendedCredits", iDefendedCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "FlagEvent.CaptureCredits", iCaptureCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "FlagEvent.CompensateCredits", iCompensateCredits);

	
	new iClient = GetEventInt(event, "player");
	new iEventType = GetEventInt(event, "eventtype");
	new bool:bWasHome = bool:GetEventInt(event, "home");
	new iFlagTeam = GetEventInt(event, "team");

	switch (iEventType)
	{
		case TF_FLAGEVENT_PICKEDUP:
		{
			if (! IsClientInGame(iClient))
			{
				return;
			}

			if (iPickupCredits <= 0)
			{
				return;
			}
		
			if (bWasHome)
			{
				iPickupCredits += iWasHomeBonus;
			}
			
			if (PlayerData_GetTimeStartedCapture(g_PlayerData[iClient][0]) >= iPickupTimeout)
			{
				Set_iClientCredits(iPickupCredits, SET_ADD, iClient, ESC_CREDITS_TEAMPLAY);
				CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_Intel_Pickup", iPickupCredits);
				PlayerData_SetTimeStartedCapture(g_PlayerData[iClient][0]);
			}
		}
		case TF_FLAGEVENT_CAPTURED:
		{
			if (iCaptureCredits > 0)
			{
				new iTeam = GetEnemyTeam(iFlagTeam);

				decl iClients[MaxClients + 1];
				new iNumClients = GetClientsOnTeam(iTeam, iClients, MaxClients + 1);

				for (new i = 0; i < iNumClients; i++)
				{
					Set_iClientCredits(iCaptureCredits, SET_ADD, iClients[i], ESC_CREDITS_OBJECTIVE);
					CPrintToChat(iClients[i], "%t %t", "Escalation_Tag", "Credits_From_Intel_Capture", iCaptureCredits);
				}
			
				Set_iObjectiveCredits(iCaptureCredits, SET_ADD, iTeam);
			}


			if (iCompensateCredits > 0)
			{
				decl iClients[MaxClients + 1];
				new iNumClients = GetClientsOnTeam(iFlagTeam, iClients, MaxClients + 1);

				for (new i = 0; i < iNumClients; i++)
				{
					Set_iClientCredits(iCompensateCredits, SET_ADD, iClients[i], ESC_CREDITS_OBJECTIVE);
					CPrintToChat(iClients[i], "%t %t", "Escalation_Tag", "Credits_From_Intel_Lost", iCompensateCredits);
				}
				
				Set_iObjectiveCredits(iCompensateCredits, SET_ADD, iFlagTeam);
			}

		}
		case TF_FLAGEVENT_DEFENDED:
		{
			if (! IsClientInGame(iClient))
			{
				return;
			}
			
			if (iDefendedCredits <= 0)
			{
				return;
			}
			
			Set_iClientCredits(iDefendedCredits, SET_ADD, iClient, ESC_CREDITS_TEAMPLAY);
			CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_Intel_Defended", iDefendedCredits);
		}
	}
}

/**
 * Gives credits to players that start capturing a control point.
 * Also helps keep track of who owned a control point before it was captured.
 *
 * @noreturn
 */
public Event_PointContested(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}

	new iTimeout;
	new iCredits;

	KVMap_IndexGetCell(g_GameInfo[0], "OnCaptureStarted.Timeout", iTimeout);
	KVMap_IndexGetCell(g_GameInfo[0], "OnCaptureStarted.Credits", iCredits);
	

	decl String:point_name[64];
	GetEventString(event, "cpname", point_name, sizeof(point_name));
	
	SetTrieValue(g_hPointOwner, point_name, GetEventInt(event, "team"));
	
	new String:Cappers[MaxClients + 1];
	
	GetEventString(event, "cappers", Cappers, MaxClients + 1);
	
	new i = 0;
	
	while (Cappers[i] != '\0')
	{
		new iClient = Cappers[i];
		
		if (IsClientInGame(iClient))
		{
			if (PlayerData_GetTimeStartedCapture(g_PlayerData[iClient][0]) >= iTimeout)
			{
				Set_iClientCredits(iCredits, SET_ADD, iClient, ESC_CREDITS_TEAMPLAY);
				CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Credits_From_CaptureStarted", iCredits);
				PlayerData_SetTimeStartedCapture(g_PlayerData[iClient][0]);
			}
		}
		
		i++;
	}
	
}

/**
 * Gives credits to the teams when a control point is captured.
 *
 * @noreturn
 */
public Event_CapturedPoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDisabled())
	{
		return;
	}
	
	if (! g_bGiveCredits)
	{
		return;
	}
	
	new iCredits;
	new iCreditsOther;

	KVMap_IndexGetCell(g_GameInfo[0], "OnCapturePoint.Credits", iCredits);
	KVMap_IndexGetCell(g_GameInfo[0], "OnLosePoint.Credits", iCreditsOther);

	new iTeam = GetEventInt(event, "team");
	
	decl String:point_name[64];
	GetEventString(event, "cpname", point_name, sizeof(point_name));
	
	decl iClients[MaxClients + 1];
	new iNumClients = GetClientsOnTeam(iTeam, iClients, MaxClients + 1);
	
	for (new i = 0; i < iNumClients; i++)
	{
		Set_iClientCredits(iCredits, SET_ADD, iClients[i], ESC_CREDITS_OBJECTIVE);
		CPrintToChat(iClients[i], "%t %t", "Escalation_Tag", "Credits_From_PointCapture", iCredits);
	}
	
	//Increase the objective credits of this team.	
	Set_iObjectiveCredits(iCredits, SET_ADD, iTeam);
	
	//Now we need to give credits to the team that lost the point.
	GetTrieValue(g_hPointOwner, point_name, iTeam);
	
	//Check to see that this is one of the playable teams.
	if (iTeam <= 1)
		return;
	
	//Since we don't need it anymore we can just reuse our old array.
	iNumClients = GetClientsOnTeam(iTeam, iClients, MaxClients + 1);
	
	for (new i = 0; i < iNumClients; i++)
	{
		Set_iClientCredits(iCreditsOther, SET_ADD, iClients[i], ESC_CREDITS_OBJECTIVE);
		CPrintToChat(iClients[i], "%t %t", "Escalation_Tag", "Credits_From_PointLost", iCreditsOther);
	}
	
	Set_iObjectiveCredits(iCreditsOther, SET_ADD, iTeam);
}

/************************USER COMMANDS************************/

/**
 * Prints out the client's credit count to chat. (Just a normal ConCmd, see console.inc for argument information.)
 *
 * @return An Action value.
 */
public Action:Command_MyCredits(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		return Plugin_Handled;
	}
	
	CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Credits_Message", PlayerData_GetCredits(g_PlayerData[iClient][0]));
	
	return Plugin_Handled;
}

/**
 * Clears a client's upgrade queue for one or all classes.
 *
 * @return An Action value.
 */
public Action:Command_ClearUpgrades(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		return Plugin_Handled;
	}
 	
	decl String:Arg1[16];	
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	if (StrEqual("list", Arg1, false))
	{
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Refund_Valid_Classnames");
		CPrintToChat(iClient, "{silver}scout");
		CPrintToChat(iClient, "{silver}sniper");		
		CPrintToChat(iClient, "{silver}soldier");		
		CPrintToChat(iClient, "{silver}demoman");
		CPrintToChat(iClient, "{silver}medic");		
		CPrintToChat(iClient, "{silver}heavy");	
		CPrintToChat(iClient, "{silver}pyro");
		CPrintToChat(iClient, "{silver}spy");		
		CPrintToChat(iClient, "{silver}engineer");		
		
		return Plugin_Handled;
	}
	
	ClearUpgrades(iClient, true, Arg1);
	
	return Plugin_Handled;
}

/**
 * Adds an upgrade to a client's upgrade queue.
 *
 * @return An Action value.
 */
public Action:Command_Upgrade(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		return Plugin_Handled;
	}
	
	if (! IsClientInGame(iClient))
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Command_Ingame_Only");
		return Plugin_Handled;
	}
	
	if (IsClientSpectator(iClient))
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Command_Onteam_Only");
		return Plugin_Handled;
	}
 
	//Check for errors first.
	if (iArgs < 1)
	{
		ReplyToCommand(iClient,"Usage: sm_buyupgrade <upgrade name>");
		return Plugin_Handled;
	}

	//Grab the upgrade.
	new String:Upgrade[UPGRADE_NAME_MAXLENGTH];	
	GetCmdArg(1 ,Upgrade, sizeof(Upgrade));

	PushUpgrade(iClient, Upgrade, TF2_GetPlayerClass(iClient), true);
	
	return Plugin_Handled;
}

/**
 * Displays the "upgrade" menu to the client calling the command.
 *
 * @return An Action value.
 */
public Action:Command_UpgradeMenu(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		return Plugin_Handled;
	}
	
	if (! IsClientInGame(iClient))
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Command_Ingame_Only");
		return Plugin_Handled;
	}
	
	if (IsClientSpectator(iClient))
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Command_Onteam_Only");
		return Plugin_Handled;
	}
 
	PlayerData_SetHasOpenedMenu(g_PlayerData[iClient][0]);

	DisplayMenu(g_hUpgradeMenuBase, iClient, MENU_DISPLAY_DURATION);

	return Plugin_Handled;
}

/************************ADMIN COMMANDS************************/

/**
 * Reloads all of Escalation's config files, except for translations which are beyond the plugin's control.
 *
 * @return An Action value.
 */
public Action:Command_ReloadConfigs(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		
		return Plugin_Handled;
	}

	ExecuteConfigs();
	
	//Reload The Gameinfo
	new Handle:hGameInfo = CreateKeyValues("escalation_gameinfo");
	
	decl String:GameInfoPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, GameInfoPath, sizeof(GameInfoPath), "configs/escalation/escalation_gameinfo.cfg");

	if (! FileToKeyValues(hGameInfo, GameInfoPath))
	{
		SetFailState("Unable to open config file for escalation_gameinfo: escalation_gameinfo.cfg");
	}

	ExecuteGameInfoConfig(hGameInfo);

	CloseHandle(hGameInfo);
	
	decl String:Tag[64];
	Format(Tag, sizeof(Tag), "%T ", "Escalation_Tag", LANG_SERVER);
	
	CShowActivity2(iClient, Tag, "{silver}%t", "Configs_Reloaded_Admin");
	LogAction(iClient, -1, "%t", "Configs_Reloaded_Admin_Log", iClient);
	
	return Plugin_Handled;
}

/**
 * Bans an upgrade, preventing it from being brought.
 *
 * @return An Action value.
 */
public Action:Command_BanUpgrade(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		
		return Plugin_Handled;
	}

	if (iArgs < 1)
	{
		if (iClient == 0)
		{
			PrintToServer("%t", "BanUpgrade_Usage");
		}
		else
		{
			CReplyToCommand(iClient, "{silver}%t", "BanUpgrade_Usage");
		}

		return Plugin_Handled;
	}
	

	decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];

	GetCmdArg(1, Upgrade, sizeof(Upgrade));
	
	if (! UpgradeDataStore_UpgradeExists(g_UpgradeDataStore[0], Upgrade))
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Upgrade_Does_Not_Exist", Upgrade);
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Upgrade_Does_Not_Exist", Upgrade);
		}
		
		return Plugin_Handled;
	}
	
	BannedUpgrades_BanUpgrade(g_BannedUpgrades[0], Upgrade);

	decl String:Tag[64];
	Format(Tag, sizeof(Tag), "%T ", "Escalation_Tag", LANG_SERVER);
	
	CShowActivity2(iClient, Tag, "{silver}%t", "Upgrade_Banned_Admin", Upgrade);
	LogAction(iClient, -1, "%t", "Upgrade_Banned_Admin_Log", iClient, Upgrade);
	
	//Force the player's upgrade queues to be reprocessed so the upgrade can't be owned by anyone.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PlayerData_SetForceQueueReprocess(g_PlayerData[i][0], true);
		}
	}
	
	return Plugin_Handled;
}

/**
 * Bans an upgrade/weapon combination, preventing them from being used together.
 *
 * @return An Action value.
 */
public Action:Command_BanCombo(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		
		return Plugin_Handled;
	}

	if (iArgs < 2)
	{
		if (iClient == 0)
		{
			PrintToServer("%t", "BanUpgradeCombo_Usage");
		}
		else
		{
			CReplyToCommand(iClient, "{silver}%t", "BanUpgradeCombo_Usage");
		}

		return Plugin_Handled;
	}

	decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];

	GetCmdArg(1, Upgrade, sizeof(Upgrade));

	if (! UpgradeDataStore_UpgradeExists(g_UpgradeDataStore[0], Upgrade))
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Upgrade_Does_Not_Exist", Upgrade);
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Upgrade_Does_Not_Exist", Upgrade);
		}
		
		return Plugin_Handled;
	}

	decl String:Weapon[8];

	GetCmdArg(2, Weapon, sizeof(Weapon));

	if (! WeaponInfoManager_DoesWeaponExist(g_WeaponInfoManager[0], StringToInt(Weapon)))
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Weapon_Does_Not_Exist", Weapon);
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Weapon_Does_Not_Exist", Weapon);
		}

		return Plugin_Handled;
	}

	BannedUpgrades_BanCombo(g_BannedUpgrades[0], StringToInt(Weapon), Upgrade, true);

	decl String:Tag[64];
	Format(Tag, sizeof(Tag), "%T ", "Escalation_Tag", LANG_SERVER);
	
	CShowActivity2(iClient, Tag, "{silver}%t", "UpgradeCombo_Banned_Admin", Upgrade, Weapon);
	LogAction(iClient, -1, "%t", "UpgradeCombo_Banned_Admin_Log", iClient, Upgrade, Weapon);
	
	//Force the player's upgrade queues to be reprocessed so the upgrade can't be owned by anyone.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PlayerData_SetForceQueueReprocess(g_PlayerData[i][0], true);
		}
	}
	
	return Plugin_Handled;
}

/**
 * Unbans an upgrade, allowing it to be brought again.
 *
 * @return An Action value.
 */
public Action:Command_UnbanUpgrade(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		
		return Plugin_Handled;
	}

	if (iArgs < 1)
	{
		if (iClient == 0)
		{
			PrintToServer("%t", "UnbanUpgrade_Usage");
		}
		else
		{
			CReplyToCommand(iClient, "{silver}%t", "UnbanUpgrade_Usage");
		}

		return Plugin_Handled;
	}


	decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];

	GetCmdArg(1, Upgrade, sizeof(Upgrade));

	if (! UpgradeDataStore_UpgradeExists(g_UpgradeDataStore[0], Upgrade))
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Upgrade_Does_Not_Exist", Upgrade);
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Upgrade_Does_Not_Exist", Upgrade);
		}

		return Plugin_Handled;
	}

	if (! BannedUpgrades_IsUpgradeBanned(g_BannedUpgrades[0], Upgrade))
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Upgrade_Not_Banned", Upgrade);
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Upgrade_Not_Banned", Upgrade);
		}

		return Plugin_Handled;
	}

	BannedUpgrades_UnbanUpgrade(g_BannedUpgrades[0], Upgrade);
	
	decl String:Tag[64];
	Format(Tag, sizeof(Tag), "%T ", "Escalation_Tag", LANG_SERVER);

	CShowActivity2(iClient, Tag, "{silver}%t", "Upgrade_Unbanned_Admin", Upgrade);
	LogAction(iClient, -1, "%t", "Upgrade_Unbanned_Admin_Log", iClient, Upgrade);
	
	return Plugin_Handled;
}

/**
 * Unbans an upgrade/weapon combination, allowing them to be used together again.
 *
 * @return An Action value.
 */
public Action:Command_UnbanCombo(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		
		return Plugin_Handled;
	}

	if (iArgs < 2)
	{
		if (iClient == 0)
		{
			PrintToServer("%t", "UnbanUpgradeCombo_Usage");
		}
		else
		{
			CReplyToCommand(iClient, "{silver}%t", "BanUpgradeCombo_Usage");
		}

		return Plugin_Handled;
	}

	decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];

	GetCmdArg(1, Upgrade, sizeof(Upgrade));

	if (! UpgradeDataStore_UpgradeExists(g_UpgradeDataStore[0], Upgrade))
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Upgrade_Does_Not_Exist", Upgrade);
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Upgrade_Does_Not_Exist", Upgrade);
		}
		
		return Plugin_Handled;
	}

	decl String:Weapon[8];

	GetCmdArg(2, Weapon, sizeof(Weapon));

	if (! WeaponInfoManager_DoesWeaponExist(g_WeaponInfoManager[0], StringToInt(Weapon)))
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Weapon_Does_Not_Exist", Weapon);
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Weapon_Does_Not_Exist", Weapon);
		}

		return Plugin_Handled;
	}

	if (! BannedUpgrades_IsComboBanned(g_BannedUpgrades[0], StringToInt(Weapon), Upgrade))
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Combo_Not_Banned", Upgrade, Weapon);
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Combo_Not_Banned", Upgrade, Weapon);
		}

		return Plugin_Handled;
	}

	BannedUpgrades_UnbanCombo(g_BannedUpgrades[0], StringToInt(Weapon), Upgrade);
	
	decl String:Tag[64];
	Format(Tag, sizeof(Tag), "%T ", "Escalation_Tag", LANG_SERVER);
	
	CShowActivity2(iClient, Tag, "{silver}%t", "UpgradeCombo_Unbanned_Admin", Upgrade, Weapon);
	LogAction(iClient, -1, "%t", "UpgradeCombo_Unbanned_Admin_Log", iClient, Upgrade, Weapon);
	
	
	return Plugin_Handled;
}

/**
 * Resets all banned upgrades.
 *
 * @return An Action value.
 */
public Action:Command_ResetBannedUpgrades(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		
		return Plugin_Handled;
	}

	BannedUpgrades_ResetBanned(g_BannedUpgrades[0]);

	decl String:Tag[64];
	Format(Tag, sizeof(Tag), "%T ", "Escalation_Tag", LANG_SERVER);

	CShowActivity2(iClient, Tag, "{silver}%t", "Upgrade_BannedReset_Admin");
	LogAction(iClient, -1, "%t", "Upgrade_BannedReset_Admin_Log", iClient);

	return Plugin_Handled;
}

/**
 * Resets all banned upgrade/weapon combinations.
 *
 * @return An Action value.
 */
public Action:Command_ResetBannedCombos(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		
		return Plugin_Handled;
	}

	BannedUpgrades_ResetBannedCombos(g_BannedUpgrades[0], true);

	decl String:Tag[64];
	Format(Tag, sizeof(Tag), "%T ", "Escalation_Tag", LANG_SERVER);

	CShowActivity2(iClient, Tag, "{silver}%t", "UpgradeCombo_BannedReset_Admin");
	LogAction(iClient, -1, "%t", "UpgradeCombo_BannedReset_Admin_Log", iClient);

	return Plugin_Handled;
}

/**
 * Displays a menu to the client, that they can use to ban upgrades.
 *
 * @return An Action value.
 */
public Action:Command_BanUpgradeMenu(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}

		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}

		return Plugin_Handled;
	}

	new Handle:hMenu = UpgradeDataStore_GetMenuOfUpgrades(g_UpgradeDataStore[0], Menu_BanUpgrade, 
	MenuAction_Select | MenuAction_DrawItem | MenuAction_DisplayItem | MenuAction_Cancel | MenuAction_End, ITEMDRAW_DEFAULT);

	SetMenuTitle(hMenu, "%T", "Menu_Select_Upgrade_Ban", iClient);
	
	DisplayMenu(hMenu, iClient, MENU_DISPLAY_DURATION * 12);

	return Plugin_Handled;
}

/**
 * Displays a menu to the client, that they can use to unban upgrades.
 *
 * @return An Action value.
 */
public Action:Command_UnbanUpgradeMenu(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}

		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}

		return Plugin_Handled;
	}

	new Handle:hMenu = UpgradeDataStore_GetMenuOfUpgrades(g_UpgradeDataStore[0], Menu_UnbanUpgrade, 
	MenuAction_Select | MenuAction_DrawItem | MenuAction_DisplayItem | MenuAction_Cancel | MenuAction_End, ITEMDRAW_DEFAULT);

	SetMenuTitle(hMenu, "%T", "Menu_Select_Upgrade_Unban", iClient);
	
	DisplayMenu(hMenu, iClient, MENU_DISPLAY_DURATION);

	return Plugin_Handled;
}

/**
 * Displays a menu to the client, that they can use to unban upgrades.
 *
 * @return An Action value.
 */
public Action:Command_SetGameInfo(iClient, iArgs)
{
	if (g_bPluginDisabledAdmin)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Admin");
		}

		return Plugin_Handled;
	}
	else if (g_bPluginDisabledForMap)
	{
		if (iClient == 0)
		{
			PrintToServer("%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}
		else
		{
			CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "Plugin_Disabled_Nosupport");
		}

		return Plugin_Handled;
	}

	if (iArgs == 0 || iArgs > 3)
	{
		CReplyToCommand(iClient, "%t", "SetGameInfo_Usage");

		return Plugin_Handled;
	}

	new iTestValue;
	new bool:bIsFloat;
	
	decl String:IndexKey[KEYVALUE_NAME_MAX_LENGTH];
	decl String:Value[16];
	decl String:IsFloat[4];

	GetCmdArg(1, IndexKey, sizeof(IndexKey));
	GetCmdArg(2, Value, sizeof(Value));
	GetCmdArg(3, IsFloat, sizeof(IsFloat));
	
	bIsFloat = bool:StringToInt(IsFloat);
	
	if (! KVMap_IndexGetCell(g_GameInfo[0], IndexKey, iTestValue))
	{
		CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "GameInfo_UnknownVar");

		return Plugin_Handled;
	}
	
	if (bIsFloat)
	{
		KVMap_IndexSetCell(g_GameInfo[0], IndexKey, StringToFloat(Value));
	}
	else
	{
		KVMap_IndexSetCell(g_GameInfo[0], IndexKey, StringToInt(Value));
	}
	
	CReplyToCommand(iClient, "%t %t", "Escalation_Tag", "GameInfo_VarSet");

	return Plugin_Handled;
}

/************************ADMIN MENU STUFF************************/

//These are basically all exactly what is taught here https://wiki.alliedmods.net/Admin_Menu_(SourceMod_Scripting)
//Go there to learn how it all works.

public OnAdminMenuCreated(Handle:topmenu)
{
	if (topmenu == g_hAdminMenu && g_AdminMenuCommands != INVALID_TOPMENUOBJECT)
	{
		return;
	}

	g_AdminMenuCommands = AddToTopMenu(topmenu, "Escalation_Commands", TopMenuObject_Category, AdminMenu_Handler, INVALID_TOPMENUOBJECT);
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (g_AdminMenuCommands == INVALID_TOPMENUOBJECT)
	{
		OnAdminMenuCreated(topmenu);
	}

	if (topmenu == g_hAdminMenu)
	{
		return;
	}
	
	g_hAdminMenu  = topmenu;
	
	if (g_AdminMenuBanUpgrades == INVALID_TOPMENUOBJECT)
	{
		g_AdminMenuBanUpgrades = AddToTopMenu(topmenu, "sm_banupgrade", TopMenuObject_Item, AdminMenu_Handler, g_AdminMenuCommands, "sm_banupgrade", ADMFLAG_BAN);
	}
	if (g_AdminMenuUnbanUpgrades == INVALID_TOPMENUOBJECT)
	{
		g_AdminMenuUnbanUpgrades = AddToTopMenu(topmenu, "sm_unbanupgrade", TopMenuObject_Item, AdminMenu_Handler, g_AdminMenuCommands, "sm_unbanupgrade", ADMFLAG_BAN);
	}
	if (g_AdminMenuResetBannedUpgrades == INVALID_TOPMENUOBJECT)
	{
		g_AdminMenuResetBannedUpgrades = AddToTopMenu(topmenu, "sm_resetbannedupgrades", TopMenuObject_Item, AdminMenu_Handler, g_AdminMenuCommands, "sm_resetbannedupgrades", ADMFLAG_BAN);
	}
	
}

public AdminMenu_Handler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (object_id == g_AdminMenuCommands)
	{
		if (action == TopMenuAction_DisplayTitle)
		{
			Format(buffer, maxlength, "%T", "Escalation_Commands", param)
		}
		else if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%T", "Escalation_Commands", param)
		}
	}
	else if (object_id == g_AdminMenuBanUpgrades)
	{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%T", "Menu_Action_BanUpgrade", param)
		}
		else if (action == TopMenuAction_SelectOption)
		{
			Command_BanUpgradeMenu(param, 0);
		}
	}
	else if (object_id == g_AdminMenuUnbanUpgrades)
	{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%T", "Menu_Action_UnbanUpgrade", param)
		}
		else if (action == TopMenuAction_SelectOption)
		{
			Command_UnbanUpgradeMenu(param, 0);
		}
	}
	else if (object_id == g_AdminMenuResetBannedUpgrades)
	{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%T", "Menu_Action_ResetBanned", param)
		}
		else if (action == TopMenuAction_SelectOption)
		{
			Command_ResetBannedUpgrades(param, 0);
		}
	}
}

/************************MENU HANDLERS************************/

/**
 * Menu handler for the base menu. See menus.inc for argument information.
 *
 * @return Callback dependent.
 */
public Menu_UpgradeMenuBase(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:buffer[32];
			
			GetMenuItem(menu, param2, buffer, sizeof(buffer));
			
			if (StrEqual("Upgrade_Class", buffer, true))
			{
				new Handle:hMenuToDisplay = MenuCache_GetMenu(g_UpgradeMenuCache[0], _:TF2_GetPlayerClass(param1) * CLASS_MENU_OFFSET);
				DisplayMenu(hMenuToDisplay, param1, MENU_DISPLAY_DURATION);				
			}
			else if (StrEqual("Upgrade_Slot_0", buffer, true))
			{
				new iClientWeaponIndex = PlayerData_GetWeaponID(g_PlayerData[param1][0], 0);

				if (IsAllClassWeapon(iClientWeaponIndex))
				{
					iClientWeaponIndex += (ALL_CLASS_WEAPON_OFFSET * _:TF2_GetPlayerClass(param1));
				}
				
				new Handle:hMenuToDisplay = MenuCache_GetMenu(g_UpgradeMenuCache[0], iClientWeaponIndex);
				
				if (hMenuToDisplay == INVALID_HANDLE)
				{
					CPrintToChat(param1, "%t %t", "Escalation_Tag", "Weapon_Not_Found");
					CPrintToChat(param1, "%t %t", "Escalation_Tag", "Weapon_Not_Found_Possible_Cause");
					
					DisplayMenu(menu, param1, MENU_DISPLAY_DURATION);
				}
				else
				{
					DisplayMenu(hMenuToDisplay, param1, MENU_DISPLAY_DURATION);
				}
			}
			else if (StrEqual("Upgrade_Slot_1", buffer, true))
			{
				new iClientWeaponIndex = PlayerData_GetWeaponID(g_PlayerData[param1][0], 1);

				if (IsAllClassWeapon(iClientWeaponIndex))
				{
					iClientWeaponIndex += (ALL_CLASS_WEAPON_OFFSET * _:TF2_GetPlayerClass(param1));
				}

				new Handle:hMenuToDisplay = MenuCache_GetMenu(g_UpgradeMenuCache[0], iClientWeaponIndex);
				
				if (hMenuToDisplay == INVALID_HANDLE)
				{
					CPrintToChat(param1, "%t %t", "Escalation_Tag", "Weapon_Not_Found");
					CPrintToChat(param1, "%t %t", "Escalation_Tag", "Weapon_Not_Found_Possible_Cause");
					
					DisplayMenu(menu, param1, MENU_DISPLAY_DURATION);
				}
				else
				{
					DisplayMenu(hMenuToDisplay, param1, MENU_DISPLAY_DURATION);
				}
			}
			else if (StrEqual("Upgrade_Slot_2", buffer, true))
			{
				new iClientWeaponIndex = PlayerData_GetWeaponID(g_PlayerData[param1][0], 2);

				if (IsAllClassWeapon(iClientWeaponIndex))
				{
					iClientWeaponIndex += (ALL_CLASS_WEAPON_OFFSET * _:TF2_GetPlayerClass(param1));
				}

				new Handle:hMenuToDisplay = MenuCache_GetMenu(g_UpgradeMenuCache[0], iClientWeaponIndex);
				
				if (hMenuToDisplay == INVALID_HANDLE)
				{
					CPrintToChat(param1, "%t %t", "Escalation_Tag", "Weapon_Not_Found");
					CPrintToChat(param1, "%t %t", "Escalation_Tag", "Weapon_Not_Found_Possible_Cause");
					
					DisplayMenu(menu, param1, MENU_DISPLAY_DURATION);
				}
				else
				{
					DisplayMenu(hMenuToDisplay, param1, MENU_DISPLAY_DURATION);
				}
			}
			else if (StrEqual("Menu_Action_EditQueue", buffer, true))
			{
				if (PlayerData_GetUpgradeQueueSize(g_PlayerData[param1][0], TF2_GetPlayerClass(param1)) == 0)
				{
					CPrintToChat(param1, "%t %t", "Escalation_Tag", "Clear_Empty_Queue");
					
					DisplayMenu(menu, param1, MENU_DISPLAY_DURATION);
					
					return 0;
				}
			
				DisplayMenu(GetEditUpgradeQueueMenu(param1), param1, MENU_DISPLAY_DURATION);
			}
			else if (StrEqual("Menu_Action_RemoveQueue", buffer, true))
			{
				if (PlayerData_GetUpgradeQueueSize(g_PlayerData[param1][0], TF2_GetPlayerClass(param1)) == 0)
				{
					CPrintToChat(param1, "%t %t", "Escalation_Tag", "Clear_Empty_Queue");
					
					DisplayMenu(menu, param1, MENU_DISPLAY_DURATION);
					
					return 0;
				}

				DisplayMenu(GetRemoveUpgradeQueueMenu(param1), param1, MENU_DISPLAY_DURATION);
			}
			else if (StrEqual("Menu_Action_Clear",buffer, true))
			{
				DisplayMenu(g_hClearMenu, param1, MENU_DISPLAY_DURATION);
			}			
		}
		case MenuAction_DisplayItem:
		{
			//Handle the translations.
			decl String:buffer[32];
			decl String:display[64];
			
			if (GetMenuItem(menu, param2, buffer, sizeof(buffer)))
			{
				Format(display, sizeof(display), "%T", buffer, param1);
			}
			
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

/**
 * Menu handler for the clear upgrade queue menu.
 *
 * @return Callback dependent.
 */
public Menu_ClearUpgrades(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:buffer[32];
			
			GetMenuItem(menu, param2, buffer, sizeof(buffer));
			
			if (StrEqual("Select_Class_All", buffer, true))
			{
				ClearUpgrades(param1, true);
			}
			else if (StrEqual("Select_Class_Scout", buffer, true))
			{
				ClearUpgrades(param1, true, "scout");
			}
			else if (StrEqual("Select_Class_Soldier", buffer, true))
			{
				ClearUpgrades(param1, true, "soldier");
			}
			else if (StrEqual("Select_Class_Pyro",buffer, true))
			{
				ClearUpgrades(param1, true, "pyro");
			}
			else if (StrEqual("Select_Class_Demoman",buffer, true))
			{
				ClearUpgrades(param1, true, "demoman");
			}
			else if (StrEqual("Select_Class_Heavy",buffer, true))
			{
				ClearUpgrades(param1, true, "heavy");
			}			
			else if (StrEqual("Select_Class_Engineer",buffer, true))
			{
				ClearUpgrades(param1, true, "engineer");
			}			
			else if (StrEqual("Select_Class_Medic",buffer, true))
			{
				ClearUpgrades(param1, true, "medic");
			}			
			else if (StrEqual("Select_Class_Spy",buffer, true))
			{
				ClearUpgrades(param1, true, "spy");
			}					
			else if (StrEqual("Select_Class_Sniper",buffer, true))
			{
				ClearUpgrades(param1, true, "sniper");
			}
			
			DisplayMenu(g_hUpgradeMenuBase, param1, MENU_DISPLAY_DURATION);
			
		}
		case MenuAction_DisplayItem:
		{
			//Handle the translations.
			decl String:buffer[32];
			decl String:display[64];
			
			GetMenuItem(menu, param2, buffer, sizeof(buffer));
			
			Format(display, sizeof(display), "%T", buffer, param1);
			return RedrawMenuItem(display);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) //Check to see if we should go back to the top menu.
			{
				DisplayMenu(g_hUpgradeMenuBase, param1, MENU_DISPLAY_DURATION); //Go back to the base menu.
			}			
		}	
	}
	
	return 0;
}

/**
 * Menu handler for the upgrade menu.
 *
 * @return Callback dependent.
 */
public Menu_UpgradeHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:Upgrade[UPGRADE_NAME_MAXLENGTH]; //Stores the name of the upgrade passed to PushUpgrade.
			
			GetMenuItem(menu, param2, Upgrade, sizeof(Upgrade)); //Grab the upgrade the user wants.

			PushUpgrade(param1, Upgrade, TF2_GetPlayerClass(param1), true); //Put the upgrade on the queue.
			
			DisplayMenuAtItem(menu, param1, param2, MENU_DISPLAY_DURATION); //Re-display the menu.
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) //Check to see if we should go back to the top menu.
			{
				DisplayMenu(g_hUpgradeMenuBase, param1, MENU_DISPLAY_DURATION); //Go back to the base menu.
			}
			
		}
		case MenuAction_DrawItem:
		{
			new iStyle;
			decl String:buffer[UPGRADE_NAME_MAXLENGTH];
			
			GetMenuItem(menu, param2, buffer, sizeof(buffer), iStyle);
			
			if (StrEqual(buffer, "Menu_Level"))
			{
				return iStyle;
			}			
			else if (StrEqual(buffer, "Menu_Cost"))
			{
				return iStyle;
			}
			else if (StrEqual(buffer, "UPGRADE_DESC_1"))
			{
				return iStyle;
			}
			else if (StrEqual(buffer, "UPGRADE_DESC_2"))
			{
				return iStyle;
			}
			else if (StrEqual(buffer, "NODRAW"))
			{
				return iStyle;
			}
			else
			{
				if (PlayerData_GetUpgradeLevel(g_PlayerData[param1][0], buffer, TF2_GetPlayerClass(param1)) == UpgradeDataStore_GetUpgradeMaxLevel(g_UpgradeDataStore[0], buffer))
				{
					return ITEMDRAW_DISABLED;
				}
				else if (IsClientAllowedUpgrade(param1, buffer))
				{
					return iStyle;
				}
				else
				{
					return ITEMDRAW_DISABLED;
				}
			}
		}
		case MenuAction_DisplayItem:
		{
			static String:LastUpgrade[UPGRADE_NAME_MAXLENGTH]; //Oh no! A static variable! Quick someone do something about this programmer!

			//Handle the translations.
			decl String:buffer[UPGRADE_NAME_MAXLENGTH];
			decl String:display[256];

			GetMenuItem(menu, param2, buffer, sizeof(buffer));

			//LogMessage("%T", "Menu_Cost", LANG_SERVER, GetUpgradeCost(buffer));

			if (StrEqual(buffer, "Menu_Level"))
			{
				Format(display, sizeof(display), "   %T", "Menu_Level", param1, PlayerData_GetUpgradeLevel(g_PlayerData[param1][0], LastUpgrade, TF2_GetPlayerClass(param1)), UpgradeDataStore_GetUpgradeMaxLevel(g_UpgradeDataStore[0], LastUpgrade));
			}
			else if (StrEqual(buffer, "Menu_Cost"))
			{
				Format(display, sizeof(display), "   %T", "Menu_Cost", param1, UpgradeDataStore_GetUpgradeCost(g_UpgradeDataStore[0], LastUpgrade));
			}
			else if (StrEqual(buffer, "UPGRADE_DESC_1"))
			{
				decl String:Description[256];	

				new iLevel = PlayerData_GetUpgradeLevel(g_PlayerData[param1][0], LastUpgrade, TF2_GetPlayerClass(param1));
				iLevel += 1;

				new iMaxLevel = UpgradeDataStore_GetUpgradeMaxLevel(g_UpgradeDataStore[0], LastUpgrade);

				if (iLevel > iMaxLevel)
				{
					iLevel = iMaxLevel;
				}

				new iValue = UpgradeDescriptions_GetValue(g_UpgradeDescriptions[0], LastUpgrade, 1, iLevel);
				
				UpgradeDescriptions_GetDescription(g_UpgradeDescriptions[0], LastUpgrade, 1, Description, sizeof(Description));
				
				Format(display, sizeof(display), "   %T", Description, param1, iValue);
			}
			else if (StrEqual(buffer, "UPGRADE_DESC_2"))
			{
				decl String:Description[256];	

				new iLevel = PlayerData_GetUpgradeLevel(g_PlayerData[param1][0], LastUpgrade, TF2_GetPlayerClass(param1));
				iLevel += 1;

				new iMaxLevel = UpgradeDataStore_GetUpgradeMaxLevel(g_UpgradeDataStore[0], LastUpgrade);

				if (iLevel > iMaxLevel)
				{
					iLevel = iMaxLevel;
				}

				new iValue = UpgradeDescriptions_GetValue(g_UpgradeDescriptions[0], LastUpgrade, 2, iLevel);
				
				UpgradeDescriptions_GetDescription(g_UpgradeDescriptions[0], LastUpgrade, 2, Description, sizeof(Description));
				
				Format(display, sizeof(display), "   %T", Description, param1, iValue);
			}
			else if (StrEqual(buffer, "NODRAW"))
			{
				return 0;
			}
			else
			{
				strcopy(LastUpgrade, sizeof(LastUpgrade), buffer);

				Format(display, sizeof(display), "%T", buffer, param1);
			}

			return RedrawMenuItem(display);
		}
	}

	return 0;
}

/**
 * Menu handler for the remove an upgrade from the client's upgrade queue menu.
 *
 * @return Callback dependent.
 */
public Menu_RemoveUpgradeQueue(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl tmpUpgradeQueue[UpgradeQueue];
			PlayerData_GetUpgradeOnQueue(g_PlayerData[param1][0], TF2_GetPlayerClass(param1), param2, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));

			PlayerData_RemoveUpgradeFromQueue(g_PlayerData[param1][0], TF2_GetPlayerClass(param1), param2);
			RemoveMenuItem(menu, param2);
			
			if (tmpUpgradeQueue[_bOwned])
			{
				new iCost = UpgradeDataStore_GetUpgradeCost(g_UpgradeDataStore[0], tmpUpgradeQueue[_Upgrade]);

				Set_iClientCredits(iCost, SET_ADD, param1, ESC_CREDITS_REFUNDED);
				
				PlayerData_SetForceQueueReprocess(g_PlayerData[param1][0], true);

				CPrintToChat(param1, "%t %t", "Escalation_Tag", "Upgrade_Removed_Credits", tmpUpgradeQueue[_Upgrade], iCost);
			}
			else
			{
				CPrintToChat(param1, "%t %t", "Escalation_Tag", "Upgrade_Removed", tmpUpgradeQueue[_Upgrade]);
			}

			DisplayMenu(menu, param1, MENU_DISPLAY_DURATION);
		}
		case MenuAction_DisplayItem:
		{
			//Handle the translations.
			decl String:display[256];
			decl String:Slot[32];
			
			decl tmpUpgradeQueue[UpgradeQueue];
			PlayerData_GetUpgradeOnQueue(g_PlayerData[param1][0], TF2_GetPlayerClass(param1), param2, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
			
			decl tmpUpgradeData[UpgradeData];
			UpgradeDataStore_GetUpgrade(g_UpgradeDataStore[0], tmpUpgradeQueue[_Upgrade], tmpUpgradeData[0], sizeof(tmpUpgradeData));
			
			new iSlot = UpgradeData_GetSlot(tmpUpgradeData[0]);

			if (UpgradeData_IsPassive(tmpUpgradeData[0]))
			{
				strcopy(Slot, sizeof(Slot), "Class");
			}
			else
			{
				strcopy(Slot, sizeof(Slot), WeaponSlotKeys[iSlot]);
			}
			
			if (tmpUpgradeQueue[_bOwned])
			{
				Format(display, sizeof(display), "%T - %T %T %T", 
				tmpUpgradeQueue[_Upgrade], param1, 
				Slot, param1,
				"Menu_Queue_Level", param1, tmpUpgradeQueue[_iLevel], 
				"Menu_Queue_Credits", param1, UpgradeData_GetCost(tmpUpgradeData[0]));			
			}
			else
			{
				Format(display, sizeof(display), "%T - %T %T", 
				tmpUpgradeQueue[_Upgrade], param1, 
				Slot, param1,
				"Menu_Queue_Level", param1, tmpUpgradeQueue[_iLevel]);			
			}

			return RedrawMenuItem(display);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) //Check to see if we should go back to the top menu.
			{
				DisplayMenu(g_hUpgradeMenuBase, param1, 10); //Go back to the base menu.
			}
		}
		case MenuAction_End:
		{
			if (param1 != MenuEnd_Selected)
			{
				CloseHandle(menu);
			}
		}
	}

	return 0;
}

/**
 * Menu handler for the editing a client's upgrade queue.
 *
 * @return Callback dependent.
 */
public Menu_EditUpgradeQueue(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl tmpUpgradeQueue[UpgradeQueue];
			PlayerData_GetUpgradeOnQueue(g_PlayerData[param1][0], TF2_GetPlayerClass(param1), param2, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));

			if (PlayerData_ShiftUpgradeInQueue(g_PlayerData[param1][0], TF2_GetPlayerClass(param1), param2))
			{
				RemoveMenuItem(menu, param2);
				InsertMenuItem(menu, (param2 - 1), tmpUpgradeQueue[_Upgrade], "UNFORMATTED_UPGRADE_TEXT");
			}

			DisplayMenu(menu, param1, MENU_DISPLAY_DURATION);
		}
		case MenuAction_DisplayItem:
		{
			//Handle the translations.
			decl String:display[256];
			decl String:Slot[32];
			
			decl tmpUpgradeQueue[UpgradeQueue];
			PlayerData_GetUpgradeOnQueue(g_PlayerData[param1][0], TF2_GetPlayerClass(param1), param2, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
			
			decl tmpUpgradeData[UpgradeData];
			UpgradeDataStore_GetUpgrade(g_UpgradeDataStore[0], tmpUpgradeQueue[_Upgrade], tmpUpgradeData[0], sizeof(tmpUpgradeData));
			
			new iSlot = UpgradeData_GetSlot(tmpUpgradeData[0]);

			if (UpgradeData_IsPassive(tmpUpgradeData[0]))
			{
				strcopy(Slot, sizeof(Slot), "Class");
			}
			else
			{
				strcopy(Slot, sizeof(Slot), WeaponSlotKeys[iSlot]);
			}
			

			Format(display, sizeof(display), "%T - %T %T", 
			tmpUpgradeQueue[_Upgrade], param1, 
			Slot, param1,
			"Menu_Queue_Level", param1, tmpUpgradeQueue[_iLevel]);

			return RedrawMenuItem(display);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) //Check to see if we should go back to the top menu.
			{
				DisplayMenu(g_hUpgradeMenuBase, param1, MENU_DISPLAY_DURATION); //Go back to the base menu.
			}
		}
		case MenuAction_End:
		{
			if (param1 != MenuEnd_Selected)
			{
				CloseHandle(menu);
			}
		}
	}

	return 0;
}

/**
 * Menu handler for the banning an upgrade.
 *
 * @return Callback dependent.
 */
public Menu_BanUpgrade(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];		
			GetMenuItem(menu, param2, Upgrade, sizeof(Upgrade));

			BannedUpgrades_BanUpgrade(g_BannedUpgrades[0], Upgrade);

			decl String:Tag[64];
			Format(Tag, sizeof(Tag), "%T ", "Escalation_Tag", LANG_SERVER);
	
			CShowActivity2(param1, Tag, "{silver}%t", "Upgrade_Banned_Admin", Upgrade);
			LogAction(param1, -1, "%t", "Upgrade_Banned_Admin_Log", param1, Upgrade);
			
			DisplayMenu(menu, param1, MENU_DISPLAY_DURATION);
		}
		case MenuAction_DrawItem:
		{
			decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];
			
			GetMenuItem(menu, param2, Upgrade, sizeof(Upgrade));
			
			if (BannedUpgrades_IsUpgradeBanned(g_BannedUpgrades[0], Upgrade))
			{
				return ITEMDRAW_IGNORE;
			}
		}
		case MenuAction_DisplayItem:
		{
			decl String:display[256];
			decl String:Upgrade[32];		
			GetMenuItem(menu, param2, Upgrade, sizeof(Upgrade));

			Format(display, sizeof(display), "%s - %T", Upgrade, Upgrade, param1);

			return RedrawMenuItem(display);
		}
		case MenuAction_End:
		{
			if (param1 != MenuEnd_Selected)
			{
				CloseHandle(menu);
			}
		}
	}

	return 0;
}

/**
 * Menu handler for the unbanning an upgrade.
 *
 * @return Callback dependent.
 */
public Menu_UnbanUpgrade(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];		
			GetMenuItem(menu, param2, Upgrade, sizeof(Upgrade));

			BannedUpgrades_UnbanUpgrade(g_BannedUpgrades[0], Upgrade);

			decl String:Tag[64];
			Format(Tag, sizeof(Tag), "%T ", "Escalation_Tag", LANG_SERVER);
	
			CShowActivity2(param1, Tag, "{silver}%t", "Upgrade_Unbanned_Admin", Upgrade);
			LogAction(param1, -1, "%t", "Upgrade_Unbanned_Admin_Log", param1, Upgrade);
			
			DisplayMenu(menu, param1, MENU_DISPLAY_DURATION);
		}
		case MenuAction_DrawItem:
		{
			decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];
			
			GetMenuItem(menu, param2, Upgrade, sizeof(Upgrade));
			
			if (! BannedUpgrades_IsUpgradeBanned(g_BannedUpgrades[0], Upgrade))
			{
				return ITEMDRAW_IGNORE;
			}
		}
		case MenuAction_DisplayItem:
		{
			decl String:display[256];
			decl String:Upgrade[32];		
			GetMenuItem(menu, param2, Upgrade, sizeof(Upgrade));

			Format(display, sizeof(display), "%s - %T", Upgrade, Upgrade, param1);

			return RedrawMenuItem(display);
		}
		case MenuAction_End:
		{
			if (param1 != MenuEnd_Selected)
			{
				CloseHandle(menu);
			}
		}
	}

	return 0;
}

/************************UPGRADE COMMAND FUNCTIONS************************/


/**
 * Refunds a client's upgrades.
 *
 * @param iClient				The index of the client to refund.
 *
 * @noreturn
 */
RefundUpgrades(iClient)
{
	new iCreditsToRefund;

	for (new TFClassType:iClass = TFClassType:1; iClass <= TFClassType:9; iClass ++) //Iterate through the classes
	{			
		for (new iIndex; iIndex < PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], iClass); iIndex++) //Iterate through the upgrades themselves now. 
		{
			decl tmpUpgradeQueue[UpgradeQueue];
			PlayerData_GetUpgradeOnQueue(g_PlayerData[iClient][0], iClass, iIndex, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
			
			if (tmpUpgradeQueue[_bOwned] == true)
			{
				iCreditsToRefund += UpgradeDataStore_GetUpgradeCost(g_UpgradeDataStore[0], tmpUpgradeQueue[_Upgrade]);//Get the value of the upgrade we're refunding then add it to the amount of credits the client will gain.
				tmpUpgradeQueue[_bOwned] = false; //Set the upgrade we're refunding to not purchased.
			}
			
			PlayerData_SetUpgradeOnQueue(g_PlayerData[iClient][0], iClass, iIndex, tmpUpgradeQueue[0]);
		}
	}

	Set_iClientCredits(iCreditsToRefund, SET_ADD, iClient, ESC_CREDITS_REFUND_FULL);
}

/**
 * Clears a client's upgrade queue.
 *
 * @param iClient				The index of the client to clear the upgrade queue.
 * @param bInform				If true, inform the client of any action taken or error encountered.
 * @param Class					If not empty only the classname here will be cleared.
 *
 * @noreturn
 */
ClearUpgrades(iClient, bool:bInform, String:Class[] = "")
{	
	if (StrEqual("", Class, true)) 
	{
		new iCreditsToGive;
		
		for (new TFClassType:iClass = TFClassType:1; iClass < TFClassType:9; iClass ++) //Iterate through the classes
		{
			for (new iIndex; iIndex < PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], iClass); iIndex ++) //Iterate through the upgrades themselves now. 
			{
				decl tmpUpgradeQueue[UpgradeQueue];
				PlayerData_GetUpgradeOnQueue(g_PlayerData[iClient][0], iClass, iIndex, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));

				if (tmpUpgradeQueue[_bOwned] == true)
				{
					iCreditsToGive += UpgradeDataStore_GetUpgradeCost(g_UpgradeDataStore[0], tmpUpgradeQueue[_Upgrade]);//Get the value of the upgrade we're refunding then add it to the amount of credits the client will gain.
				}	
			}

			//Reset the upgrade queue itself so it is empty.
			PlayerData_ResetUpgradeQueue(g_PlayerData[iClient][0], iClass);
		}

		//Now that we have the total cost of their upgrades we can give them their credits.
		new iNewCredits = Set_iClientCredits(iCreditsToGive, SET_ADD, iClient, ESC_CREDITS_REFUND_FULL);

		if (bInform)
		{
			CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Cleared_All_Classes");
			CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Refunded_New_Credits", iNewCredits);
		}
		
		//If the client's loadout isn't refreshed they would end up with upgrades they didn't actually own on their weapons.
		PlayerData_SetForceQueueReprocess(g_PlayerData[iClient][0], true);

		return;
	}
	
	new TFClassType:iClassToRefund;
	new iCreditsToGive;
	
	iClassToRefund = GetClassID(Class);

	//Make sure they've specified a valid class.
	if (iClassToRefund == TFClass_Unknown)
	{
		CPrintToChat(iClient,"%t %t", "Escalation_Tag", "Refund_Invalid_Class", Class);
		
		return;
	}

	//Check if this is the class the client is currently playing as, if so set their loadout to needing a refresh.
	if (IsClientInGame(iClient))
	{
		if (iClassToRefund == TF2_GetPlayerClass(iClient))
		{
			PlayerData_SetForceQueueReprocess(g_PlayerData[iClient][0], true);
		}
	}

	//Make sure there are actually some upgrades on this class.
	if (PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], iClassToRefund) == 0)
	{
		if (bInform)
		{	
			CPrintToChat(iClient,"%t %t", "Escalation_Tag", "Clear_Empty_Queue")
		}

		return;
	}

	for (new iIndex = 0; iIndex < PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], iClassToRefund); iIndex ++) //Now we can go through the upgrades themselves.
	{
			decl tmpUpgradeQueue[UpgradeQueue];
			PlayerData_GetUpgradeOnQueue(g_PlayerData[iClient][0], iClassToRefund, iIndex, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
			
			if (tmpUpgradeQueue[_bOwned] == true)
			{
				iCreditsToGive += UpgradeDataStore_GetUpgradeCost(g_UpgradeDataStore[0], tmpUpgradeQueue[_Upgrade]);//Get the value of the upgrade we're refunding then add it to the amount of credits the client will gain.
			}
	}

	new iNewCredits = Set_iClientCredits(iCreditsToGive, SET_ADD, iClient, ESC_CREDITS_REFUND_FULL);

	//Reset the upgrade queue itself so it is empty.
	PlayerData_ResetUpgradeQueue(g_PlayerData[iClient][0], iClassToRefund);

	if (bInform)
	{		
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Cleared_Success_Class");
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Refunded_New_Credits", iNewCredits);
	}

	return;
}

/**
 * Pushes an upgrade onto the client's upgrade queue.
 *
 * @param iClient				The index of the client wanting the upgrade.
 * @param Upgrade				The name of the upgrade to push onto the queue..
 * @param iClass				The class whose upgrade queue to push the upgrade onto.
 * @param bRespond				If true the client will be informed of success or failure by chat messages.
 * @param bForce				If true the bypass the check of if the client is allowed the upgrade.
 *								This does not let the client buy the upgrade. Their current class and weapons must still be allowed it.
 *								It is designed to let other plugins add upgrade to the client's queue when their loadout is not yet known.
 *
 * @return						True if the upgrade was pushed onto the queue successfully, false if an error occured.
 */
bool:PushUpgrade(iClient, const String:Upgrade[UPGRADE_NAME_MAXLENGTH], TFClassType:iClass, bool:bRespond, bool:bForce = false)
{
	//Allocate the memory to store a copy of the upgrade's object.
	decl tmpUpgradeData[UpgradeData];

	//Try to get the upgrade the user wants.
	if (! UpgradeDataStore_GetUpgrade(g_UpgradeDataStore[0], Upgrade, tmpUpgradeData[0], sizeof(tmpUpgradeData)))
	{
		if (bRespond)
		{
			CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Upgrade_Not_Found", Upgrade);
			CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Upgrade_Not_Found_Bug");
		}
		
		return false;		
	}

	//Fetch the upgrade's slot.
	new iSlot = UpgradeData_GetSlot(tmpUpgradeData[0]);

	//And the highest we can upgrade this to.
	new iMaxLevel = UpgradeData_GetLevelCount(tmpUpgradeData[0]);
	new iNextLevel;

	new iClientWeaponIndex = PlayerData_GetWeaponID(g_PlayerData[iClient][0], iSlot);


	//Check to see if the upgrade is passive, if it was we treat it as a clas upgrade.
	if (! UpgradeData_IsPassive(tmpUpgradeData[0]))
	{
		//Check to see if da weapon is allowed the upgrade.
		if (! IsWeaponAllowedUpgrade(iClient, iClientWeaponIndex, Upgrade, iClass) && ! bForce)
		{
			if (bRespond)
			{
				CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Upgrade_Weapon_Not_Allowed");	
			}

			return false;
		}
	}
	else
	{
		if (! ClassInfoStore_IsUpgradeAllowed(g_ClassInfoStore[0], iClass, Upgrade) && ! bForce)
		{
			if (bRespond)
			{
				CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Upgrade_Class_Not_Allowed");	
			}
			
			return false;
		}
	}

	// PlayerData_PushUpgradeOntoQueue returns false when an upgrade already is at iMaxLevel on the queue.
	if (! PlayerData_PushUpgradeToQueue(g_PlayerData[iClient][0], iClass, Upgrade, iMaxLevel, iNextLevel))
	{
		if (bRespond)
		{
			CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Upgrade_Highest_Level");
		}

		return false;
	}

	if (bRespond)
	{
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Upgrade_Added_Success", Upgrade, iNextLevel);
	}

	return true;
}

/**
 * Creates a Remove Upgrade Queue menu for a client.
 *
 * @param iClient				The index of the client wanting the menu.
 *
 * @noreturn
 */
Handle:GetRemoveUpgradeQueueMenu(iClient)
{
	new Handle:hMenu = CreateMenu(Menu_RemoveUpgradeQueue, MenuAction_Select | MenuAction_DisplayItem | MenuAction_Cancel | MenuAction_End);

	for (new i = 0; i < PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], TF2_GetPlayerClass(iClient)); i ++)
	{
		decl tmpUpgradeQueue[UpgradeQueue];
	
		PlayerData_GetUpgradeOnQueue(g_PlayerData[iClient][0], TF2_GetPlayerClass(iClient), i, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
	
		AddMenuItem(hMenu, tmpUpgradeQueue[_Upgrade], "UNFORMATTED_UPGRADE_TEXT");
	}
	
	SetMenuTitle(hMenu, "%T", "Menu_Select_Upgrade_Remove", iClient)
	SetMenuExitBackButton(hMenu, true);

	return hMenu;
}

/**
 * Creates a Edit Upgrade Queue menu for a client.
 *
 * @param iClient				The index of the client wanting the menu.
 *
 * @noreturn
 */
Handle:GetEditUpgradeQueueMenu(iClient)
{
	new Handle:hMenu = CreateMenu(Menu_EditUpgradeQueue, MenuAction_Select | MenuAction_DisplayItem | MenuAction_Cancel | MenuAction_End);

	for (new i = 0; i < PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], TF2_GetPlayerClass(iClient)); i ++)
	{
		decl tmpUpgradeQueue[UpgradeQueue];
	
		PlayerData_GetUpgradeOnQueue(g_PlayerData[iClient][0], TF2_GetPlayerClass(iClient), i, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));

		if (tmpUpgradeQueue[_bOwned])
		{
			AddMenuItem(hMenu, tmpUpgradeQueue[_Upgrade], "UNFORMATTED_UPGRADE_TEXT", ITEMDRAW_IGNORE);
		}
		else
		{
			AddMenuItem(hMenu, tmpUpgradeQueue[_Upgrade], "UNFORMATTED_UPGRADE_TEXT");
		}
	}

	SetMenuTitle(hMenu, "%T", "Menu_Select_Upgrade_Shift", iClient)
	SetMenuExitBackButton(hMenu, true);

	return hMenu;
}

/************************UPGRADE QUEUE FUNCTIONS************************/

/**
 * Processes a client's upgrade queue.
 *
 * @param iClient				The index of the client of whose upgrade queue to process.
 *
 * @noreturn
 */
ProcessUpgradeQueue(iClient)
{
	//Check if the upgrade queue needs reprocessing.
	if (PlayerData_GetForceQueueReprocess(g_PlayerData[iClient][0]))
	{
		PlayerAttributeManager_ClearAttributes(iClient);
		WeaponAttributes_Clear(iClient);
		PlayerData_ResetQueuePosition(g_PlayerData[iClient][0]);

		PlayerData_SetForceQueueReprocess(g_PlayerData[iClient][0], false)
	}

	if (PlayerData_HaveWeaponsChanged(g_PlayerData[iClient][0]))
	{
		PlayerAttributeManager_ClearAttributes(iClient);
		WeaponAttributes_Clear(iClient);
		
		for (new i = 0; i < UPGRADABLE_SLOTS; i ++)
		{
			decl iAttributes[ENTITY_MAX_ATTRIBUTES];
			decl Float:fValues[ENTITY_MAX_ATTRIBUTES];
		
			if (StockAttributes_GetItemAttributes(g_StockAttributes[0], PlayerData_GetWeaponID(g_PlayerData[iClient][0], i), iAttributes, fValues))
			{
				WeaponAttributes_SetAttributes(iClient, i, iAttributes, fValues);
			}
		}


		PlayerData_ResetQueuePosition(g_PlayerData[iClient][0]);
	}

	//This has to come after PlayerData_HaveWeaponsChanged to allow it to cache the player's weapon indexes.
	if (IsPluginDisabled() || ! g_bBuyUpgrades)
	{
		return;
	}

	//Process the upgrade queue.
	for ( ; PlayerData_GetQueuePosition(g_PlayerData[iClient][0]) < PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], TF2_GetPlayerClass(iClient)); PlayerData_IncrementQueuePosition(g_PlayerData[iClient][0]) )
	{
		if (! (ProcessQueueAtPosition(iClient, PlayerData_GetQueuePosition(g_PlayerData[iClient][0]))))
		{
			break;
		}
	}


	WeaponAttributes_Apply(iClient);
	PlayerAttributeManager_ApplyAttributes(iClient);
}

/**
 * Processes an upgrade on a client's queue, buying it if possible
 * and adding it's attributes to the client if it was brought.
 *
 * @param iClient				The index of the client of whose upgrade queue to process.
 * @param iIndex				The index of the upgrade on the queue to process.
 *
 * @noreturn
 */
ProcessQueueAtPosition(iClient, iIndex)
{    
	decl tmpUpgradeQueue[UpgradeQueue];
	PlayerData_GetUpgradeOnQueue(g_PlayerData[iClient][0], TF2_GetPlayerClass(iClient), iIndex, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue)); //Fetch the upgrade from the queue.
	
	//Allocate the memory to store a copy of the upgrade's object.
	decl tmpUpgradeData[UpgradeData];
	
	if (! UpgradeDataStore_GetUpgrade(g_UpgradeDataStore[0], tmpUpgradeQueue[_Upgrade], tmpUpgradeData[0], sizeof(tmpUpgradeData)))
	{
		ThrowError("Invalid upgrade passed to function. \"%s\" - Upgrade", tmpUpgradeQueue[_Upgrade]); 
	}
	
	//Fetch all the values related to the upgrade.
	new iUpgradeCost = UpgradeData_GetCost(tmpUpgradeData[0]);
	new iUpgradeSlot = UpgradeData_GetSlot(tmpUpgradeData[0]);
	new bool:bIsPassive = UpgradeData_IsPassive(tmpUpgradeData[0]);
	new iClientWeaponIndex = PlayerData_GetWeaponID(g_PlayerData[iClient][0], iUpgradeSlot);
	
	//Check to see if the client is allowed the upgrade. 
	new bool:bIsAllowedUpgrade = IsWeaponAllowedUpgrade(iClient, iClientWeaponIndex, tmpUpgradeQueue[_Upgrade], TF2_GetPlayerClass(iClient));
	
	if (! bIsAllowedUpgrade)
	{
		bIsAllowedUpgrade = ClassInfoStore_IsUpgradeAllowed(g_ClassInfoStore[0], TF2_GetPlayerClass(iClient), tmpUpgradeQueue[_Upgrade]);
	}
	

	if (! bIsAllowedUpgrade)
	{
		//If the client isn't allowed the upgrade the odds are they have done some trickery and switched loadouts, thus we need to refund their credits.
		if (tmpUpgradeQueue[_bOwned] == true)
		{		
			Set_iClientCredits(iUpgradeCost, SET_ADD, iClient, ESC_CREDITS_REFUNDED); //Refund the credits.
			tmpUpgradeQueue[_bOwned] = false; //Set the upgrade to not owned.
			PlayerData_SetUpgradeOnQueue(g_PlayerData[iClient][0], TF2_GetPlayerClass(iClient), iIndex, tmpUpgradeQueue[0]); //Store the modified upgrade.
		}
	
		return true; //Return from the function.
	}
	
	if (tmpUpgradeQueue[_bOwned] == false) //Check to see if the client owns this upgrade. If they don't we try to buy it, if they can't afford it we return false.
	{
		if (iUpgradeCost > PlayerData_GetCredits(g_PlayerData[iClient][0]))
		{
			return false; //Not enough money for this upgrade yet, so sad.
		}
		
		Set_iClientCredits(iUpgradeCost, SET_SUBTRACT, iClient, ESC_CREDITS_PURCHASE);//The player can afford the upgrade! HUZZAH!			
		tmpUpgradeQueue[_bOwned] = true; //Set the upgrade to owned.
		PlayerData_SetUpgradeOnQueue(g_PlayerData[iClient][0], TF2_GetPlayerClass(iClient), iIndex, tmpUpgradeQueue[0]); //Store the modified upgrade on the queue.		
	}

	//Fetch the LevelData object containing the attributes.
	decl tmpLevelData[LevelData];	
	UpgradeData_GetLevel(tmpUpgradeData[0], tmpUpgradeQueue[_iLevel], tmpLevelData[0]);
	
	//Iterate through the attributes of the weapons.
	for (new i = 0; i < LevelData_GetAttributeCount(tmpLevelData[0]); i ++)
	{
		decl tmpAttributeInfo[AttributeInfo];
	
		LevelData_GetAttribute(tmpLevelData[0], i, tmpAttributeInfo[0]);

		//Check to see if the upgrade is passive, if it is we apply it to the player directly.
		if (bIsPassive)
		{
			PlayerAttributeManager_AddAttribute(iClient, tmpAttributeInfo[_iAttribute], tmpAttributeInfo[_fValue], tmpAttributeInfo[_bIsPercent]);
		}
		else //Else we use apply it the weapon.
		{
			WeaponAttributes_Add(iClient, iUpgradeSlot, tmpAttributeInfo[_iAttribute], tmpAttributeInfo[_fValue], tmpAttributeInfo[_bIsPercent]);
		}
	}

	return true;
}


/************************UPGRADE UTILITY FUNCTIONS************************/

/**
 * Checks to see if a weapon is allowed an upgrade.
 *
 * @param iClient				The index of the client to see if they're allowed the upgrade.
 * @param iClientWeaponIndex	The index of the weapon to check.
 * @param Upgrade				The name of the upgrade to check.
 * @param iClass				The class the client is currently playing as.
 *
 * @return						True if the weapon is allowed the upgrade, false if it isn't.
 */
bool:IsWeaponAllowedUpgrade(iClient, iClientWeaponIndex, const String:Upgrade[], TFClassType:iClass)
{
	//First see if the upgrade has been outright banned by the server admin.
	if (BannedUpgrades_IsUpgradeBanned(g_BannedUpgrades[0], Upgrade))
	{
		return false;
	}

	//After we've checked that the server admin is fine with the upgrade we check it against the weapons the client has equiped.
	for (new iSlot; iSlot < UPGRADABLE_SLOTS; iSlot ++)
	{
		if (BannedUpgrades_IsComboBanned(g_BannedUpgrades[0], PlayerData_GetWeaponID(g_PlayerData[iClient][0], iSlot), Upgrade))
		{
			return false;
		}
	}

	return WeaponInfoManager_IsWeaponAllowedUpgrade(g_WeaponInfoManager[0], iClientWeaponIndex, Upgrade, iClass); //Return the answer.
}


/**
 * Checks to see if a client is allowed an upgrade.
 * This, unlike IsWeaponAllowedUpgrade does not require any pre-existing knowledge of the client.
 * And performs checks against the class and all the client's weapons as well.
 *
 * @param iClient				The index of the client to see if they're allowed the upgrade.
 * @param Upgrade				The name of the upgrade to check.
 *
 * @return						True if the client is allowed the upgrade, false if they aren't.
 */
bool:IsClientAllowedUpgrade(iClient, const String:Upgrade[])
{
	decl tmpUpgradeData[UpgradeData];
	
	if (! UpgradeDataStore_GetUpgrade(g_UpgradeDataStore[0], Upgrade, tmpUpgradeData[0], sizeof(tmpUpgradeData)))
	{
		ThrowError("Invalid upgrade passed to function. \"%s\" - Upgrade", Upgrade); 
	}

	new iSlot = UpgradeData_GetSlot(tmpUpgradeData[0]);
	new iClientWeaponIndex = PlayerData_GetWeaponID(g_PlayerData[iClient][0], iSlot);
	
	//First see if the upgrade has been outright banned by the server admin.
	if (BannedUpgrades_IsUpgradeBanned(g_BannedUpgrades[0], Upgrade))
	{
		return false;
	}

	//After we've checked that the server admin is fine with the upgrade we check it against the weapons the client has equiped.
	for (new i; i < UPGRADABLE_SLOTS; i ++)
	{
		if (BannedUpgrades_IsComboBanned(g_BannedUpgrades[0], PlayerData_GetWeaponID(g_PlayerData[iClient][0], i), Upgrade))
		{
			return false;
		}
	}

	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	
	new bool:bResult = WeaponInfoManager_IsWeaponAllowedUpgrade(g_WeaponInfoManager[0], iClientWeaponIndex, Upgrade, iClass);
	
	if (! bResult)
	{
		bResult = ClassInfoStore_IsUpgradeAllowed(g_ClassInfoStore[0], iClass, Upgrade);
	}
	
	return  bResult; //Return the answer.
}

/************************UTILITY FUNCTIONS************************/

/**
 * Gets the average earned credits of client's in the game.
 *
 * @param iExclude				The index of the client to to exclude from averaging the credits.
 *
 * @return						The average credits of client's in the game.
 */
GetAverageCredits(iExclude = 0)
{
	new iCredits;
	new iClientCount;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && g_bClientHasData[i] && i != iExclude)
		{
			iCredits += PlayerData_GetEarnedCredits(g_PlayerData[i][0]);
			iClientCount++;
		}
	}
	
	//This check here provides protection against that pesky integer division by zero that computers absolutely hate running into.
	if (iClientCount > 0 && iCredits > 0)
	{
		return iCredits / iClientCount;
	}
	else
	{
		return 0;
	}
}

/**
 * Forces a client's cached loadout to be refreshed.
 *
 * @param iClient				The index of the client to refresh.
 *
 * @noreturn
 */
ForceCachedLoadoutRefresh(iClient)
{
	new bool:bHandledWearables;
	
	for (new i = 0; i < UPGRADABLE_SLOTS; i++)
	{
		new iEntity = GetPlayerWeaponSlot(iClient, i);
		
		//Handle the wearables.
		if (! IsValidEntity(iEntity) && ! bHandledWearables)
		{
			decl iWearables[PLAYER_MAX_WEARABLES];

			new iWearableCount = GetClientWearables(iClient, iWearables, sizeof(iWearables));
			
			for (new iWearableIndex = 0; iWearableIndex < iWearableCount; iWearableIndex ++)
			{
				new iItemDefinitionIndex = GetEntProp(iWearables[iWearableIndex], Prop_Send, "m_iItemDefinitionIndex");
				
				new iSlot = WeaponInfoManager_GetSlot(g_WeaponInfoManager[0], iItemDefinitionIndex, TF2_GetPlayerClass(iClient));
		
				if (iSlot != WEAPONINFO_INVALID_SLOT)
				{
					PlayerData_UpdateWeapon(g_PlayerData[iClient][0], iSlot, iItemDefinitionIndex);
					WeaponAttributes_UpdateWeaponEnt(iClient, iSlot, iWearables[iWearableIndex]);
				}
			}
			
			bHandledWearables = true;
			
			continue;
		}
		
		new iItemDefinitionIndex = GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
		
		new iSlot = WeaponInfoManager_GetSlot(g_WeaponInfoManager[0], iItemDefinitionIndex, TF2_GetPlayerClass(iClient));
		
		if (iSlot != WEAPONINFO_INVALID_SLOT)
		{
			PlayerData_UpdateWeapon(g_PlayerData[iClient][0], iSlot, iItemDefinitionIndex);
			WeaponAttributes_UpdateWeaponEnt(iClient, iSlot, iEntity);
		}
	}
}

/**
 * Checks if a client index is valid, connected and useable by the plugin (I.e not replay or STV).
 *
 * @param iClient				The index of the client to check.
 *
 * @return						True if the client the client is valid and safe, false if otherwise.
 */
bool:IsClientValid(iClient)
{
	if (iClient <= 0 || iClient > MaxClients)
	{
		return false;
	}
	else if (! IsClientConnected(iClient))
	{
		return false;
	}
	else if (IsClientReplay(iClient) || IsClientSourceTV(iClient))
	{
		return false;
	}

	return true;
}

/************************GETTERS & SETTERS************************/

//These functions enable most of the code of the plugin to stop caring about how or where data is stored. 
//You should never access a global variable directly, instead use these to set and get them. This allows you to just update these functions to chnage something about the variable rather than all the places the variables are changed.
//Setters also return the new value of a variable, enabling you to save calling the get function if you need the new value straight after. It should also be noted that if a setter receives invalid flags it will throw an error.

//All setters follow these rules for arguments.
//Value - The value the function will be operating with. Depending on the variable it'll be prefixed with i,f or b.
//iOperation - The operation to take. Use the enum Set_Operation for these.
// 0 - Absolute Set - Sets the value to exactly what the argument sent is. Boolean setters only support this operation.
// 1 - Multiply - Multiplies the variable by the value.
// 2 - Divide - Divides the variable by the value. 
// 3 - Add - Adds value to the variable.
// 4 - Subtract - Subtracts value from variable.
// 5 - Modulo - Performs a modulo operation on variable with value. (variable % value) This operation is not supported on float setters.
//
//Getters and Setters will sometimes share a varying amount of index arguments when the variable being set is an array.
//indexes - If the variable is an array you'll be required to supply a varying amount of indexes for it.

/**
 * Sets the credit count of a client.
 *
 * @param iValue				The value to use with the set operation.
 * @param iOperation			The set operation to take.
 * @param iClient				the client to set the credits of.
 * @param iFlags				The flags containing the reason the client is getting these credits.
 *
 * @return						the client's new credit count.
 */
Set_iClientCredits(iValue, Set_Operation:iOperation, iClient, iFlags)
{
	//Call the Forward
	Call_StartForward(g_hClientCreditsChanged); //Esc_ClientCreditsChanged
	
	Call_PushCell(iClient);
	Call_PushCellRef(iOperation);
	Call_PushCell(iFlags);
	Call_PushCellRef(iValue);

	Call_Finish();
	
	//Handle that there total earned credits.
	if (iFlags & ESC_CREDITS_RESET)
	{
		PlayerData_SetEarnedCredits(g_PlayerData[iClient][0], 0, iOperation);
	}	
	else if (iFlags & ESC_CREDITS_STARTING || iFlags & ESC_CREDITS_PURCHASE || iFlags & ESC_CREDITS_REFUNDED || iFlags & ESC_CREDITS_REFUND_FULL || iFlags & ESC_CREDITS_OBJECTIVE || iFlags & ESC_CREDITS_NOAVERAGE)
	{
		//Quite dull when the credits aren't supposed to be averaged.
	}
	else
	{
		PlayerData_SetEarnedCredits(g_PlayerData[iClient][0], iValue, iOperation);
	}

	return PlayerData_SetCredits(g_PlayerData[iClient][0], iValue, iOperation);
}

/**
 * Gets the objective credits of a team.
 *
 * @param team					The team to get the credits of.
 *
 * @return						The team's credit count.
 */
Get_iObjectiveCredits(team)
{
	return g_iObjectiveCredits[team];
}	

/**
 * Sets the objective credits of a team.
 *
 * @param iValue				The value to use with the set operation.
 * @param iOperation			The set operation to take.
 * @param team					The team to set the credits of.
 *
 * @return						The team's new credit count.
 */
Set_iObjectiveCredits(iValue, Set_Operation:iOperation, team)
{
	if (iOperation == SET_ABSOLUTE) //Check to see if the user wants an Absolute Set on the variable.
	{
		g_iObjectiveCredits[team] = iValue; //Set the value.
		return g_iObjectiveCredits[team]; //Return the variable.
	}
	else if (iOperation == SET_MULTIPLY)
	{
		g_iObjectiveCredits[team] *= iValue;
		return g_iObjectiveCredits[team];
	}
	else if (iOperation == SET_DIVIDE)
	{
		g_iObjectiveCredits[team] /= iValue;
		return g_iObjectiveCredits[team];				
	}
	else if (iOperation == SET_ADD)
	{
		g_iObjectiveCredits[team] += iValue;
		return g_iObjectiveCredits[team];		
	}
	else if (iOperation == SET_SUBTRACT)
	{
		g_iObjectiveCredits[team] -= iValue;
		return g_iObjectiveCredits[team];		
	}
	else if (iOperation == SET_MODULO)
	{
		g_iObjectiveCredits[team] %= iValue;
		return g_iObjectiveCredits[team];		
	}
	else 
	{
		ThrowError("Invalid operation sent to setter function.");
	}
	
	//The compiler complains when a function doesn't return a value. This is here to make it happy.
	return g_iObjectiveCredits[team];
}

/************************NATIVE FUNCTIONS************************/

/**
 * Native callback for pushing an upgrade onto a client's queue.
 *
 * @param hPlugin				Handle to the calling plugin.
 * @param iNumParams			The number of arguments passed to the function.
 *
 * @return						True on the upgrade being pushed to the client's queue.
 */
public Native_Esc_PushUpgradeOntoQueue (Handle:hPlugin, iNumParams)
{
	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	if (iNumParams != 5)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid number of arguments passed to functions.");
	}

	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}

	new iClient = GetNativeCell(1);

	if (! IsClientValid(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i) passed to function.", iClient);
	}

	decl String:Upgrade[UPGRADE_NAME_MAXLENGTH];
	GetNativeString(2, Upgrade, sizeof(Upgrade));
	
	new TFClassType:iClass = TFClassType:GetNativeCell(3);

	if (! IsValidClass(iClass))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid class (%i) passed to function.", iClient);
	}
	
	new bool:bRespond = bool:GetNativeCell(4);
	new bool:bForce = bool:GetNativeCell(5);
	
	return PushUpgrade(iClient, Upgrade, iClass, bRespond, bForce);
}

/**
 * Native callback for getting an upgrade from a client's queue.
 *
 * @param hPlugin				Handle to the calling plugin.
 * @param iNumParams			The number of arguments passed to the function.
 *
 * @noreturn
 */
public Native_Esc_GetUpgradeFromQueue (Handle:hPlugin, iNumParams)
{
	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	if (iNumParams != 5)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid number of arguments passed to functions.");
	}

	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	new iClient = GetNativeCell(1);
	new iIndex = GetNativeCell(2);
	new TFClassType:iClass = TFClassType:GetNativeCell(3);
	new iBufferSize = GetNativeCell(5);

	decl tmpUpgradeQueue[UpgradeQueue];

	if (! IsClientValid(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i) passed to function.", iClient);
	}
	
	if (! IsValidClass(iClass))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid class (%i) passed to function.", iClient);
	}

	if (iBufferSize > sizeof(tmpUpgradeQueue))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Buffer to store UpgradeQueue struct in is not large enough.", iClient);
	}

	new iQueueSize = PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], iClass);
	
	if (iIndex > iQueueSize || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "iIndex (%i) is out of range.", iIndex);
	}
	
	PlayerData_GetUpgradeOnQueue(g_PlayerData[iClient][0], iClass, iIndex, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
	
	SetNativeArray(4, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));
}

/**
 * Native callback for removing an upgrade from a client's queue.
 *
 * @param hPlugin				Handle to the calling plugin.
 * @param iNumParams			The number of arguments passed to the function.
 *
 * @noreturn
 */
public Native_Esc_RemoveUpgradeFromQueue (Handle:hPlugin, iNumParams)
{
	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	if (iNumParams != 4)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid number of arguments passed to functions.");
	}

	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	new iClient = GetNativeCell(1);
	new iIndex = GetNativeCell(2);
	new TFClassType:iClass = TFClassType:GetNativeCell(3);
	new bool:bInform = bool:GetNativeCell(4);
	
	if (! IsClientValid(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i) passed to function.", iClient);
	}
	
	if (! IsValidClass(iClass))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid class (%i) passed to function.", iClient);
	}

	new iQueueSize = PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], iClass);
	
	if (iIndex > iQueueSize || iIndex < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "iIndex (%i) is out of range.", iIndex);
	}

	decl tmpUpgradeQueue[UpgradeQueue];	
	PlayerData_GetUpgradeOnQueue(g_PlayerData[iClient][0], iClass, iIndex, tmpUpgradeQueue[0], sizeof(tmpUpgradeQueue));

	if (tmpUpgradeQueue[_bOwned])
	{
		new iCost = UpgradeDataStore_GetUpgradeCost(g_UpgradeDataStore[0], tmpUpgradeQueue[_Upgrade]);
		Set_iClientCredits(iCost, SET_ADD, iClient, ESC_CREDITS_REFUNDED);
		
		PlayerData_SetForceQueueReprocess(g_PlayerData[iClient][0], true);
		
		if (bInform)
		{
			CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Upgrade_Removed_Credits", tmpUpgradeQueue[_Upgrade], iCost);
		}
	}
	else if (bInform)
	{
		CPrintToChat(iClient, "%t %t", "Escalation_Tag", "Upgrade_Removed", tmpUpgradeQueue[_Upgrade]);
	}
	
	PlayerData_RemoveUpgradeFromQueue(g_PlayerData[iClient][0], iClass, iIndex);
}

/**
 * Native callback for getting a client's upgrade queue size.
 *
 * @param hPlugin				Handle to the calling plugin.
 * @param iNumParams			The number of arguments passed to the function.
 *
 * @return						The client's upgrade queue size.
 */
public Native_Esc_GetUpgradeQueueSize (Handle:hPlugin, iNumParams)
{
	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	if (iNumParams != 2)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid number of arguments passed to functions.");
	}

	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	new iClient = GetNativeCell(1);
	new TFClassType:iClass = TFClassType:GetNativeCell(2);

	if (! IsClientValid(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i) passed to function.", iClient);
	}
	
	if (! IsValidClass(iClass))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid class (%i) passed to function.", iClient);
	}
	
	return PlayerData_GetUpgradeQueueSize(g_PlayerData[iClient][0], iClass);
}

/**
 * Native callback for clearing a client's upgrade queue.
 *
 * @param hPlugin				Handle to the calling plugin.
 * @param iNumParams			The number of arguments passed to the function.
 *
 * @noreturn
 */
public Native_Esc_ClearUpgradeQueue (Handle:hPlugin, iNumParams)
{
	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	if (iNumParams != 3)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid number of arguments passed to functions.");
	}

	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	new iClient = GetNativeCell(1);
	new TFClassType:iClass = TFClassType:GetNativeCell(2);
	new bool:bInform = bool:GetNativeCell(3);
	
	if (! IsClientValid(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i) passed to function.", iClient);
	}
	
	if (! IsValidClass(iClass))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid class (%i) passed to function.", iClient);
	}
	
	decl String:Class[32];
	ClassIDToName(iClass, Class, sizeof(Class));
	
	ClearUpgrades(iClient, bInform, Class);
}

/**
 * Native callback for setting a client's credits.
 *
 * @param hPlugin				Handle to the calling plugin.
 * @param iNumParams			The number of arguments passed to the function.
 *
 * @return						The client's upgrade queue size.
 */
public Native_Esc_SetClientCredits (Handle:hPlugin, iNumParams)
{
	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}
	
	if (iNumParams != 4)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid number of arguments passed to functions.");
	}

	new iClient = GetNativeCell(1);
	new Set_Operation:iOperation = Set_Operation:GetNativeCell(2);
	new iFlags = GetNativeCell(3);
	new iValue = GetNativeCell(4);
	
	iFlags |= ESC_CREDITS_PLUGIN;
	
	if (! IsClientValid(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i) passed to function.", iClient);
	}
	
	return Set_iClientCredits(iValue, iOperation, iClient, iFlags);
}

/**
 * Native callback for checking if the plugin is running.
 *
 * @param hPlugin				Handle to the calling plugin.
 * @param iNumParams			The number of arguments passed to the function.
 *
 * @return						True if the plugin is active, false if it isn't.
 */
public Native_Esc_IsPluginActive (Handle:hPlugin, iNumParams)
{
	return g_bPluginStarted;
}

/**
 * Native callback for getting an array of upgrade names.
 *
 * @param hPlugin				Handle to the calling plugin.
 * @param iNumParams			The number of arguments passed to the function.
 *
 * @return						Handle.
 */
public Native_Esc_GetArrayOfUpgrades (Handle:hPlugin, iNumParams)
{
	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}

	new Handle:hMyArray = UpgradeDataStore_GetArrayOfUpgrades(g_UpgradeDataStore[0]);
	new Handle:hArray = CloneHandle(hMyArray, hPlugin);
	CloseHandle(hMyArray);
	
	return _:hArray;
}

/**
 * Native callback for checking if a client has data.
 *
 * @param hPlugin				Handle to the calling plugin.
 * @param iNumParams			The number of arguments passed to the function.
 *
 * @return						True if the plugin is active, false if it isn't.
 */
public Native_Esc_ClientHasData (Handle:hPlugin, iNumParams)
{
	if (! g_bPluginStarted)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Escalation is not running.");
	}

	if (iNumParams != 1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid number of arguments passed to functions.");
	}

	new iClient = GetNativeCell(1);
	
	if (! IsClientValid(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i) passed to function.", iClient);
	}
	
	return g_bClientHasData[iClient];
}


/************************DEVELOPER COMMANDS************************/

#if defined DEV_BUILD

/**
 * Grants credits to the client that uses the command.
 * Can also be used to give other clients credits.
 *
 * @return An Action value.
 */
public Action:Command_GiveCredits(iClient, iArgs)
{
	new String:arg1[32];
	new String:arg2[32];
	
	if (iArgs < 1)
	{
		CReplyToCommand(iClient,"Usage: sm_givecredits <target> <credits>");
		return Plugin_Handled;
	}
	
	if (iArgs < 2)
	{
		GetCmdArg(1,arg1,sizeof(arg1));	
		Set_iClientCredits(StringToInt(arg1), SET_ADD, iClient, ESC_CREDITS_PLUGIN);
	
		decl String:clientName[MAX_NAME_LENGTH];
		GetClientName(iClient, clientName, sizeof(clientName));
		
		
		CShowActivity2(iClient, "{royalblue}[Escalation]{silver} ", "{silver}Someone has given %s {dodgerblue}%i{silver} credits.", clientName, StringToInt(arg1));
	}
	else if (iArgs < 3)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		
		new iCreditsToGive = StringToInt(arg1);
		
		//Grab the lucky man getting these credits.
		new iTarget = FindTarget(iClient, arg2);
		if (iTarget == -1)
			return Plugin_Handled;
		
		Set_iClientCredits(iCreditsToGive, SET_ADD, iTarget, ESC_CREDITS_PLUGIN);		
		
		decl String:targetName[MAX_NAME_LENGTH];
		GetClientName(iTarget, targetName, sizeof(targetName));
		
		CShowActivity2(iClient, "{royalblue}[Escalation]{silver} ", "{silver}Someone has given %s {dodgerblue}%i{silver} credits.", targetName, iCreditsToGive);		
		
	}
	
	return Plugin_Handled;
}

/**
 * Acts as a wrapper around Command_Upgrade calling it as if the target used the command.
 *
 * @return An Action value.
 */
public Action:Command_ForceUpgrade(iClient, iArgs)
{
	if (iArgs < 2)
	{
		ReplyToCommand(iClient, "Usage: sm_forceupgrade <upgrade> <target>");
		return Plugin_Handled;
	}

	new String:arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
		
	new iTarget = FindTarget(iClient, arg2);
		
	//Hand control over to Command_Upgrade
	return Command_Upgrade(iTarget, iArgs);
}

/**
 * Prints out the credits of all clients to the console.
 *
 * @return An Action value.
 */
public Action:Command_PrintCredits(iClient, iArgs)
{
	decl String:buffer1[MAX_NAME_LENGTH];

	for (new i = 1; i <= MaxClients; i++)
	{
		if (! IsClientConnected(i)) //Check if the client we're up to is connected. If they are not we jump to the start of the loop.
			continue;
			
		GetClientName(i, buffer1, sizeof(buffer1));	
			
		PrintToConsole(iClient, "iClient - %i Name - %s Credits - %i", i, buffer1, PlayerData_GetCredits(g_PlayerData[i][0]));	
	}

	return Plugin_Handled;
}

/**
 * Prints out the credits of all clients on a team to the console.
 *
 * @return An Action value.
 */
public Action:Command_PrintTeamCredits(iClient, iArgs)
{
	decl String:arg1[4];
	decl String:buffer1[MAX_NAME_LENGTH];
	
	GetCmdArg(1, arg1, sizeof(arg1)); 

	new iTeam = StringToInt(arg1);
	
	decl iClients[MaxClients+1];
	
	new iSize = GetClientsOnTeam(iTeam, iClients, MaxClients + 1);

	
	for (new i = 0; i <= iSize; i++)
	{
		GetClientName(iClients[i], buffer1, sizeof(buffer1));				
		PrintToConsole(iClient, "iClient - %i Name - %s Credits - %i", iClients[i], buffer1, PlayerData_GetCredits(g_PlayerData[i][0]));		
	}
	
	return Plugin_Handled;
}

/**
 * Prints out the earned credits of all clients to the console.
 *
 * @return An Action value.
 */
public Action:Command_PrintTotalCredits(iClient, iArgs)
{
	decl String:buffer1[MAX_NAME_LENGTH];

	for (new i = 1; i <= MaxClients; i++)
	{
		if (! IsClientValid(i) || ! g_bClientHasData[i])
			continue;
			
		GetClientName(i, buffer1, sizeof(buffer1));	
			
		PrintToConsole(iClient, "iClient - %i Name - %s Credits - %i", i, buffer1, PlayerData_GetEarnedCredits(g_PlayerData[i][0]));	
	}

	return Plugin_Handled;
}

/**
 * Displays the upgrade menu of the specified weapon to the client.
 *
 * @return An Action value.
 */
public Action:Command_ForceMenuDisplay(iClient, iArgs)
{
	if (iArgs < 1)
	{
		ReplyToCommand(iClient, "Usage: sm_forcemenu <weaponID> <classID (optional)>");
		return Plugin_Handled;
	}

	decl String:buffer1[32];
	decl String:buffer2[32];
	
	GetCmdArg(1, buffer1, sizeof(buffer1));
	
	if (iArgs > 1)
	{
		GetCmdArg(2, buffer2, sizeof(buffer2));
	}
	
	new iClientWeaponIndex = StringToInt(buffer1);
	new iClass = StringToInt(buffer2);
	
	if (IsAllClassWeapon(iClientWeaponIndex))
	{
		iClientWeaponIndex += 100000 * iClass;
	}
				
	new Handle:hMenuToDisplay = MenuCache_GetMenu(g_UpgradeMenuCache[0], iClientWeaponIndex);
				
	if (hMenuToDisplay == INVALID_HANDLE)
	{
		CReplyToCommand(iClient, "{royalblue}[Escalation]{silver} So sorry good Developer but this command can't display a menu for a weapon you haven't implemented yet.");
	}
	else
	{
		DisplayMenu(hMenuToDisplay, iClient, 60);
	}
	
	return Plugin_Handled;
}

/**
 * Forces a custom attribute onto the client using the command.
 *
 * @return An Action value.
 */
public Action:Command_ForceAttribute(iClient, iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "You can't use this command as server.");
		
		return Plugin_Handled;
	}

	decl String:buffer1[32];
	decl String:buffer2[32];
	
	GetCmdArg(1, buffer1, sizeof(buffer1));
	GetCmdArg(2, buffer2, sizeof(buffer2));
	
	new iAttribute = StringToInt(buffer1);
	new Float:fValue = StringToFloat(buffer2);
	
	Esc_ApplyCustomAttribute(iClient, iAttribute, fValue);
	
	ReplyToCommand(iClient, "Forced attribute %i onto iClient %N with value %f", iAttribute, iClient, fValue);
	
	return Plugin_Handled;
}

/**
 * Forces the plugin to enable itself on non-supported maps.
 *
 * @return An Action value.
 */
public Action:Command_ForceSupport(iClient, iArgs)
{
	g_bPluginDisabledForMap = false;

	if (! IsPluginDisabled() &&  ! g_bPluginStarted)
	{
		StartPlugin();
	}
	
	return Plugin_Handled;
}

/**
 * Destroys all global objects in order to test for memory leaks. This breaks the plugin.
 *
 * @return An Action value.
 */
public Action:Command_DestroyObjects(iClient, iArgs)
{
	WeaponInfoManager_Destroy(g_WeaponInfoManager[0]);
	MenuCache_Destroy(g_UpgradeMenuCache[0]);
	UpgradeDataStore_Destroy(g_UpgradeDataStore[0]);
	ClassInfoStore_Destroy(g_ClassInfoStore[0]);
	UpgradeDescriptions_Destroy(g_UpgradeDescriptions[0]);
	StockAttributes_Destroy(g_StockAttributes[0]);
	BannedUpgrades_Destroy(g_BannedUpgrades[0]);
	
	ReplyToCommand(iClient, "All objects have been destroyed. The plugin is now broken until you reload it.");
	
	return Plugin_Handled;
}

#endif
