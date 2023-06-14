# ACE Autodoc

Arma 3 script by Ir0nsight

TLDR: AI doctor automatically heals unconcious units nearby.

## Overview

This script allows to turn any AI into an automated doctor.
The doctor will look for ACE-unconcious men (player and AI) around him and then treat those injured.
Treatment takes longer for more wounds and provides a full heal in the end.

Doctors can be movable: move to patients, or static: will not move, only treat closeby (< 1m).

## Usage

- place Init.sqf in your mission folder  
   if you already have an Init.sqf, place the content of this one at the end of your file.
- place function in doctors init in zeus or editor

  - in zeus:
    `[_this] spawn irn_fnc_initAutoDoc;`

  - in editor:
    `[] spawn { sleep 5; [this] spawn irn_fnc_initAutoDoc; };`

    The functions are initialized by the Init.sqf, which is why they are not directly available,
    and have to be delayed in the editor.

- stop the script:
  - if the AI doctor dies, the script is stopped.
  - call `_this setVariable ["isAutoDoc", false, true]; ` on the doctor to stop the script manually
  - the script is paused if the doctor goes unconcious (in ACE).

## Advanced Usage

`[this, true, 0.1] spawn irn_fnc_initAutoDoc;`
runs the autodoc with "can move" and 10% healtime

- can move:
  - true: AI will walk to close by injured
  - false: AI will not walk to injured, patients have to be dragged close enough (1m)
- speed factor: number from 0 to 1
  - 1: 100% heal time required, compared to KAT kit
  - 0: 0% heal time required (instant)
