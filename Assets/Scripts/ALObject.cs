using System.Collections;
using System.Collections.Generic;
using static System.Exception;
using System;
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

        // Load the LTC textures
        byte[] rawDDS = System.IO.File.ReadAllBytes("./Assets/Textures/ltc_mat.dds");

        Texture2D LTC_mat = LoadTextureDXT(rawDDS, TextureFormat.DXT1);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public static Texture2D LoadTextureDXT(byte[] ddsBytes, TextureFormat textureFormat)
     {
         if (textureFormat != TextureFormat.DXT1 && textureFormat != TextureFormat.DXT5)
             throw new Exception("Invalid TextureFormat. Only DXT1 and DXT5 formats are supported by this method.");
     
         byte ddsSizeCheck = ddsBytes[4];
         if (ddsSizeCheck != 124)
             throw new Exception("Invalid DDS DXTn texture. Unable to read");  //this header byte should be 124 for DDS image files
     
         int height = ddsBytes[13] * 256 + ddsBytes[12];
         int width = ddsBytes[17] * 256 + ddsBytes[16];
     
         int DDS_HEADER_SIZE = 128;
         byte[] dxtBytes = new byte[ddsBytes.Length - DDS_HEADER_SIZE];
         Buffer.BlockCopy(ddsBytes, DDS_HEADER_SIZE, dxtBytes, 0, ddsBytes.Length - DDS_HEADER_SIZE);
     
         Texture2D texture = new Texture2D(width, height, textureFormat, false);
         texture.LoadRawTextureData(dxtBytes);
         texture.Apply();
     
         return (texture);
     }
}

