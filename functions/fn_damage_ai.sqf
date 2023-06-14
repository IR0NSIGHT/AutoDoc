irn_fnc_damage_ai = {
    params ["_ai"];
    
    [_ai, [[3, "Body", 1]], "bullet"] call ace_medical_damage_fnc_woundsHandlerBase
}