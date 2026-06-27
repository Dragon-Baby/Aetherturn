using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceMoveGroup : DouyinSequenceGroupBase
{
    protected override Type UnitType => typeof(DouyinSequenceMoveUnit);
    protected override string DefaultUnitScriptName => "DouyinSequenceMoveUnit";
}

