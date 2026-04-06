using UnityEngine;

namespace Aetherturn
{
    public class SmoothAxisRotator : MonoBehaviour
    {
        public enum RotationAxis
        {
            X,
            Y,
            Z
        }

        public enum RotationDirection
        {
            Positive = 1,
            Negative = -1
        }

        [Header("Rotation")]
        public RotationAxis rotationAxis = RotationAxis.Y;
        public RotationDirection rotationDirection = RotationDirection.Positive;
        public Space rotationSpace = Space.Self;

        [Header("Speed")]
        public float slowSpeed = 30f;
        public float fastSpeed = 180f;
        [Range(0f, 1f)]
        public float startBlend = 0f;
        [Min(0.01f)]
        public float smoothTime = 0.35f;

        private float currentSpeed;
        private float targetSpeed;
        private float speedVelocity;

        private void Awake()
        {
            startBlend = Mathf.Clamp01(startBlend);
            currentSpeed = GetSpeedByBlend(startBlend);
            targetSpeed = currentSpeed;
        }

        private void Update()
        {
            currentSpeed = Mathf.SmoothDamp(
                currentSpeed,
                targetSpeed,
                ref speedVelocity,
                smoothTime,
                Mathf.Infinity,
                Time.deltaTime);

            Vector3 axis = GetAxisVector();
            float signedSpeed = currentSpeed * (float)rotationDirection;
            float deltaAngle = signedSpeed * Time.deltaTime;

            transform.Rotate(axis, deltaAngle, rotationSpace);
        }

        public void UseSlowSpeed()
        {
            targetSpeed = slowSpeed;
        }

        public void UseFastSpeed()
        {
            targetSpeed = fastSpeed;
        }

        public void SetUseFast(bool useFast)
        {
            targetSpeed = useFast ? fastSpeed : slowSpeed;
        }

        public void SetSpeedBlend(float blend)
        {
            targetSpeed = GetSpeedByBlend(blend);
        }

        public void SetSpeed(float speed)
        {
            targetSpeed = Mathf.Max(0f, speed);
        }

        public float GetCurrentSpeed()
        {
            return currentSpeed;
        }

        private float GetSpeedByBlend(float blend)
        {
            return Mathf.Lerp(slowSpeed, fastSpeed, Mathf.Clamp01(blend));
        }

        private Vector3 GetAxisVector()
        {
            switch (rotationAxis)
            {
                case RotationAxis.X:
                    return Vector3.right;
                case RotationAxis.Z:
                    return Vector3.forward;
                default:
                    return Vector3.up;
            }
        }
    }
}
