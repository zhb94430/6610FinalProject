using System.Collections;
using System.Collections.Generic;
using static System.Exception;
using System;
using UnityEngine;

public class ALObject : MonoBehaviour
{
    public Color AreaLightColor;
    public float AreaLightIntensity = 1.0F;

    // Shader properties
    public float roughness = 0.4F;

    public List<GameObject> targetObjects;

    // public Material 

    private Mesh currentALMesh;
    private List<Vector4> verticesToShader;

    // Start is called before the first frame update
    void Start()
    {
        // Get the vertices from the current MeshFilter
        currentALMesh = gameObject.GetComponent<MeshFilter>().mesh;

        // Validate vertices (Only 4 vertices for now)
        
        SendToShader();
        

        // Load the LTC textures
        byte[] rawDDS_mat = System.IO.File.ReadAllBytes("./Assets/Textures/ltc_mat.dds");
        byte[] rawDDS_amp = System.IO.File.ReadAllBytes("./Assets/Textures/ltc_amp.dds");

        Texture2D LTC_mat = LoadTextureDXT(rawDDS_mat, TextureFormat.RGBAFloat);
        Texture2D LTC_amp = LoadTextureDXT(rawDDS_amp, TextureFormat.RGFloat);

        foreach (GameObject targetObject in targetObjects)
        {
            MeshRenderer targetMesh = targetObject.GetComponent<MeshRenderer>();

            targetMesh.material.SetTexture("InverseMTex", LTC_mat);
            targetMesh.material.SetTexture("AmpTex", LTC_amp);  
        }
    }

    // Update is called once per frame
    void Update()
    {
        SendToShader();
    }

    public void SendToShader()
    {
        verticesToShader = new List<Vector4>();

        foreach (Vector3 vertex in currentALMesh.vertices)
        {
            Vector3 vertex_World = transform.TransformPoint(vertex);

            // Debug.Log(vertex_World);

            Vector4 temp = new Vector4(vertex_World.x,
                                       vertex_World.y,
                                       vertex_World.z,
                                       1.0F);

            verticesToShader.Add(temp);
        }

        // Set shader properties
        Shader.SetGlobalColor("AreaLightColor", AreaLightColor);
        Shader.SetGlobalFloat("AreaLightIntensity", AreaLightIntensity);
        Shader.SetGlobalFloat("roughness", roughness);
        Shader.SetGlobalVectorArray("AreaLightPolygon_World", verticesToShader.ToArray());
    }

    //https://answers.unity.com/questions/555984/can-you-load-dds-textures-during-runtime.html
    public static Texture2D LoadTextureDXT(byte[] ddsBytes, TextureFormat textureFormat)
     {
        // if (textureFormat != TextureFormat.DXT1 && textureFormat != TextureFormat.DXT5)
       //      throw new Exception("Invalid TextureFormat. Only DXT1 and DXT5 formats are supported by this method.");
     
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

