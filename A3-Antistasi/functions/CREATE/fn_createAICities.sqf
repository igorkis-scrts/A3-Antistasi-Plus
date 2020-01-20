//NOTA: TAMBIÉN LO USO PARA FIA
if (!isServer and hasInterface) exitWith{};

private ["_markerX","_groups","_soldiers","_positionX","_num","_dataX","_prestigeOPFOR","_prestigeBLUFOR","_esAAF","_params","_frontierX","_array","_countX","_groupX","_dog","_grp","_sideX"];
_markerX = _this select 0;

_groups = [];
_soldiers = [];

_positionX = getMarkerPos (_markerX);

_num = [_markerX] call A3A_fnc_sizeMarker;
_sideX = sidesX getVariable [_markerX,sideUnknown];
if ({if ((getMarkerPos _x inArea _markerX) and (sidesX getVariable [_x,sideUnknown] != _sideX)) exitWith {1}} count markersX > 0) exitWith {};
_num = round (_num / 100);

diag_log format ["[Antistasi] Spawning City Patrol in %1 (createAICities.sqf)", _markerX];

_dataX = server getVariable _markerX;
//_prestigeOPFOR = _dataX select 3;
//_prestigeBLUFOR = _dataX select 4;
_prestigeOPFOR = _dataX select 2;
_prestigeBLUFOR = _dataX select 3;
_esAAF = true;
if (_markerX in destroyedSites) then
	{
	_esAAF = false;
	_params = [_positionX,Invaders,CSATSpecOp];
	}
else
	{
	if (_sideX == Occupants) then
		{
		_num = round (_num * (_prestigeOPFOR + _prestigeBLUFOR)/100);
		_frontierX = [_markerX] call A3A_fnc_isFrontline;
		if (_frontierX) then
			{
			_num = _num * 2;
			_params = [_positionX, Occupants, groupsNATOSentry];
			}
		else
			{
			_params = [_positionX, Occupants, groupsNATOGen];
			};
		}
	else
		{
		_esAAF = false;
		_num = round (_num * (_prestigeBLUFOR/100));
		_array = [];
		{if (random 20 < skillFIA) then {_array pushBack (_x select 0)} else {_array pushBack (_x select 1)}} forEach groupsSDKSentry;
		_params = [_positionX, teamPlayer, _array];
		};
	};
if (_num < 1) then {_num = 1};

_countX = 0;
while {(spawner getVariable _markerX != 2) and (_countX < _num)} do
	{
	_groupX = _params call A3A_fnc_spawnGroup;
	sleep 1;
	if (_esAAF) then
		{
		if (random 10 < 2.5) then
			{
			_dog = _groupX createUnit ["Fin_random_F",_positionX,[],0,"FORM"];
			[_dog] spawn A3A_fnc_guardDog;
			};
		};
	_nul = [leader _groupX, _markerX, "SAFE", "RANDOM", "SPAWNED","NOVEH2", "NOFOLLOW"] execVM "scripts\UPSMON.sqf";//TODO need delete UPSMON link
	_groups pushBack _groupX;
	_countX = _countX + 1;
	};

if ((_esAAF) or (_markerX in destroyedSites)) then
	{
	{_grp = _x;
	{[_x,""] call A3A_fnc_NATOinit; _soldiers pushBack _x} forEach units _grp;} forEach _groups;
	}
else
	{
	{_grp = _x;
	{[_x] spawn A3A_fnc_FIAinitBases; _soldiers pushBack _x} forEach units _grp;} forEach _groups;
	};


//Units fully spawned in, awaiting despawn
waitUntil
{
    sleep 10;
    private _spawners = allUnits select {_x getVariable ["spawner", false]};
    private _blufor = [];
    private _redfor = [];
    private _greenfor = [];
    {
        switch (side (group _x)) do
        {
            case (Occupants):
            {
                _blufor pushBack _x;
            };
            case (Invaders):
            {
                _redfor pushBack _x;
            };
            case (teamPlayer):
            {
                _greenfor pushBack _x;
            };
        };
    } forEach _spawners;
    private _needsSpawn = [_marker, _blufor, _redfor, _greenfor] call A3A_fnc_needsSpawn;
    private _markerState = spawner getVariable _marker;
    if(_markerState != _needsSpawn) then
    {
        if((_markerState == 2) && (_needsSpawn == 1)) then
        {
            //Enemy to far away, disable AI for now
            {
                {
                    _x enableSimulationGlobal false;
                } forEach (units _x);
            } forEach _groups;
        };
        if((_markerState == 1) && (_needsSpawn == 2)) then
        {
            //Enemy is closing in activate AI for now
            {
                {
                    _x enableSimulationGlobal true;
                } forEach (units _x);
            } forEach _groups;
        };
        spawner setVariable [_marker, _needsSpawn, true];
    };
    (_needsSpawn == 0)  //Despawns if _needsSpawn is equal 0
};

/*
waitUntil {sleep 1;((spawner getVariable _markerX == 2)) or ({[_x,_markerX] call A3A_fnc_canConquer} count _soldiers == 0)};

if (({[_x,_markerX] call A3A_fnc_canConquer} count _soldiers == 0) and (_esAAF)) then
	{
	[[_positionX,Occupants,"",false],"A3A_fnc_patrolCA"] remoteExec ["A3A_fnc_scheduler",2];
	};
*/

{if (alive _x) then {deleteVehicle _x}} forEach _soldiers;
{deleteGroup _x} forEach _groups;
