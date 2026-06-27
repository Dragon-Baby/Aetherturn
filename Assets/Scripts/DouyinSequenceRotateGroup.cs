using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceRotateGroup : DouyinSequenceGroupBase
{
    protected override Type UnitType => typeof(DouyinSequenceRotateUnit);
    protected override string DefaultUnitScriptName => "DouyinSequenceRotateUnit";
}

