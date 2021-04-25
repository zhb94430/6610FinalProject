using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ALObject : MonoBehaviour
{
    public Color AreaLightColor;
    public float AreaLightIntensity = 1.0F;

    // public Material 

    private Mesh currentALMesh;
    private List<Vector4> verticesToShader;

    // Start is called before the first frame update
    void Start()
    {
        // Get the vertices from the current MeshFilter
        currentALMesh = gameObject.GetComponent<MeshFilter>().mesh;

        verticesToShader = new List<Vector4>();

        // Validate vertices (Only 4 vertices for now)
        foreach (Vector3 vertex in currentALMesh.vertices)
        {
            

            Vector3 vertex_World = transform.TransformPoint(vertex);

            Debug.Log(vertex_World);

            Vector4 temp = new Vector4(vertex_World.x,
                                       vertex_World.y,
                                       vertex_World.z,
                                       1.0F);

            verticesToShader.Add(temp);
        }

        // Set shader properties
        Shader.SetGlobalColor("AreaLightColor", AreaLightColor);
        Shader.SetGlobalFloat("AreaLightIntensity", AreaLightIntensity);
        Shader.SetGlobalVectorArray("AreaLightPolygon_World", verticesToShader.ToArray());
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
