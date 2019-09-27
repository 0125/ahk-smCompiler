stock float GetClientsDistance(int victim, int attacker) {
	float attackerPos[3];
	float victimPos[3];
	float mins[3];
	float maxs[3];
	float halfHeight;
	GetClientMins(victim, mins);
	GetClientMaxs(victim, maxs);
	
	halfHeight = maxs[2] - mins[2] + 10;
	
	GetClientAbsOrigin(victim,victimPos);
	GetClientAbsOrigin(attacker,attackerPos);
	
	float posHeightDiff = attackerPos[2] - victimPos[2];
	
	if (posHeightDiff > halfHeight)
	{
		attackerPos[2] -= halfHeight;
	}
	else if (posHeightDiff < (-1.0 * halfHeight))
	{
		victimPos[2] -= halfHeight;
	}
	else
	{
		attackerPos[2] = victimPos[2];
	}
	
	return GetVectorDistance(victimPos ,attackerPos, false);
}

stock void IncapPlayer(int client) {
	if(IsValidEntity(client))
	{
		int iDmgEntity = CreateEntityByName("point_hurt");
		SetEntityHealth(client, 1);
		SetTempHealth(client, 0); // prevents l4d1 server error msg spam: DataTable warning: (class player): Out-of-range value (-XX.000000) in SendPropFloat 'm_healthBuffer', clamping.
		DispatchKeyValue(client, "targetname", "bm_target");
		DispatchKeyValue(iDmgEntity, "DamageTarget", "bm_target");
		DispatchKeyValue(iDmgEntity, "Damage", "100");
		DispatchKeyValue(iDmgEntity, "DamageType", "32"); // using falldamage (32) prevents a bug where if a player gets incapped multiple times in a row in short succession he does not get incapped
		DispatchSpawn(iDmgEntity);
		AcceptEntityInput(iDmgEntity, "Hurt", client);
		DispatchKeyValue(client, "targetname", "bm_targetoff");
		RemoveEdict(iDmgEntity);
	}
}

stock int GetTempHealth(int client) {
	float decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float time = (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime"));
	float TempHealth = buffer - (time * decay);
	if (TempHealth < 0) return 0;
	else return RoundToFloor(TempHealth);
}

stock int SetTempHealth(int client, int hp) {
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	float TempHealthFloat = hp * 1.0; //prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealthFloat);
}

stock bool IsPlayerIncapped(int client) {
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) 
		return true;
	else
		return false;
}

stock bool IsValidClient(int client) {
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

stock bool IsSurvivor(int client) {
	if (client > 0 && client < MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
		return true;
	return false;
}

stock bool L4D_IsSurvivorAffectedBySI(int client) {
	return GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 || 
		GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0;
}

stock bool L4D2_IsSurvivorAffectedBySI(int client) {
	return GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 || 
		GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 || 
		GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 || 
		GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 || 
		GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0;
}

stock bool IsServerEmpty() {
	for (int i=1; i<=MaxClients; i++)
		if (IsValidClient(i))
			return false;
	return true;
}

stock bool IsPlayerOnFire(int client) {
	if(GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE) return true;
	else return false;
}

stock int IsPlayerTank(int client) {
	if (GetClientTeam(client) != 3) return false; // 3=infected
	
	char playermodel[96];
	GetClientModel(client, playermodel, sizeof(playermodel));
	return (StrContains(playermodel, "hulk", false) > -1);
}

stock void SetTankSpeed(int client, float speed) {
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}

stock float GetTankSpeed(int client) {
	return GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
}