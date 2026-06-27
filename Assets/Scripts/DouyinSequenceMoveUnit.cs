using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceMoveUnit : MonoBehaviour, IDouyinSequenceUnit
{
    public Vector3 MoveAxis = Vector3.right;
    public bool UseLocalSpace = true;
    public float MoveDistance = 1f;
    public float MoveSpeed = 0.5f;

    private Vector3 baseLocalPosition;
    private Vector3 baseWorldPosition;
    private float currentDistance;
    private float targetDistance;
    private int moveDirection = 1;
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
        currentDistance = 0f;
        targetDistance = 0f;
        moveDirection = 1;
        isPlaying = false;
        isComplete = true;
        ApplyCurrentDistance();
    }

    public void BeginForward()
    {
        EnsureInitialized();
        targetDistance = MoveDistance;
        moveDirection = 1;
        isComplete = false;

        if (MoveDistance <= 0f || MoveSpeed <= 0f)
        {
            currentDistance = MoveDistance;
            ApplyCurrentDistance();
            isPlaying = false;
            isComplete = true;
            return;
        }

        isPlaying = true;
    }

    public void BeginBackward()
    {
        EnsureInitialized();
        targetDistance = 0f;
        moveDirection = -1;
        isComplete = false;

        if (MoveDistance <= 0f || MoveSpeed <= 0f)
        {
            currentDistance = 0f;
            ApplyCurrentDistance();
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

        currentDistance += moveDirection * MoveSpeed * deltaTime;
        if (moveDirection > 0 && currentDistance >= targetDistance)
        {
            currentDistance = targetDistance;
            isPlaying = false;
            isComplete = true;
        }
        else if (moveDirection < 0 && currentDistance <= targetDistance)
        {
            currentDistance = targetDistance;
            isPlaying = false;
            isComplete = true;
        }

        ApplyCurrentDistance();
    }

    public bool IsComplete() => isComplete;

    public float GetProgress01()
    {
        return MoveDistance <= 0f ? 1f : Mathf.Clamp01(currentDistance / MoveDistance);
    }

    private void EnsureInitialized()
    {
        MoveDistance = Mathf.Max(0f, MoveDistance);
        MoveSpeed = Mathf.Max(0f, MoveSpeed);
        normalizedAxis = NormalizeAxis(MoveAxis, Vector3.right);
        if (!hasInitialized)
        {
            baseLocalPosition = transform.localPosition;
            baseWorldPosition = transform.position;
        }
        hasInitialized = true;
    }

    private void ApplyCurrentDistance()
    {
        Vector3 offset = normalizedAxis * currentDistance;
        if (UseLocalSpace)
        {
            transform.localPosition = baseLocalPosition + offset;
        }
        else
        {
            transform.position = baseWorldPosition + offset;
        }
    }

    private static Vector3 NormalizeAxis(Vector3 axis, Vector3 fallbackAxis)
    {
        return axis.sqrMagnitude > 0.0001f ? axis.normalized : fallbackAxis;
    }
}

