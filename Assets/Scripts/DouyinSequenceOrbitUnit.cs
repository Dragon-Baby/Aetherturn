using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceOrbitUnit : MonoBehaviour, IDouyinSequenceUnit
{
    public Transform OrbitCenter;
    public Vector3 OrbitAxis = Vector3.up;
    public float OrbitLoops = 2f;
    public float AccelDuration = 1f;
    public float CruiseDuration = 1f;
    public float DecelDuration = 1f;
    public bool KeepOriginalRotation;

    private Vector3 baseWorldPosition;
    private Quaternion baseWorldRotation;
    private Vector3 cachedCenterPosition;
    private float currentAngle;
    private float elapsedTime;
    private float totalAngle;
    private float totalDuration;
    private float maxAngularSpeed;
    private float accelRate;
    private float decelRate;
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
            CaptureBaseState();
            ResetToBase();
        }
    }

    public void ResetToBase()
    {
        EnsureInitialized();
        transform.position = baseWorldPosition;
        transform.rotation = baseWorldRotation;
        cachedCenterPosition = ResolveCenterPosition();
        elapsedTime = 0f;
        currentAngle = 0f;
        isPlaying = false;
        isComplete = true;
    }

    public void BeginForward()
    {
        EnsureInitialized();
        ResetToBase();
        isComplete = false;

        if (totalDuration <= 0.0001f || totalAngle <= 0.0001f)
        {
            isPlaying = false;
            isComplete = true;
            return;
        }

        isPlaying = true;
    }

    public void BeginBackward()
    {
        BeginForward();
    }

    public void Tick(float deltaTime)
    {
        EnsureInitialized();
        if (!isPlaying || isComplete)
        {
            return;
        }

        elapsedTime += deltaTime;
        if (elapsedTime >= totalDuration)
        {
            transform.position = baseWorldPosition;
            transform.rotation = baseWorldRotation;
            elapsedTime = totalDuration;
            currentAngle = 0f;
            isPlaying = false;
            isComplete = true;
            return;
        }

        ApplyAngle(GetAngleAtTime(elapsedTime));
    }

    public bool IsComplete() => isComplete;

    public float GetProgress01()
    {
        if (totalDuration <= 0.0001f || isComplete)
        {
            return 1f;
        }
        return Mathf.Clamp01(elapsedTime / totalDuration);
    }

    public float GetTotalDuration() => totalDuration;

    public float GetSpeedFactor()
    {
        if (maxAngularSpeed <= 0.0001f || totalDuration <= 0.0001f)
        {
            return 0f;
        }

        float t = elapsedTime;
        if (t <= 0f)
        {
            return 0f;
        }

        if (AccelDuration > 0f)
        {
            if (t < AccelDuration)
            {
                return Mathf.Clamp01(t / AccelDuration);
            }
            t -= AccelDuration;
        }

        if (CruiseDuration > 0f)
        {
            if (t < CruiseDuration)
            {
                return 1f;
            }
            t -= CruiseDuration;
        }

        if (DecelDuration > 0f && t < DecelDuration)
        {
            return Mathf.Clamp01(1f - t / DecelDuration);
        }

        return 0f;
    }

    private void EnsureInitialized()
    {
        normalizedAxis = NormalizeAxis(OrbitAxis, Vector3.up);
        RebuildMotionProfile();
        if (!hasInitialized)
        {
            baseWorldPosition = transform.position;
            baseWorldRotation = transform.rotation;
        }
        hasInitialized = true;
    }

    private void CaptureBaseState()
    {
        baseWorldPosition = transform.position;
        baseWorldRotation = transform.rotation;
    }

    private void RebuildMotionProfile()
    {
        OrbitLoops = Mathf.Max(0f, OrbitLoops);
        AccelDuration = Mathf.Max(0f, AccelDuration);
        CruiseDuration = Mathf.Max(0f, CruiseDuration);
        DecelDuration = Mathf.Max(0f, DecelDuration);

        totalAngle = 360f * OrbitLoops;
        totalDuration = AccelDuration + CruiseDuration + DecelDuration;

        float effectiveTime = 0.5f * AccelDuration + CruiseDuration + 0.5f * DecelDuration;
        if (effectiveTime <= 0.0001f || totalAngle <= 0.0001f)
        {
            maxAngularSpeed = 0f;
            accelRate = 0f;
            decelRate = 0f;
            return;
        }

        maxAngularSpeed = totalAngle / effectiveTime;
        accelRate = AccelDuration > 0f ? maxAngularSpeed / AccelDuration : 0f;
        decelRate = DecelDuration > 0f ? maxAngularSpeed / DecelDuration : 0f;
    }

    private Vector3 ResolveCenterPosition()
    {
        return OrbitCenter != null ? OrbitCenter.position : baseWorldPosition;
    }

    private float GetAngleAtTime(float time)
    {
        if (time <= 0f)
        {
            return 0f;
        }

        if (totalDuration <= 0.0001f || totalAngle <= 0.0001f)
        {
            return totalAngle;
        }

        float angle = 0f;
        float t = time;

        if (AccelDuration > 0f)
        {
            if (t < AccelDuration)
            {
                return 0.5f * accelRate * t * t;
            }
            angle += 0.5f * maxAngularSpeed * AccelDuration;
            t -= AccelDuration;
        }

        if (CruiseDuration > 0f)
        {
            if (t < CruiseDuration)
            {
                return angle + maxAngularSpeed * t;
            }
            angle += maxAngularSpeed * CruiseDuration;
            t -= CruiseDuration;
        }

        if (DecelDuration > 0f && t < DecelDuration)
        {
            return angle + maxAngularSpeed * t - 0.5f * decelRate * t * t;
        }

        return totalAngle;
    }

    private void ApplyAngle(float targetAngle)
    {
        float deltaAngle = targetAngle - currentAngle;
        if (Mathf.Abs(deltaAngle) <= 0.0001f)
        {
            return;
        }

        transform.RotateAround(cachedCenterPosition, normalizedAxis, deltaAngle);
        if (KeepOriginalRotation)
        {
            transform.rotation = baseWorldRotation;
        }
        currentAngle = targetAngle;
    }

    private static Vector3 NormalizeAxis(Vector3 axis, Vector3 fallbackAxis)
    {
        return axis.sqrMagnitude > 0.0001f ? axis.normalized : fallbackAxis;
    }
}

