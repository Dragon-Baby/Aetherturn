using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceGearUnit : MonoBehaviour, IDouyinSequenceUnit
{
    public Vector3 RotationAxis = Vector3.forward;
    public float RotateSpeed;
    public bool UseLocalSpace = true;

    private Quaternion baseLocalRotation;
    private Quaternion baseWorldRotation;
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
    }

    public void BeginForward() { }
    public void BeginBackward() { }

    public void Tick(float deltaTime)
    {
        Tick(deltaTime, 1f);
    }

    public void Tick(float deltaTime, float speedFactor)
    {
        EnsureInitialized();
        float deltaAngle = RotateSpeed * speedFactor * deltaTime;
        if (Mathf.Abs(deltaAngle) > 0.0001f)
        {
            transform.Rotate(normalizedAxis, deltaAngle, UseLocalSpace ? Space.Self : Space.World);
        }
    }

    public bool IsComplete() => true;

    private void EnsureInitialized()
    {
        normalizedAxis = NormalizeAxis(RotationAxis, Vector3.forward);
        if (!hasInitialized)
        {
            baseLocalRotation = transform.localRotation;
            baseWorldRotation = transform.rotation;
        }
        hasInitialized = true;
    }

    private static Vector3 NormalizeAxis(Vector3 axis, Vector3 fallbackAxis)
    {
        return axis.sqrMagnitude > 0.0001f ? axis.normalized : fallbackAxis;
    }
}

