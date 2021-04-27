// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "AreaLight/Shading"
{
    Properties
    {
        roughness ("Roughness", Range(0.0, 1.0)) = 0.5

        MainTex ("Texture", 2D) = "white" {}

        InverseMTex ("Special", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members normal_World,viewDir_World)
#pragma exclude_renderers d3d11

            // Set "vert" as the vertex shader function
            #pragma vertex vert
            // Set "frag" as the fragment shader function
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"


            // Shader pipeline structs 
            // Vertex shader input
            struct appdata
            {
                float4 vertex : POSITION; // gl_position
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0; // UV
            };

            // Vertex shader output, frag shader input
            struct v2f
            {
                float2 uv : TEXCOORD0; // UV
                float4 vertex : SV_POSITION; // Clip space position, camera space?
                float4 vertex_World : COLOR;
                float3 normal_World : NORMAL;
            };

            
            // Global Variables

            fixed4 DiffuseColor;
            fixed4 SpecularColor;
            fixed4 AreaLightColor;
            float AreaLightIntensity;
            float4 AreaLightPolygon_World[4];

            float roughness;

            float3 cameraPos;

            sampler2D MainTex;
            // Texture storing parameters for inverse M
            // M = [a 0 b]
            //     [0 c 0]
            //     [d 0 1]
            // a b c d are stored and accessed by roughness and theta
            sampler2D InverseMTex; 


            // Helper functions
            // Compute the irradiance by integrating the LTC
            float3 CalculateIrradiance(float3 normal, 
                                       float3 cameraDirection, 
                                       float3x3 inverseM)
            {
                // Orthonormal basis around N


                // Calculate the P_0 from provided polygon
                float3 Polygon_0[4];
                for (int i = 0; i < 4; i++)
                {
                    Polygon_0[i] = mul(inverseM, AreaLightPolygon_World[i].xyz);
                }

                // Clipping?

                // Calculate the directions from current frag to P_0
                float3 fragToPolygon_0[4];
                for (int i = 0; i < 4; i++)
                {
                    fragToPolygon_0[i] = normalize(AreaLightPolygon_World[i].xyz);
                }                


                // Integrate the polygon 
                
                // Translate the author's code
                float sum = 0.0;
                for (int i = 0; i < 4; i++)
                {
                    int j = (i + 1) % 4;

                    float3 p_i = AreaLightPolygon_World[i].xyz;
                    float3 p_j = AreaLightPolygon_World[j].xyz;

                    float cosTheta = dot(p_i, p_j);
                    float theta = acos(cosTheta);    
                    sum += cross(p_i, p_j).z * ((theta > 0.001) ? theta/sin(theta) : 1.0);
                }
                
                // My understanding:
                // float sum = 0.0;
                // for (int i = 0; i < 4; i++)
                // {
                //     int j = (i + 1) % n;

                //     float3 p_i = AreaLightPolygon_World[i];
                //     float3 p_j = AreaLightPolygon_World[j];

                //     float inner1 = InnerProduct(p_i, p_j);
                //     float inner2 = InnerProduct(cross(p_i, p_j) / abs(cross(p_i, p_j)), float3(0.0, 0.0, 1.0));

                //     sum += acos(inner1) * inner2;
                // }

                float irradiance = UNITY_INV_TWO_PI * sum;

                float3 result = float3(irradiance, irradiance, irradiance);

                return result;

            }



        
            // Vertex Shader
            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal_World = UnityObjectToWorldNormal(v.normal);
                o.vertex_World = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            // Debug
            // fixed4 frag (v2f i) : SV_Target
            // {
            //     return fixed4(AreaLightPolygon_World[3]);
            // }


            // Fragment Shader
            // SV_Target is a semantic signifier
            // See https://docs.unity3d.com/Manual/SL-ShaderSemantics.html
            fixed4 frag (v2f i) : SV_Target
            {
                //Fragment Specific Variables
                float theta;
                float2 inverseM_UV; // UV value for accessing inverseMParam

                float3 viewDir_World = UnityWorldSpaceViewDir(i.vertex_World);

                theta = acos(dot(i.normal_World, viewDir_World));
                inverseM_UV = float2(roughness, theta/UNITY_HALF_PI);

                // Sample inverseM_Param to get the fitted value for inverseM
                float4 inverseM_Sample = tex2D(InverseMTex, inverseM_UV);
                
                // return fixed4(inverseM_Sample);                

                float3x3 inverseM = float3x3( float3(                1,                 0, inverseM_Sample.y),
                                              float3(                0, inverseM_Sample.z,                 0),
                                              float3(inverseM_Sample.w,                 0, inverseM_Sample.x));

                // Calculate irradiance of Area Light by evaluating LTC
                float3 irradiance = CalculateIrradiance(i.normal_World, viewDir_World, inverseM);
                
                return fixed4(irradiance, 1.0);

                // irradiance *= inverseM_Sample.w;

                // float3x3 identityM = float3x3 (1,0,0,
                //                                0,1,0,
                //                                0,0,1);
                // float3 radiance = CalculateIrradiance(i.normal_World, viewDir_World, identityM);

                // float3 result = (irradiance * SpecularColor + radiance * DiffuseColor) * AreaLightColor;
                // fixed4 result_fixed4 = fixed4(result.r, result.g, result.b, 1.0);
                
                // return result_fixed4;
            }

            ENDCG
        }
    }
}
