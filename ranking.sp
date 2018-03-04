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

char queryBuffer[3096];

Handle db = INVALID_HANDLE;

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
		Format(queryBuffer, sizeof(queryBuffer), "CREATE TABLE IF NOT EXIST 'TIME RANK' ('steamid' VARCHAR(32) PRIMARY KEY NOT NULL, 'name' varchar(64) NOT NULL, 'time' INT(16))");
	}
}
public Action Show_rank(int client, int args) {
	
}