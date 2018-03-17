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

int seconds = 0;
int minutes = 0;
int hours = 0;

bool playerReaded[MAXPLAYERS + 1] = false;

char queryBuffer[3096];

Handle db = INVALID_HANDLE;

int timePlayedT[MAXPLAYERS + 1];
int timePlayedCT[MAXPLAYERS + 1];
int timePlayedTotal[MAXPLAYERS + 1];
int timePlayedSpec[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("rank", Show_rank, "Shows ranking menu");
	ConnectDB();
}

public void ConnectDB() {
	char error[255];
	db = SQL_Connect("rankme", true, error, sizeof(error));
	
	if (db == INVALID_HANDLE) {
		LogError("ERROR CONNECTING TO THE DB"); 
	} else {
		Format(queryBuffer, sizeof(queryBuffer), "CREATE TABLE IF NOT EXISTS timerank (steamid VARCHAR(32) PRIMARY KEY NOT NULL, name varchar(64) NOT NULL, timeT INTEGER, timeCT INTEGER, timeTotal INTEGER, timeSpec INTEGER)");
		SQL_TQuery(db, ConnectDBCallback, queryBuffer);
	}
}
public void ConnectDBCallback(Handle owner, Handle hndl, char[] error, any data) {
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR CREATING THE TABLE");
		LogError("%s", error);
	}
}

public void OnClientPostAdminCheck(int client) {
	char query[254];
	char steamID[32];
	if (!IsFakeClient(client)) {
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
		Format(query, sizeof(query), "SELECT timeT, timeCT, timeTotal FROM timerank WHERE steamid = '%s'", steamID);
		SQL_TQuery(db, OnClientPostAdminCheckCallback, query, GetClientUserId(client));
	}
}

public void OnClientPostAdminCheckCallback(Handle owner, Handle hndl, char[] error, any data) {
	int client = GetClientOfUserId(data);
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR GETING THE TIME");
		LogError("%i", error);
	} else if (!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) {
		InsertClientToTable(client);
	} else {
		timePlayedT[client] = SQL_FetchInt(hndl, 0);
		timePlayedCT[client] = SQL_FetchInt(hndl, 1);
		timePlayedTotal[client] = SQL_FetchInt(hndl, 2);
		playerReaded[client] = true;
	}
}

public void InsertClientToTable(client) {
	char query[254];
	char steamID[32];
	char name[64];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	GetClientName(client, name, sizeof(name));
	Format(query, sizeof(query), "INSERT INTO timerank VALUES ('%s', '%s', 0, 0, 0)", steamID, name);
	SQL_TQuery(db, InsertClientToTableCallback, query, GetClientUserId(client));
}

public void InsertClientToTableCallback(Handle owner, Handle hndl, char[] error, any data) {
	int client = GetClientOfUserId(data);
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR ADDING USER ON TABLE");
		LogError("%i", error);
	} else {
		timePlayedT[client] = 0;
		timePlayedCT[client] = 0;
		timePlayedTotal[client] = 0;
		playerReaded[client] = true;
	}
}

public void OnMapStart() {
	CreateTimer(1.0, TimeCount, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimeCount (Handle timer) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			if (GetClientTeam(i) == 2) {
				timePlayedT[i]++;
			} else if (GetClientTeam(i) == 3) {
				timePlayedCT[i]++;
			} else if (GetClientTeam(i) == 1) {
				timePlayedSpec[i]++;
			}
			timePlayedTotal[i] = timePlayedT[i] + timePlayedCT[i] + timePlayedSpec[i];
		}
	}
}

public void UpdateRankCallback (Handle owner, Handle hndl, char[] error, any data) {
	if (hndl == INVALID_HANDLE) {
		LogError("%", error);
	}
}

public void OnMapEnd() {
	if (db == INVALID_HANDLE) {
		LogError("ERROR CONNECTING TO THE DB"); 
	} else {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i) && playerReaded[i]) {
				SaveTime(i);
				timePlayedTotal[i] = 0;
				timePlayedT[i] = 0;
				timePlayedCT[i] = 0;
				timePlayedSpec[i] = 0;
				playerReaded[i] = false;
			}
		}
	}
}

public void OnClientDisconnect(int client) {
	if (!IsFakeClient(client) && playerReaded[client]) {
		SaveTime(client);
	}
	timePlayedTotal[client] = 0;
	timePlayedT[client] = 0;
	timePlayedCT[client] = 0;
	timePlayedSpec[client] = 0;
	playerReaded[client] = false;
}

public void SaveTime(int client) {
	char query[254];
	char steamID[32];
	char name[64];
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	Format(query, sizeof(query), "UPDATE timerank SET name = '%s', timeT = '%i', timeCT = '%i', timeTotal = '%i' WHERE steamid = '%s'", name, timePlayedT[client], timePlayedCT[client], timePlayedTotal[client], steamID);
	SQL_TQuery(db, SaveTimeCallback, query);
}

public void SaveTimeCallback(Handle owner, Handle hndl, char[] error, any data) {
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR SAVING CLIENT TIME");
		LogError("%s", error);
	}
}

public void UpdateRank() {
	char query[254];
	char steamID[32];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID));
			if (playerReaded[i]) {
				Format(query, sizeof(query), "UPDATE timerank SET timeT = '%i', timeCT = '%i', timeTotal = '%i' WHERE steamid = '%s'", timePlayedT[i], timePlayedCT[i], timePlayedTotal[i], steamID);
				SQL_TQuery(db, UpdateRankCallback, query);		
			}
		}
	}	
}

public Action Show_rank(int client, int args) {
	UpdateRank();
	Menu menu = new Menu(MenuHandler_Rank, MenuAction_Start | MenuAction_Select | MenuAction_End);
	menu.SetTitle("Time ranking");
	menu.AddItem("Total time ranking", "Total time ranking");
	menu.AddItem("T time ranking", "T time ranking");
	menu.AddItem("CT time ranking", "CT time ranking");
	menu.Display(client, 20);
	ConverseTime(timePlayedTotal[client]);
	PrintToChat(client, "Total: Has jugado: %i horas, %i minutos, %i segundos", hours, minutes, seconds);
	ConverseTime(timePlayedT[client]);
	PrintToChat(client, "T: Has jugado %i horas, %i minutos, %i segundos", hours, minutes, seconds);
	ConverseTime(timePlayedCT[client]);
	PrintToChat(client, "CT: Has jugado %i horas, %i minutos, %i segundos", hours, minutes, seconds);
	return Plugin_Handled;
}

public void ConverseTime(int time) {
	seconds = time;
	minutes = 0;
	hours = 0;
	while (seconds >= 60) {
		minutes++;
		seconds = seconds - 60;
	}
	while (minutes >= 60) {
		hours++;
		minutes = minutes - 60;
	}
}
public int MenuHandler_Rank(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		char info[64];
		menu.GetItem(param2, info, sizeof(info));
		if(StrEqual(info, "Total time ranking")) {
			ShowRank(param1, "timeTotal");
		} else if (StrEqual (info, "T time ranking")) {
			ShowRank(param1, "timeT");
		} else if (StrEqual (info, "CT time ranking")) {
			ShowRank(param1, "timeCT");
		}
	}
}

public void ShowRank(int client, char[] typeRank) {
	char query[254];
	if (StrEqual (typeRank, "timeTotal")) {
		Format(query, sizeof(query), "SELECT name, timeTotal FROM timerank ORDER BY timeTotal DESC LIMIT 999");
	} else if (StrEqual (typeRank, "timeT")) {
		Format(query, sizeof(query), "SELECT name, timeT FROM timerank ORDER BY timeT DESC LIMIT 999");
	} else if (StrEqual (typeRank, "timeCT")) {
		Format(query, sizeof(query), "SELECT name, timeCT FROM timerank ORDER BY timeCT DESC LIMIT 999");
	}
	SQL_TQuery(db, ShowRankCallback, query, GetClientUserId(client));
}

public void ShowRankCallback(Handle owner, Handle hndl, char[] error, any data) {
	int client = GetClientOfUserId(data);
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR SHOWING THE RANK");
		LogError("%s", error);
	} else {
		int rankPosition;
		int time;
		char name[64];
		char rank[128];
		Menu menu = new Menu(MenuHandler_ShowRank, MenuAction_Start | MenuAction_Select | MenuAction_End | MenuAction_Cancel);
		menu.SetTitle("Time ranking");
		while (SQL_FetchRow(hndl)) {
			rankPosition++;
			SQL_FetchString(hndl, 0, name, sizeof(name));
			time = SQL_FetchInt(hndl, 1);
			ConverseTime(time);
			Format(rank, sizeof(rank), "%i %s - %i h %i m %i s", rankPosition, name, hours, minutes, seconds);
			menu.AddItem("Rank", rank);
		}
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		SetMenuExitBackButton(menu, true);
		menu.Display(client,MENU_TIME_FOREVER);
	}
}

public int MenuHandler_ShowRank(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Cancel) {
		Show_rank(param1, 0);
	}
}