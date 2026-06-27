using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceRotateUnit : MonoBehaviour, IDouyinSequenceUnit
{
    public Vector3 RotationAxis = Vector3.up;
    public bool UseLocalSpace = true;
    public float RotateAngle = 90f;
    public float RotateSpeed = 45f;

    private float currentAngle;
    private float targetAngle;
    private int rotateDirection = 1;
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
        ApplyAbsoluteAngle(0f);
        targetAngle = 0f;
        rotateDirection = 1;
        isPlaying = false;
        isComplete = true;
    }

    public void BeginForward()
    {
        EnsureInitialized();
        targetAngle = RotateAngle;
        rotateDirection = 1;
        isComplete = false;

        if (RotateAngle <= 0f || RotateSpeed <= 0f)
        {
            ApplyAbsoluteAngle(RotateAngle);
            isPlaying = false;
            isComplete = true;
            return;
        }

        isPlaying = true;
    }

    public void BeginBackward()
    {
        EnsureInitialized();
        targetAngle = 0f;
        rotateDirection = -1;
        isComplete = false;

        if (RotateAngle <= 0f || RotateSpeed <= 0f)
        {
            ApplyAbsoluteAngle(0f);
            isPlaying = false;
            isComplete = true;
            return;
        }

        isPlaying = true;
    }

    public void Tick(float deltaTime)
    {
        EnsureInitialized();
        if (!isPlaying || isComplete)
        {
            return;
        }

        float nextAngle = currentAngle + rotateDirection * RotateSpeed * deltaTime;
        if (rotateDirection > 0 && nextAngle >= targetAngle)
        {
            ApplyAbsoluteAngle(targetAngle);
            isPlaying = false;
            isComplete = true;
            return;
        }

        if (rotateDirection < 0 && nextAngle <= targetAngle)
        {
            ApplyAbsoluteAngle(targetAngle);
            isPlaying = false;
            isComplete = true;
            return;
        }

        ApplyAbsoluteAngle(nextAngle);
    }

    public bool IsComplete() => isComplete;

    public float GetProgress01()
    {
        return RotateAngle <= 0f ? 1f : Mathf.Clamp01(currentAngle / RotateAngle);
    }

    private void EnsureInitialized()
    {
        RotateAngle = Mathf.Max(0f, RotateAngle);
        RotateSpeed = Mathf.Max(0f, RotateSpeed);
        normalizedAxis = NormalizeAxis(RotationAxis, Vector3.up);
        hasInitialized = true;
    }

    private void ApplyAbsoluteAngle(float nextAngle)
    {
        float deltaAngle = nextAngle - currentAngle;
        if (Mathf.Abs(deltaAngle) > 0.0001f)
        {
            transform.Rotate(normalizedAxis, deltaAngle, UseLocalSpace ? Space.Self : Space.World);
        }
        currentAngle = nextAngle;
    }

    private static Vector3 NormalizeAxis(Vector3 axis, Vector3 fallbackAxis)
    {
        return axis.sqrMagnitude > 0.0001f ? axis.normalized : fallbackAxis;
    }
}

