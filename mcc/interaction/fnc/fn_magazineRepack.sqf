/*===================================================== MCC_fnc_magazineRepack ======================================================================================================================

	Repack all the handguns and primary weapon magazines in the player's inventory

*/

private ["_fullCount","_mgazinesAmmo","_mgazinesClasses","_index","_totalAmmo"];
_mgazinesAmmo = [];
_mgazinesClasses = [];

0 = ["Repacking Magazines",(count magazinesAmmo player)*2,player] spawn MCC_fnc_interactProgress;

{
	_x params ["_magClass","_magCount","_loaded","_magType"];

	if (_magType in [-1,1,2]) then {

		//Sort only magazines in inventory
		if !(_loaded) then {

			if !(_magClass in _mgazinesClasses) then {
				_mgazinesClasses pushBack _magClass;
				_mgazinesAmmo set [(_mgazinesClasses find _magClass),0];
			};

			_index = _mgazinesClasses find _magClass;
			_mgazinesAmmo set [_index,(_mgazinesAmmo select _index) + _magCount];

			player removeMagazine _magClass;
		};
	};
} forEach (magazinesAmmoFull player);

//Start the progress bar
waitUntil {missionNamespace getVariable ["MCC_fnc_interactProgress_running",false]};

//Pack magazines
{
	if !(missionNamespace getVariable ["MCC_fnc_interactProgress_running",false]) exitWith {};
	_x params ["_magClass"];
	_totalAmmo = _mgazinesAmmo select (_mgazinesClasses find _magClass);
	_fullCount = getNumber (configFile >> "CfgMagazines" >> _magClass >> "count");

	for "_i" from 1 to (_totalAmmo/_fullCount) step 1 do
	{
		player addMagazine _magClass;
	};

	if (_totalAmmo mod _fullCount > 0) then {
		player addMagazine [_magClass, _totalAmmo mod _fullCount];
	};

	sleep 3;
} forEach _mgazinesClasses;