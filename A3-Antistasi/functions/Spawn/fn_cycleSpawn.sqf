//Defines for group types to allow runtime groups joining and so on
#define GARRISON    10
#define OVER        11
#define STATIC      12
#define MORTAR      13
#define PATROL      14
#define OTHER       15

#define IS_CREW     false
#define IS_CARGO    true

params ["_marker", "_patrolMarker", ["_allVehicles", []], ["_allGroups", []]];

/*  Handles the unit spawn progress of any marker

    Execution on: HC or Server

    Scope: Internal

    Params:
        _marker: STRING : Name of the marker that should be spawned in
        _patrolMarker: STRING : Name of the patrol marker around the main marker
        _allVehicles: ARRAY of OBJECTS: (Optional) List of already spawned vehicles on the marker
        _allGroups: ARRAY of GROUPS: (Optional) List of already spawned groups on the marker

    Returns:
        Nothing
*/

private _fileName = "cycleSpawn";

private _side = sidesX getVariable [_marker, sideUnknown];
if(_side == sideUnknown) exitWith
{
    [1, format ["Could not retrieve side for %1", _marker], _fileName] call A3A_fnc_log;
};
[2, format ["Starting cyclic spawn of %1, side is %2", _marker, _side], _fileName] call A3A_fnc_log;

private _garrison = [_marker] call A3A_fnc_getGarrison;
[_garrison, format ["%1_garrison",_marker]] call A3A_fnc_logArray;
private _over = [_marker] call A3A_fnc_getOver;
private _locked = garrison getVariable (format ["%1_locked", _marker]);

//Calculate patrol marker size
private _garCount = [_garrison + _over, true] call A3A_fnc_countGarrison;
[_marker, _patrolMarker, _garCount] call A3A_fnc_adaptMarkerSizeToUnitCount;

//Spawn in the garrison units
{
    _x params ["_vehicleType", "_crewArray", "_cargoArray"];

    //Check if this vehicle (if there) is locked
    if (!(_locked select _forEachIndex)) then
    {
        private _vehicleGroup = grpNull;
        private _vehicle = objNull;

        if (_vehicleType != "") then
        {
            //Array got a vehicle, spawn it in
            _vehicleGroup = createGroup _side;
            _vehicle = [_marker, _vehicleType, _forEachIndex, _vehicleGroup, false] call A3A_fnc_cycleSpawnVehicle;
            _allVehicles pushBack [_vehicle, [GARRISON, _forEachIndex]];
            sleep 0.25;
        };

        _vehicleGroup = [_marker, _side, _crewArray, _forEachIndex, _vehicleGroup, _vehicle, false] call A3A_fnc_cycleSpawnVehicleCrew;
        if !(isNull _vehicleGroup) then
        {
            _allGroups pushBack [_vehicleGroup, [GARRISON, IS_CREW, _forEachIndex]];
        };
    };

    private _groupSoldier = [_side, _marker, _cargoArray, _forEachIndex, false] call A3A_fnc_cycleSpawnSoldierGroup;
    if !(isNull _groupSoldier) then
    {
        _allGroups pushBack [_groupSoldier, [GARRISON, IS_CARGO, _forEachIndex]];
    };
} forEach _garrison;

//Spawn in the over units
{
    _x params ["_vehicleType", "_crewArray", "_cargoArray"];

    private _vehicleGroup = grpNull;
    private _vehicle = objNull;

    if (_vehicleType != "") then
    {
        //Array got a vehicle, spawn it in
        _vehicleGroup = createGroup _side;
        _vehicle = [_marker, _vehicleType, _forEachIndex, _vehicleGroup, true] call A3A_fnc_cycleSpawnVehicle;
        _allVehicles pushBack [_vehicle, [OVER, _forEachIndex]];
        sleep 0.25;
    };

    _vehicleGroup = [_marker, _side, _crewArray, _forEachIndex, _vehicleGroup, _vehicle, true] call A3A_fnc_cycleSpawnVehicleCrew;
    if !(isNull _vehicleGroup) then
    {
        _allGroups pushBack [_vehicleGroup, [OVER, IS_CREW, _forEachIndex]];
    };

    private _groupSoldier = [_side, _marker, _cargoArray, _forEachIndex, true] call A3A_fnc_cycleSpawnSoldierGroup;
    if !(isNull _groupSoldier) then
    {
        _allGroups pushBack [_groupSoldier, [OVER, IS_CARGO, _forEachIndex]];
    };
} forEach _over;

//Spawn in statics of the marker
private _statics = garrison getVariable [format ["%1_statics", _marker], []];
private _staticGroup = grpNull;
{
    if(isNull _staticGroup) then
    {
        _staticGroup = createGroup _side;
        _allGroups pushBack [_staticGroup, [STATIC, IS_CREW, 0]];
    };
    private _static = [_marker, _staticGroup, _x select 0, _x select 1, _forEachIndex] call A3A_fnc_cycleSpawnStatic;
    _allVehicles pushBack [_static, [STATIC, -1]];
} forEach _statics;

//Spawn in mortars of the marker
private _mortars = garrison getVariable [format ["%1_mortars", _marker], []];
private _mortarGroup = grpNull;
{
    if(isNull _mortarGroup) then
    {
        _mortarGroup = createGroup _side;
        _allGroups pushBack [_mortarGroup, [MORTAR , IS_CREW, 0]];
    };
    private _mortar = [_marker, _mortarGroup, _x select 0, _x select 1, _forEachIndex] call A3A_fnc_cycleSpawnStatic;
    _allVehicles pushBack [_mortar, [STATIC, -1]];
} forEach _mortars;

if (_side == teamPlayer) then
{
    //Get units to man statics
};

//Spawning in patrol units around the marker
private _patrols = [_marker] call A3A_fnc_getPatrols;
{
    private _group = [_side, _marker, _x, _forEachIndex, _patrolMarker] call A3A_fnc_cycleSpawnPatrol;
    if !(isNull _group) then
    {
        _allGroups pushBack [_group, [PATROL, IS_CARGO, _forEachIndex]];
    };
} forEach _patrols;

//Saving all groups and vehicles to the spawnedArrays
spawner setVariable [format ["%1_groups", _marker], _allGroups, true];
spawner setVariable [format ["%1_vehicles", _marker], _allVehicles, true];

//Handling the alert state and the despawn
[_marker] spawn A3A_fnc_markerAlert;
[_marker, _patrolMarker] spawn A3A_fnc_markerDespawner;
