// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "AreaLight/Shading"
{
    Properties
    {
        // roughness ("Roughness", Range(0.0, 1.0)) = 0.5
        DiffuseColor ("Diffuse Color", Color) = (0.5,0.5,0.5,1)
        SpecularColor ("Specular Color", Color) = (1,1,1,1)

        MainTex ("Texture", 2D) = "white" {}

        InverseMTex ("Special", 2D) = "white" {}
        AmpTex ("Special", 2D) = "white" {}
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

            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"


            // Shader pipeline structs 
            // Vertex shader input
            struct appdata
            {
                float4 vertex : POSITION; // gl_position
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0; // UV
                float3 texcoord : TEXCOORD1; // Ray Casting
            };

            // Vertex shader output, frag shader input
            struct v2f
            {
                float4 vertex : SV_POSITION; // Clip space position
                float2 uv : TEXCOORD0; // UV
                float4 ssUV : TEXCOORD1;
                float3 ray : TEXCOORD2;
                float4 vertex_World : TEXCOORD3;
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
            float4x4 inverseViewProjM;

            sampler2D _CameraDepthTexture;
            sampler2D MainTex;
            // Texture storing parameters for inverse M
            // M = [a 0 b]
            //     [0 c 0]
            //     [d 0 1]
            // a b c d are stored and accessed by roughness and theta
            sampler2D_float InverseMTex; 
            sampler2D_float AmpTex; 


            // Helper functions
            // Integrate one edge of the polygon
            float Integrate(float3 p1, float3 p2)
            {
                float cosTheta = dot(p1, p2);
                float theta = acos(cosTheta);    
                float result = cross(p1, p2).z * ((theta > 0.001) ? theta/sin(theta) : 1.0);

                return result;
            }

            int isVisible(float3 fragToPolygon_0[5])
            {
                for (int i = 0; i < 5; i++)
                {
                    if (fragToPolygon_0[i].z > 0) return 1;
                }     

                return 0;
            }
            
            // Compute the irradiance by integrating the LTC
            float3 CalculateIrradiance(float3 position,
                                       float3 normal, 
                                       float3 cameraDirection, 
                                       float3x3 inverseM)
            {
                // Orthonormal basis around N
                float3 T1;
                float3 T2;

                T1 = normalize(cameraDirection - normal*dot(cameraDirection,normal));
                T2 = normalize(cross(normal, T1));

                // inverseM = mul(inverseM, transpose(float3x3(T1, T2, normal)));
                inverseM = mul(inverseM, float3x3(T1, T2, normal));

                // Clipping?

                // Calculate the directions from current frag to P_0
                float3 fragToPolygon_0[5];

                for (int i = 0; i < 4; i++)
                {
                    float3 fragToPolygon = AreaLightPolygon_World[i] - position;
                    fragToPolygon_0[i] = mul(inverseM, fragToPolygon);
                }                

                fragToPolygon_0[4] = float3(0,0,0);

                // int n;
                // ClipQuadToHorizon(fragToPolygon_0, n);

                if (isVisible(fragToPolygon_0) == 0) return float3(0,0,0);
                // if (n == 0) return float3(0,0,0);

                fragToPolygon_0[0] = normalize(fragToPolygon_0[0]);
                fragToPolygon_0[1] = normalize(fragToPolygon_0[1]);
                fragToPolygon_0[2] = normalize(fragToPolygon_0[2]);
                fragToPolygon_0[3] = normalize(fragToPolygon_0[3]);
                fragToPolygon_0[4] = normalize(fragToPolygon_0[4]);

                // Integrate the polygon 
                
                // Translate the author's code
                // integrate
                float sum = 0.0;

                sum += Integrate(fragToPolygon_0[0], fragToPolygon_0[1]);
                sum += Integrate(fragToPolygon_0[1], fragToPolygon_0[2]);
                sum += Integrate(fragToPolygon_0[2], fragToPolygon_0[3]);                
                sum += Integrate(fragToPolygon_0[3], fragToPolygon_0[0]);

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

                sum = max(0.0, sum);

                float3 result = float3(sum, sum, sum);

                return result;

            }



        
            // Vertex Shader
            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal_World = normalize(UnityObjectToWorldNormal(v.normal));
                o.vertex_World = mul(unity_ObjectToWorld, v.vertex);
                
                // Frag World Space Position
                o.ssUV = ComputeScreenPos(o.vertex);

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

                float3 viewDir_World = normalize(UnityWorldSpaceViewDir(i.vertex_World));

                theta = acos(dot(i.normal_World, viewDir_World));
                inverseM_UV = float2(roughness, theta/UNITY_HALF_PI);

                // Some constant from the author
                float LUT_SIZE  = 64.0;
                float LUT_SCALE = (LUT_SIZE - 1.0)/LUT_SIZE;
                float LUT_BIAS  = 0.5/LUT_SIZE;
                inverseM_UV = inverseM_UV * LUT_SCALE + LUT_BIAS;

                // // Sample inverseM_Param to get the fitted value for inverseM
                float4 inverseM_Sample = tex2D(InverseMTex, inverseM_UV);
                float4 amp_Sample = tex2D(AmpTex, inverseM_UV);
                
                inverseM_Sample.b = 1.0;

                // return fixed4(amp_Sample);    

                // return fixed4(inverseM_Sample);            

                // float3x3 inverseM = float3x3( float3(                1,                 0, inverseM_Sample.y),
                //                               float3(                0, inverseM_Sample.z,                 0),
                //                               float3(inverseM_Sample.w,                 0, inverseM_Sample.x));

                float3x3 inverseM = float3x3( float3(                1,                 0, inverseM_Sample.w),
                                              float3(                0, inverseM_Sample.z,                 0),
                                              float3(inverseM_Sample.y,                 0, inverseM_Sample.x));

                // // Calculate irradiance of Area Light by evaluating LTC
                float3 irradiance = CalculateIrradiance(i.vertex_World, i.normal_World, viewDir_World, inverseM);
                irradiance *= amp_Sample.w;  
                
                // float3 irradiance = float3(0,0,0);              

                // return fixed4(irradiance, 1.0);

                float3x3 identityM = float3x3 (float3(1,0,0),
                                               float3(0,1,0),
                                               float3(0,0,1));
                float3 radiance = CalculateIrradiance(i.vertex_World, i.normal_World, viewDir_World, identityM);

                float3 result = (irradiance * SpecularColor + radiance * DiffuseColor) * AreaLightColor * AreaLightIntensity * UNITY_INV_TWO_PI;

                return fixed4(result, 1.0);

                // return fixed4(normalize(AreaLightPolygon_World[1]));
            }

            ENDCG
        }
    }
    FallBack "Standard"
}
