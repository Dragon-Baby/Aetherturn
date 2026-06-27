using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequencePendulumUnit : MonoBehaviour, IDouyinSequenceUnit
{
    private const float TwoPi = Mathf.PI * 2f;

    public Vector3 RotationAxis = Vector3.forward;
    public bool UseLocalSpace = true;
    public float MaxAngle = 20f;
    public float Speed = 2f;
    public float StartPhase;
    public float StopAngle;

    private Quaternion baseLocalRotation;
    private Quaternion baseWorldRotation;
    private float currentPhase;
    private float lastAppliedAngle;
    private int requiredSwingCount = 1;
    private int completedCycles;
    private bool isPlaying;
    private bool isComplete = true;
    private Vector3 normalizedAxis;
    private bool hasInitialized;

    private void Awake()
    {
        bool alreadyInitialized = hasInitialized;
        EnsureInitialized();
        if (!alreadyInitialized)
        {
            ResetToBase();
        }
    }

    public void ResetToBase()
    {
        EnsureInitialized();
        if (UseLocalSpace)
        {
            transform.localRotation = baseLocalRotation;
        }
        else
        {
            transform.rotation = baseWorldRotation;
        }

        currentPhase = StartPhase;
        lastAppliedAngle = 0f;
        completedCycles = 0;
        requiredSwingCount = 1;
        isPlaying = false;
        isComplete = true;
        ApplyAbsoluteAngle(Mathf.Sin(currentPhase) * MaxAngle);
    }

    public void BeginForward()
    {
        BeginForward(requiredSwingCount);
    }

    public void BeginForward(int swingCount)
    {
        EnsureInitialized();
        ResetToBase();
        requiredSwingCount = Mathf.Max(0, swingCount);

        if (requiredSwingCount <= 0 || MaxAngle <= 0f || Speed <= 0f)
        {
            ApplyAbsoluteAngle(StopAngle);
            isPlaying = false;
            isComplete = true;
            return;
        }

        isPlaying = true;
        isComplete = false;
    }

    public void BeginBackward()
    {
        BeginForward(requiredSwingCount);
    }

    public void Tick(float deltaTime)
    {
        EnsureInitialized();
        if (!isPlaying || isComplete)
        {
            return;
        }

        float previousPhase = currentPhase;
        currentPhase += Speed * deltaTime;

        int previousCycles = Mathf.FloorToInt((previousPhase - StartPhase) / TwoPi);
        int currentCyclesCount = Mathf.FloorToInt((currentPhase - StartPhase) / TwoPi);
        if (currentCyclesCount > previousCycles)
        {
            completedCycles = currentCyclesCount;
        }

        ApplyAbsoluteAngle(Mathf.Sin(currentPhase) * MaxAngle);

        if (completedCycles >= requiredSwingCount)
        {
            ApplyAbsoluteAngle(StopAngle);
            isPlaying = false;
            isComplete = true;
        }
    }

    public bool IsComplete() => isComplete;

    public float GetProgress01()
    {
        return requiredSwingCount <= 0 ? 1f : Mathf.Clamp01((float)completedCycles / requiredSwingCount);
    }

    private void EnsureInitialized()
    {
        MaxAngle = Mathf.Max(0f, MaxAngle);
        Speed = Mathf.Max(0f, Speed);
        normalizedAxis = NormalizeAxis(RotationAxis, Vector3.forward);
        if (!hasInitialized)
        {
            baseLocalRotation = transform.localRotation;
            baseWorldRotation = transform.rotation;
        }
        hasInitialized = true;
    }

    private void ApplyAbsoluteAngle(float targetAngle)
    {
        float deltaAngle = targetAngle - lastAppliedAngle;
        if (Mathf.Abs(deltaAngle) > 0.0001f)
        {
            transform.Rotate(normalizedAxis, deltaAngle, UseLocalSpace ? Space.Self : Space.World);
        }
        lastAppliedAngle = targetAngle;
    }

    private static Vector3 NormalizeAxis(Vector3 axis, Vector3 fallbackAxis)
    {
        return axis.sqrMagnitude > 0.0001f ? axis.normalized : fallbackAxis;
    }
}

