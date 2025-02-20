using UnityEngine;

[ExecuteInEditMode]
public class ClippingPlane : MonoBehaviour
{
    public Material material;

    [Header("Clipping Plane Settings")]
    [Range(-10f, 10f)]
    public float offset = 0.1f;  // Offset from the object's position to control clipping distance

    void Update()
    {
        if (material == null)
        {
            Debug.LogError("Material not assigned to the ClippingPlane script.");
            return;
        }

        // Set the plane normal in world space
        Vector4 clipPlaneNormal = new Vector4(transform.up.x, transform.up.y, transform.up.z, 0);
        material.SetVector("_ClipPlaneNormal", clipPlaneNormal);

        // Calculate the plane position using the object's position and the offset
        Vector4 clipPlanePos = new Vector4(transform.position.x, transform.position.y, transform.position.z + offset, 1);
        material.SetVector("_ClipPlanePos", clipPlanePos);

        // Debugging output
        Debug.Log($"Clip Plane Normal: {clipPlaneNormal}");
        Debug.Log($"Clip Plane Position: {clipPlanePos}");
    }
}
