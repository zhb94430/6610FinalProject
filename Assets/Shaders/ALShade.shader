// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "AreaLight/Shading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM

            // Set "vert" as the vertex shader function
            #pragma vertex vert
            // Set "frag" as the fragment shader function
            #pragma fragment frag


            // Shader pipeline structs 
            // Vertex shader input
            struct appdata
            {
                float4 vertex : POSITION; // gl_position
                float2 uv : TEXCOORD0; // UV
            };

            // Vertex shader output, frag shader input
            struct v2f
            {
                float2 uv : TEXCOORD0; // UV
                float4 vertex : SV_POSITION; // Clip space position, camera space?
            };


            // Custom Structs
            // Struct for area light
            struct AreaLight
            {
                float3 Polygon[4]; // P_0
                float3 color;
                
                float radiance;
            };

            
            // Global Variables
            uniform AreaLight areaLight1;
            float3 cameraPos;

            // Texture storing parameters for inverse M
            // M = [a 0 b]
            //     [0 c 0]
            //     [d 0 1]
            // a b c d are stored and accessed by roughness and theta
            sampler2D inverseM_Param; 


            // Helper functions
            // Compute the irradiance by integrating the LTC
            float3 CalculateIrradiance(float3 normal, 
                                       float3 cameraDirection, 
                                       mat3 inverseM)
            {
                // Orthonormal basis around N


                // Calculate the P_0 from provided polygon
                float3 Polygon_0[4];
                for (int i = 0; i < 4; i++)
                {
                    Polygon_0[i] = inverseM * Polygon[i];
                }

                // Clipping?

                // Calculate the directions from current frag to P_0
                float3 fragToPolygon_0[4];
                for (int i = 0; i < 4; i++)
                {
                    fragToPolygon_0[i] = normalize(Polygon[i]);
                }                

                // Integrate the polygon
                float sum = 0.0;
                for (int i = 0; i < 4; i++)
                {
                    int j = (i + 1) % n;

                    p_i = areaLight1.Polygon[i];
                    p_j = areaLight1.Polygon[j];

                    float inner1 = InnerProduct(p_i, p_j);
                    float inner2 = InnerProduct(cross(p_i, p_j) / abs(cross(p_i, p_j)), float3(0.0, 0.0, 1.0));

                    sum += acos(inner1) * inner2;
                }

                float irradiance = 1/2*pi * sum;


            }



        
            // Vertex Shader
            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;
                
                return o;
            }




            // Fragment Shader
            // SV_Target is a semantic signifier
            // See https://docs.unity3d.com/Manual/SL-ShaderSemantics.html
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 result = fixed4(0.0, 0.0, 0.0, 0.0);

                //Fragment Specific Variables
                float3 normal_World;
                float3 cameraDirection_World;
                float theta;
                float2 inverseM_UV; // UV value for accessing inverseMParam

                theta = acos(dot(normal_World, cameraDirection_World));
                inverseM_UV = float2(roughness, theta/(0.5*pi));

                // Sample inverseM_Param to get the fitted value for inverseM
                float4 sample = texture2D(inverseM_Param, inverseM_UV);
                mat3 inverseM = mat3( vec3(       1,        0, sample.y),
                                      vec3(       0, sample.z,        0),
                                      vec3(sample.w,        0, sample.x));

                // Calculate irradiance of Area Light by evaluating LTC
                float3 irradiance = 

                

                return color;
            }

            ENDCG
        }
    }
}
