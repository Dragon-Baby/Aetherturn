using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceAudioBridge : MonoBehaviour
{
    public bool EnableAudio = true;
    public float MasterVolume = 1f;
    public AudioSource PendulumAudio;
    public GameObject PendulumAudioObject;
    public AudioSource ExtendAudio;
    public GameObject ExtendAudioObject;
    public AudioSource RotateAudio;
    public GameObject RotateAudioObject;
    public AudioSource SpinAudio;
    public GameObject SpinAudioObject;
    public bool EnableDebugLog;

    private readonly List<AudioSource> oneShotSources = new List<AudioSource>();
    private AudioSource continuousSource;

    public void ResetToBase()
    {
        StopAll(true);
    }

    public void BeginState(string stateName)
    {
        if (!EnableAudio)
        {
            StopAll(true);
            return;
        }

        if (stateName == "Pendulum")
        {
            BeginContinuous(GetPendulumAudio(), stateName);
        }
        else if (stateName == "CenterSpin")
        {
            BeginContinuous(GetSpinAudio(), stateName);
        }
        else if (stateName == "ExtendForward" || stateName == "Retract")
        {
            BeginOneShot(GetExtendAudio(), stateName);
        }
        else if (stateName == "BallRotate" || stateName == "BallReset")
        {
            BeginOneShot(GetRotateAudio(), stateName);
        }
        else
        {
            StopContinuousIfDifferent(null);
        }
    }

    public void Tick(float deltaTime)
    {
        for (int i = oneShotSources.Count - 1; i >= 0; i--)
        {
            AudioSource audioSource = oneShotSources[i];
            if (audioSource != null && audioSource.isPlaying)
            {
                continue;
            }

            if (audioSource != null)
            {
                audioSource.enabled = false;
            }
            oneShotSources.RemoveAt(i);
        }
    }

    public void PauseAll()
    {
        List<AudioSource> sources = CollectConfiguredSources();
        for (int i = 0; i < sources.Count; i++)
        {
            if (sources[i] != null && sources[i].isPlaying)
            {
                sources[i].Pause();
            }
        }
    }

    public void ResumeActive()
    {
        if (continuousSource != null)
        {
            continuousSource.enabled = true;
            continuousSource.UnPause();
        }

        for (int i = 0; i < oneShotSources.Count; i++)
        {
            if (oneShotSources[i] != null)
            {
                oneShotSources[i].enabled = true;
                oneShotSources[i].UnPause();
            }
        }
    }

    public void StopAll()
    {
        StopAll(true);
    }

    public void StopAll(bool disableSources)
    {
        List<AudioSource> sources = CollectConfiguredSources();
        for (int i = 0; i < sources.Count; i++)
        {
            AudioSource audioSource = sources[i];
            if (audioSource == null)
            {
                continue;
            }

            audioSource.Stop();
            if (disableSources)
            {
                audioSource.enabled = false;
            }
        }

        oneShotSources.Clear();
        continuousSource = null;
    }

    private AudioSource GetPendulumAudio() => ResolveAudioSource(PendulumAudio, PendulumAudioObject);
    private AudioSource GetExtendAudio() => ResolveAudioSource(ExtendAudio, ExtendAudioObject);
    private AudioSource GetRotateAudio() => ResolveAudioSource(RotateAudio, RotateAudioObject);
    private AudioSource GetSpinAudio() => ResolveAudioSource(SpinAudio, SpinAudioObject);

    private static AudioSource ResolveAudioSource(AudioSource audioSource, GameObject audioObject)
    {
        return audioSource != null ? audioSource : audioObject != null ? audioObject.GetComponent<AudioSource>() : null;
    }

    private List<AudioSource> CollectConfiguredSources()
    {
        List<AudioSource> sources = new List<AudioSource>();
        AddUnique(sources, GetPendulumAudio());
        AddUnique(sources, GetExtendAudio());
        AddUnique(sources, GetRotateAudio());
        AddUnique(sources, GetSpinAudio());
        return sources;
    }

    private void BeginContinuous(AudioSource audioSource, string label)
    {
        StopContinuousIfDifferent(audioSource);
        if (PlayFromStart(audioSource, true))
        {
            continuousSource = audioSource;
            oneShotSources.Remove(audioSource);
            Log("Begin continuous " + label);
        }
    }

    private void BeginOneShot(AudioSource audioSource, string label)
    {
        StopContinuousIfDifferent(null);
        if (PlayFromStart(audioSource, false))
        {
            AddUnique(oneShotSources, audioSource);
            Log("Begin one-shot " + label);
        }
    }

    private void StopContinuousIfDifferent(AudioSource nextSource)
    {
        if (continuousSource != null && continuousSource != nextSource)
        {
            continuousSource.Stop();
            continuousSource.enabled = false;
            continuousSource = null;
        }
    }

    private bool PlayFromStart(AudioSource audioSource, bool shouldLoop)
    {
        if (audioSource == null)
        {
            return false;
        }

        audioSource.enabled = true;
        audioSource.playOnAwake = false;
        audioSource.loop = shouldLoop;
        audioSource.volume = Mathf.Clamp01(MasterVolume);
        audioSource.Stop();
        audioSource.Play();
        return true;
    }

    private static void AddUnique<T>(List<T> list, T value)
    {
        if (value != null && !list.Contains(value))
        {
            list.Add(value);
        }
    }

    private void Log(string message)
    {
        if (EnableDebugLog)
        {
            Debug.Log("[DouyinSequenceAudioBridge] " + message, this);
        }
    }
}

