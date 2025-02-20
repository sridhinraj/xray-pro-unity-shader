using UnityEngine;

public class XRayEffectWithAutodeskShader : MonoBehaviour
{ 
    public Material clippingMaterial; // The material using the ClippingShader
    public Transform planeTransform; // The transform of the cutting plane
    public Vector4 clipPlane; // Plane's position and direction

    void Update()
    {
        // Update the clip plane position based on the planeTransform
        clipPlane = new Vector4(planeTransform.up.x, planeTransform.up.y, planeTransform.up.z,
                               -Vector3.Dot(planeTransform.position, planeTransform.up));

        // Send the clip plane data to the shader
        clippingMaterial.SetVector("_ClipPlane", clipPlane);
    }
}
