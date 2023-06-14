[] execVM "functions\fn_damage_ai.sqf";

/**
* will treat all wounds, respecting treating time per wound
* directly returns time to treat, and spawns coroutine that fully heals after time is over
*/
irn_fnc_treat_wounded = {
    params[
        "_wounded",
        ["_speedFactor", 0.5]
    ];
    _treattime = ["", _wounded] call ace_medical_treatment_fnc_getHealtime;
    _delay = _treattime * _speedFactor;
    [_delay, _wounded] spawn {
        params ["_delay", "_wounded"];
        sleep _delay;
        [_wounded] call ace_medical_treatment_fnc_fullHeallocal;
    };
    // return
    _delay
};

irn_fnc_isKnockedout = {
    params ["_unit"];
    _unit getVariable ["ACE_isUnconscious", false]
};

irn_fnc_closePatients = {
    params ["_unit", ["_range", 15]];
    _men = (getPos _unit) nearEntities ["Man", _range];
    _men append (crew vehicle _unit - [_unit]);
    _docOnFoot = (vehicle _unit isEqualto _unit);
    // todo subtract self from _men
    _knocked = _men select {
        alive _x &&
        [_x] call irn_fnc_isKnockedout &&
        // both on foot or both in same car
        ((_docOnFoot && (vehicle _x isEqualto _x)) || (vehicle _unit isEqualto vehicle _x))
    };
    diag_log ["collected injured: ", _knocked apply {
        [_x, [_x] call irn_fnc_isKnockedout]
    }];
    _knocked
};

irn_fnc_chatNearby = {
    params ["_unit", "_mssg", ["_range", 50]];
    _nearplayers = allplayers select {
        _x distance _unit < _range
    };
    _machines = _nearplayers apply {
        owner _x
    };
    [_unit, _mssg] remoteExec ["sideChat", _machines];
};

irn_fnc_formatETA = {
    params ["_seconds"];
    _rounded = ceil(_seconds / 10) * 10;
    str(_rounded)
};

/**
* initialize this unit as an automatic doctor
* requires spawn, not call
* unit will heal all nearby ACE-unconcious units
*/
irn_fnc_initAutodoc = {
    if (!canSuspend) exitwith {};
    params["_doc", ["_canmove", true], ["_speedFactor", 0.5]];
    if (!_canmove) then {
        _doc disableAI "path";
    };
    _doc setVariable ["isAutodoc", true];
    // start medic tent loop
    while {alive _doc && _doc getVariable ["isAutodoc", false]} do {
        sleep 3;
        // suspend while doctor in unconcious
        if ([_doc] call irn_fnc_isKnockedout) then {
            continue;
        };
        // todo also heal wounded, not only unconcious
        _k_o = ([_doc] call irn_fnc_closePatients) select {
            _canmove || _doc distance _x < 1
        };
        if (count _k_o != 0) then {
            _patient = selectRandom _k_o;
            
            if (_canmove) then {
                // is not in a vehicle
                _doc domove (getPosATL _patient vectorAdd [0, 0, 0]);
            };
            
            [_doc, ("Treating " + name(_patient) + " now!")] call irn_fnc_chatNearby;
            
            waitUntil {
                movetoCompleted _doc || movetoFailed _doc || !_canmove;
            };
            if (_canmove && movetoFailed _doc) then {
                [_doc, ("I can't reach " + name(_patient) + "!")] call irn_fnc_chatNearby;
                continue;
            };
            _doc doWatch _patient;
            _doc disableAI "move";
            _doc setDir (_doc getDir _patient);
            _doc setunitPos "middle";
            sleep 1;
            [_doc, selectRandom ["KNEEL_TREAT", "KNEEL_TREAT2"], "ASIS"] call BIS_fnc_ambientanim;
            _eta = [_patient] call irn_fnc_treat_wounded;
            
            _etastr =[_eta] call irn_fnc_formatETA;
            [_doc, ("Patient will be combat-ready in " + _etastr + " seconds.")] call irn_fnc_chatNearby;
            sleep _eta;
            
            // resume
            _doc setunitPos "UP";
            _doc enableAI "move";
            _doc call BIS_fnc_ambientanim__terminate;
        };
    }
};

[] spawn {
    // init stuff
    sleep 1;
    {
        [_x] call irn_fnc_damage_ai;
    } forEach [victim_01, victim_02, victim_03, victim_04, victim_05, victim_06];
    
    [doctor_01, false] spawn irn_fnc_initAutodoc;
}