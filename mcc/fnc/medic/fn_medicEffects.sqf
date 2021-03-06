//=================================================================MCC_fnc_medicEffects=========================================================================================
//Handle clients medic effects
//=============================================================================================================================================================================
private ["_bleeding","_remaineBlood","_maxBleeding","_ypos","_ratio","_blink","_unit"];
_unit = param [0,objNull,[objNull]];

//Zeus open
if (!(missionNamespace getvariable ["MCC_medicSystemEnabled",false]) || isNull _unit || !(local _unit)) exitWith {};

//Bleeding
if (missionNamespace getvariable ["MCC_medicBleedingEnabled",false]) then {
	_bleeding = _unit getVariable ["MCC_medicBleeding",0];
	_maxBleeding = missionNamespace getvariable ["MCC_medicBleedingTime",200];
	_remaineBlood = _unit getvariable ["MCC_medicRemainBlood",_maxBleeding];

	if (isnil "MCC_medicBleedingPPEffectColor" && isPlayer _unit) then {
		MCC_medicBleedingPPEffectColor = ppEffectCreate ["ColorCorrections", 1522];
		MCC_medicBleedingPPEffectColor ppEffectForceInNVG True;

		MCC_medicBleedingPPEffectBlur = ppEffectCreate ["DynamicBlur", 440];
		MCC_medicBleedingPPEffectBlur ppEffectForceInNVG True;
	};

	//Loose blood
	if (_bleeding > 0.1) then
	{
		if ((_unit getVariable ["MCC_clientEffectsTime",time-5]) < time  && isPlayer _unit) then
		{
			[_bleeding * 100] spawn BIS_fnc_bloodEffect;
			[[[netid _unit,_unit], format ["WoundedGuyA_0%1",(floor (random 8))+1]], "MCC_fnc_globalSay3D", true, false] spawn BIS_fnc_MP;
			_unit setVariable ["MCC_clientEffectsTime",time+5+random 10];
		};

		_remaineBlood = _remaineBlood - _bleeding;
		_unit setVariable ["MCC_medicRemainBlood",_remaineBlood, true];
		if (_remaineBlood<=0) then {[_unit,_unit] spawn MCC_fnc_unconscious;};
	};

	//Regain Blood
	if (_bleeding == 0 && _remaineBlood < _maxBleeding) then
	{
		_remaineBlood = _remaineBlood + (0.1*(_unit getvariable ["MCC_bleedingRegMulti",1]));
		_unit setVariable ["MCC_medicRemainBlood",_remaineBlood, true];
	};

	//Blood loss effects
	if (isPlayer _unit) then {
		_ratio = (_remaineBlood/_maxBleeding);
		if (_ratio < 0.9 && isNull(findDisplay 312)) then
		{
			MCC_medicBleedingPPEffectColor ppEffectEnable TRUE;
			MCC_medicBleedingPPEffectBlur ppEffectEnable TRUE;

			if (random 1 < 0.05 && _ratio <0.5) then
			{
				MCC_medicBleedingPPEffectColor ppEffectAdjust [0.8,0.8,0, [0,0,0,0], [0,0,0,_ratio], [0.8,0.8,0.8,1]];
				MCC_medicBleedingPPEffectColor ppEffectCommit 0.05;
				if (getFatigue _unit < _ratio) then {_unit setFatigue _ratio};
				sleep 0.05;
			};

			MCC_medicBleedingPPEffectColor ppEffectAdjust [1, 1, 0, [1, 1, 1, 0], [1, 1, 1, _ratio], [0.75, 0.25, 0, 1.0]];
			MCC_medicBleedingPPEffectColor ppEffectCommit 1;

			MCC_medicBleedingPPEffectBlur ppEffectAdjust [(1 - _ratio) min 0.3];
			MCC_medicBleedingPPEffectBlur ppEffectCommit 1;
		}
		else
		{
			MCC_medicBleedingPPEffectColor ppEffectEnable false;
			MCC_medicBleedingPPEffectBlur ppEffectEnable false;
		};
	};
};

//Self heal for AI
if !(isPlayer _unit) then {

	if (_bleeding > 0.1 || damage _unit > 0.3 && (alive _unit) && !(_unit getVariable ["MCC_medicUnconscious",false]) && canMove _unit && (lifeState _unit != "INCAPACITATED")) then {

		if ((_remaineBlood/_maxBleeding < 0.5 || (getDammage _unit)>0.3)) then
		{
			sleep random 3;
			if ("FirstAidKit" in (items _unit)) then
			{
				_unit removeItem "FirstAidKit";
				_unit action ["HealSoldierSelf", _unit];
				_unit setVariable ["MCC_medicBleeding",0,true];
			}
			else
			{
				if ("MCC_bandage" in (items _unit)) then
				{
					_unit removeItem "MCC_bandage";
					_unit action ["HealSoldierSelf", _unit];
					_unit setVariable ["MCC_medicBleeding",0,true];
					_unit setDamage 0.2;
				};
			};
		};
	};
};

//refresh stats
_bleeding = _unit getVariable ["MCC_medicBleeding",0];

//AI heal for players and AI
if (isplayer _unit && (_bleeding > 0.1 || (_unit getVariable ["MCC_medicUnconscious",false])) ||
    !isPlayer _unit && (_bleeding > 0.1 || (_unit getVariable ["MCC_medicUnconscious",false]) || damage _unit > 0.3)
    ) then {
	private ["_medics","_savior"];

	_medics = (units _unit) select {("FirstAidKit" in (items _x) || "Medikit" in (items _x) || "MCC_epipen" in (items _x)) && (alive _x) && !(_x getVariable ["MCC_medicUnconscious",false]) && canMove _x && (lifeState _x != "INCAPACITATED") && (vehicle _x == _x)};

	if (count _medics > 0) then {
		_savior = selectRandom _medics;

		[_savior,_unit] spawn {
			params ["_savior","_unit"];

			_savior doMove getpos _unit;
			_t = time + 15;

			waituntil { sleep .5; (_savior distance _unit < 5) or !(alive _unit) or !(alive _savior) or (_savior getVariable ["MCC_medicUnconscious",false]) or !(canMove _savior) or (lifeState _savior == "INCAPACITATED")  or (vehicle _savior != _savior) or time > _t};
		};

		if (_savior distance _unit < 5) then {
			_savior action ["heal", _unit];
			_unit setVariable ["MCC_medicUnconscious",false,true];
			_unit setVariable ["MCC_medicBleeding",0,true];
			_unit setDamage 0;
		};
	};
};

