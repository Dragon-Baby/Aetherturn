using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceController : MonoBehaviour
{
    private enum SequenceState
    {
        Idle,
        Pendulum,
        ExtendForward,
        BallRotate,
        CenterSpin,
        BallReset,
        Retract,
        Wait
    }

    public DouyinSequenceRegistry Registry;
    public float DelayAfterPendulum;
    public float DelayAfterExtend;
    public float DelayAfterBallRotate;
    public float DelayAfterCenterSpin;
    public float DelayAfterBallReset;
    public float DelayAfterRetract;
    public bool AutoPlay = true;
    public bool LoopSequence = true;
    public bool EnableDebugLog;

    private SequenceState currentState = SequenceState.Idle;
    private bool isPlaying;
    private bool pendingAutoPlay;
    private float waitTimer;
    private SequenceState waitNextState = SequenceState.Idle;

    private void Awake()
    {
        if (Registry != null)
        {
            Registry.Validate();
            Registry.CollectAll();
            Registry.ResetAllToBase();
            Registry.SetAllVertexLightIntensityScale(Registry.GetCurrentNightBlend01());
        }
        else
        {
            Log("Registry is nil");
        }

        pendingAutoPlay = AutoPlay && Registry != null;
        isPlaying = false;
        EnterState(SequenceState.Idle);
    }

    private void Update()
    {
        if (pendingAutoPlay)
        {
            pendingAutoPlay = false;
            if (Registry != null)
            {
                isPlaying = true;
                BeginState(SequenceState.Pendulum);
            }
        }

        if (!isPlaying || Registry == null)
        {
            return;
        }

        float deltaTime = Time.deltaTime;
        Registry.TickVertexLights(deltaTime);
        Registry.TickSequenceAudio(deltaTime);

        float? gearDriveFactor = currentState == SequenceState.CenterSpin ? Registry.GetOrbitSpeedFactor() : null;
        Registry.TickGears(deltaTime, gearDriveFactor);

        if (currentState == SequenceState.Wait)
        {
            waitTimer -= deltaTime;
            if (waitTimer <= 0f)
            {
                waitTimer = 0f;
                BeginState(waitNextState);
            }
            return;
        }

        if (currentState == SequenceState.Pendulum)
        {
            Registry.TickPendulums(deltaTime);
            if (Registry.ArePendulumsComplete())
            {
                EnterWaitState(DelayAfterPendulum, SequenceState.ExtendForward);
            }
            return;
        }

        if (currentState == SequenceState.ExtendForward)
        {
            Registry.TickExtenders(deltaTime);
            if (Registry.AreExtendersComplete())
            {
                EnterWaitState(DelayAfterExtend, SequenceState.BallRotate);
            }
            return;
        }

        if (currentState == SequenceState.BallRotate)
        {
            Registry.TickBalls(deltaTime);
            if (Registry.AreBallsComplete())
            {
                EnterWaitState(DelayAfterBallRotate, SequenceState.CenterSpin);
            }
            return;
        }

        if (currentState == SequenceState.CenterSpin)
        {
            Registry.TickOrbit(deltaTime);
            float orbitProgress = Registry.GetOrbitProgress01();
            Registry.TickOrbitFx(deltaTime, orbitProgress);
            Registry.SetAllVertexLightIntensityScale(Registry.GetOrbitNightBlend01(orbitProgress));
            if (Registry.IsOrbitComplete())
            {
                Registry.CompleteOrbitFx();
                EnterWaitState(DelayAfterCenterSpin, SequenceState.BallReset);
            }
            return;
        }

        if (currentState == SequenceState.BallReset)
        {
            Registry.TickBalls(deltaTime);
            if (Registry.AreBallsComplete())
            {
                EnterWaitState(DelayAfterBallReset, SequenceState.Retract);
            }
            return;
        }

        if (currentState == SequenceState.Retract)
        {
            Registry.TickExtenders(deltaTime);
            if (!Registry.AreExtendersComplete())
            {
                return;
            }

            if (LoopSequence)
            {
                EnterWaitState(DelayAfterRetract, SequenceState.Pendulum);
            }
            else
            {
                Registry.ResetAllToBase();
                Registry.SetAllVertexLightIntensityScale(Registry.GetCurrentNightBlend01());
                EnterState(SequenceState.Idle);
                isPlaying = false;
            }
        }
    }

    public void PlaySequence()
    {
        if (Registry == null)
        {
            Log("PlaySequence skipped because Registry is unavailable");
            return;
        }

        Registry.CollectAll();
        if (currentState == SequenceState.Idle)
        {
            pendingAutoPlay = false;
            BeginState(SequenceState.Pendulum);
        }
        isPlaying = true;
    }

    public void PauseSequence()
    {
        isPlaying = false;
        Registry?.PauseSequenceAudio();
    }

    public void ResumeSequence()
    {
        if (Registry == null)
        {
            return;
        }

        Registry.ResumeSequenceAudio();
        isPlaying = true;
    }

    public void RestartSequence()
    {
        if (Registry == null)
        {
            return;
        }

        Registry.CollectAll();
        Registry.ResetAllToBase();
        Registry.SetAllVertexLightIntensityScale(Registry.GetCurrentNightBlend01());
        pendingAutoPlay = false;
        waitTimer = 0f;
        waitNextState = SequenceState.Idle;
        isPlaying = true;
        BeginState(SequenceState.Pendulum);
    }

    public void StopSequence()
    {
        isPlaying = false;
        pendingAutoPlay = false;
        waitTimer = 0f;
        waitNextState = SequenceState.Idle;

        if (Registry != null)
        {
            Registry.ResetAllToBase();
            Registry.SetAllVertexLightIntensityScale(Registry.GetCurrentNightBlend01());
            Registry.StopSequenceAudio();
        }

        EnterState(SequenceState.Idle);
    }

    public int GetCurrentState()
    {
        return (int)currentState;
    }

    private void BeginState(SequenceState state)
    {
        if (Registry == null)
        {
            EnterState(SequenceState.Idle);
            isPlaying = false;
            return;
        }

        if (state == SequenceState.Pendulum)
        {
            Registry.BeginPendulums();
        }
        else if (state == SequenceState.ExtendForward)
        {
            Registry.BeginExtendForward();
        }
        else if (state == SequenceState.BallRotate)
        {
            Registry.BeginBallForward();
        }
        else if (state == SequenceState.CenterSpin)
        {
            Registry.BeginOrbit();
            Registry.BeginOrbitFx(Registry.GetOrbitDuration());
        }
        else if (state == SequenceState.BallReset)
        {
            Registry.BeginBallBackward();
        }
        else if (state == SequenceState.Retract)
        {
            Registry.BeginExtendBackward();
        }

        BeginAudioState(state);
        EnterState(state);
    }

    private void EnterWaitState(float duration, SequenceState nextState)
    {
        float waitDuration = Mathf.Max(0f, duration);
        if (waitDuration <= 0f)
        {
            BeginState(nextState);
            return;
        }

        waitTimer = waitDuration;
        waitNextState = nextState;
        BeginAudioState(SequenceState.Wait);
        EnterState(SequenceState.Wait);
    }

    private void BeginAudioState(SequenceState state)
    {
        Registry?.BeginSequenceAudio(GetStateName(state));
    }

    private void EnterState(SequenceState state)
    {
        currentState = state;
        Log("EnterState=" + state);
    }

    private static string GetStateName(SequenceState state)
    {
        switch (state)
        {
            case SequenceState.Pendulum:
                return "Pendulum";
            case SequenceState.ExtendForward:
                return "ExtendForward";
            case SequenceState.BallRotate:
                return "BallRotate";
            case SequenceState.CenterSpin:
                return "CenterSpin";
            case SequenceState.BallReset:
                return "BallReset";
            case SequenceState.Retract:
                return "Retract";
            case SequenceState.Wait:
                return "Wait";
            default:
                return "Idle";
        }
    }

    private void Log(string message)
    {
        if (EnableDebugLog)
        {
            Debug.Log("[DouyinSequenceController] " + message, this);
        }
    }
}

