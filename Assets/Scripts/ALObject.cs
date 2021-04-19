using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ALObject : MonoBehaviour
{
    public Color AreaLightColor;
    public float AreaLightIntensity = 1.0F;

    // public Material 

    private Mesh currentALMesh;

    // Start is called before the first frame update
    void Start()
    {
        // Get the vertices from the current MeshFilter
        currentALMesh = gameObject.GetComponent<MeshFilter>().mesh;

        // Validate vertices (Only 4 vertices for now)
        foreach (Vector3 vertex in currentALMesh.vertices)
        {
            Debug.Log(vertex);
        }

        // Set shader properties
        Shader.SetGlobalColor("AreaLightColor", AreaLightColor);
        Shader.SetGlobalFloat("AreaLightIntensity", AreaLightIntensity);
        Shader.SetGlobalVectorArray("AreaLightPolygon_World", currentALMesh.vertices);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
