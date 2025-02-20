using UnityEngine;

public class MaskMover : MonoBehaviour
{
    public Material targetMaterial;  // Material applied to the house with the shader
    public float moveSpeed = 2f;     // Speed of the sphere movement
    public float clipThreshold = 0.5f; // Threshold for clipping effect

    private Vector3 maskCenter;

    void Start()
    {
        // Initialize mask center to the position of the sphere
        maskCenter = transform.position;
        Debug.Log("Initial Mask Center: " + maskCenter);  // Debugging the initial position

        if (targetMaterial == null)
        {
            Debug.LogError("Target Material is not assigned!");  // Check if material is assigned
        }
        else
        {
            Debug.Log("Target Material assigned correctly.");
        }

        UpdateMaskCenter();
    }

    void Update()
    {
        // Move the sphere using WASD keys
        float moveX = Input.GetAxis("Horizontal") * moveSpeed * Time.deltaTime;
        float moveZ = Input.GetAxis("Vertical") * moveSpeed * Time.deltaTime;

        // Update position of the sphere
        transform.Translate(moveX, 0, moveZ);
        Debug.Log("Sphere moved to: " + transform.position);  // Debug the new position of the sphere

        // Update the mask center in the shader
        UpdateMaskCenter();
    }

    private void UpdateMaskCenter()
    {
        // Get the position of the sphere in world space
        maskCenter = transform.position;

        // Debug the mask center
        Debug.Log("Mask Center being sent to shader: " + maskCenter);

        // Update the "_MaskCenter" property in the material
        if (targetMaterial != null)
        {
            targetMaterial.SetVector("_MaskCenter", maskCenter);
            Debug.Log("_MaskCenter updated in shader.");
        }
        else
        {
            Debug.LogError("No material assigned to update _MaskCenter!");
        }

        // Update the "_AlphaClipThreshold" property in the material (controlling the cutout threshold)
        targetMaterial.SetFloat("_AlphaClipThreshold", clipThreshold);
        Debug.Log("_AlphaClipThreshold set to: " + clipThreshold);
    }
}
