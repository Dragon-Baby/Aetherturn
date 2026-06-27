using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public interface IDouyinSequenceUnit
{
    void ResetToBase();
    void BeginForward();
    void BeginBackward();
    void Tick(float deltaTime);
    bool IsComplete();
}

public abstract class DouyinSequenceGroupBase : MonoBehaviour, IDouyinSequenceUnit
{
    public GameObject[] UnitObjects;
    public string UnitScriptName;

    protected readonly List<IDouyinSequenceUnit> units = new List<IDouyinSequenceUnit>();
    protected bool isComplete = true;

    protected abstract Type UnitType { get; }
    protected abstract string DefaultUnitScriptName { get; }

    protected virtual void Awake()
    {
        if (string.IsNullOrEmpty(UnitScriptName))
        {
            UnitScriptName = DefaultUnitScriptName;
        }
        CollectUnits();
    }

    public virtual void CollectUnits()
    {
        units.Clear();

        if (UnitObjects != null)
        {
            for (int i = 0; i < UnitObjects.Length; i++)
            {
                CollectFromObject(UnitObjects[i]);
            }
        }

        isComplete = units.Count == 0;
    }

    public virtual void ResetToBase()
    {
        for (int i = 0; i < units.Count; i++)
        {
            units[i].ResetToBase();
        }
        isComplete = units.Count == 0;
    }

    public virtual void BeginForward()
    {
        EnsureCollected();
        for (int i = 0; i < units.Count; i++)
        {
            units[i].BeginForward();
        }
        isComplete = units.Count == 0;
    }

    public virtual void BeginBackward()
    {
        EnsureCollected();
        for (int i = 0; i < units.Count; i++)
        {
            units[i].BeginBackward();
        }
        isComplete = units.Count == 0;
    }

    public virtual void Tick(float deltaTime)
    {
        if (isComplete)
        {
            return;
        }

        bool allCompleted = true;
        for (int i = 0; i < units.Count; i++)
        {
            units[i].Tick(deltaTime);
            if (!units[i].IsComplete())
            {
                allCompleted = false;
            }
        }
        isComplete = allCompleted;
    }

    public bool IsComplete()
    {
        return isComplete;
    }

    protected void EnsureCollected()
    {
        if (units.Count == 0)
        {
            CollectUnits();
        }
    }

    protected void CollectFromObject(GameObject source)
    {
        if (source == null)
        {
            return;
        }

        Component component = null;
        if (!string.IsNullOrEmpty(UnitScriptName))
        {
            MonoBehaviour[] behaviours = source.GetComponents<MonoBehaviour>();
            for (int i = 0; i < behaviours.Length; i++)
            {
                if (behaviours[i] != null && behaviours[i].GetType().Name == UnitScriptName)
                {
                    component = behaviours[i];
                    break;
                }
            }
        }

        if (component == null && UnitType != null)
        {
            component = source.GetComponent(UnitType);
        }

        if (component is IDouyinSequenceUnit unit)
        {
            units.Add(unit);
        }
    }
}

