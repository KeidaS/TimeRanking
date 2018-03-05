#pragma semicolon 1


#include <sourcemod>
#include <sdktools>


public Plugin myinfo = 
{
	name = "Time Ranking",
	author = "KeidaS",
	description = "Ranking",
	version = "1.0",
	url = "www.hermandadfenix.es"
};

bool ok = false;
char queryBuffer[3096];

Handle db = INVALID_HANDLE;

int timePlayed[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("rank", Show_rank, "Shows ranking menu");
	ConnectDB();
}

public void ConnectDB() {
	char error[255];
	db = SQL_Connect("default", true, error, sizeof(error));
	
	if (db == INVALID_HANDLE) {
		LogError("ERROR CONNECTING TO THE DB"); 
	} else {
		Format(queryBuffer, sizeof(queryBuffer), "CREATE TABLE IF NOT EXISTS 'rank' (steamid VARCHAR(32) PRIMARY KEY NOT NULL, name varchar(64) NOT NULL, time INTEGER)");
		SQL_Query(db, queryBuffer, sizeof(queryBuffer));
	}
}

public void OnClientPostAdminCheck(int client) {
	char query[254];
	char steamID[32];
	if (!IsFakeClient(client)) {
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
		Format(query, sizeof(query), "SELECT time FROM rank WHERE steamid = '%s'", steamID);
		Handle getTime = SQL_Query(db, query, sizeof(query));
		if (db == INVALID_HANDLE) {
			LogError("ERROR CONNECTING TO THE DB"); 
		} else if (!SQL_GetRowCount(getTime)) {
			InsertClientToTable(client);
		} else {
			ok = true;
			timePlayed[client] = SQL_FetchInt(getTime, 0);
		}
	}
}

public void InsertClientToTable(client) {
	char query[254];
	char steamID[32];
	char name[64];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	GetClientName(client, name, sizeof(name));
	Format(query, sizeof(query), "INSERT INTO rank VALUES ('%s', '%s', 0)", steamID, name);
	SQL_Query(db, query, sizeof(query));
}

public void OnMapStart() {
	CreateTimer(1.0, TimeCount, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimeCount (Handle timer) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			timePlayed[i]++;
		}
	}
}

public void OnClientDisconnect(int client) {
	char query[254];
	char steamID[32];
	char name[64];
	if (!IsFakeClient(client)) {
		GetClientName(client, name, sizeof(name));
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
		Format(query, sizeof(query), "UPDATE rank SET name = %s, time = %i WHERE steamid = %s", name, timePlayed[client], steamID);
		SQL_Query(db, query, sizeof(query));
	}
}
public Action Show_rank(int client, int args) {
	if (ok) {
		PrintToChatAll("EZZZZ");
	}
	PrintToChatAll("%i", timePlayed[client]);
}