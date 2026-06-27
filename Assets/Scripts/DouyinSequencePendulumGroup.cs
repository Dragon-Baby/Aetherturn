using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequencePendulumGroup : DouyinSequenceGroupBase
{
    public int SwingCount = 17;

    protected override Type UnitType => typeof(DouyinSequencePendulumUnit);
    protected override string DefaultUnitScriptName => "DouyinSequencePendulumUnit";

    protected override void Awake()
    {
        SwingCount = Mathf.Max(1, SwingCount);
        base.Awake();
    }

    public override void BeginForward()
    {
        EnsureCollected();
        for (int i = 0; i < units.Count; i++)
        {
            if (units[i] is DouyinSequencePendulumUnit pendulum)
            {
                pendulum.BeginForward(SwingCount);
            }
            else
            {
                units[i].BeginForward();
            }
        }
        isComplete = units.Count == 0;
    }

    public override void BeginBackward()
    {
        BeginForward();
    }
}

