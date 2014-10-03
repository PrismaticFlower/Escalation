#if defined _escalation_included
#endinput
#endif
#define _escalation_included

#include<escalation_constants>

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
forward Esc_ClientCreditsChanged(iClient, Set_Operation:iOperation, &iFlags, &iValue);