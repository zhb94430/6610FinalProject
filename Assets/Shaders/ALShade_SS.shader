Shader "AreaLight/ALShade_SS"
{
    Properties
    {
        DiffuseColor ("Diffuse Color", Color) = (0.5,0.5,0.5,1)
        SpecularColor ("Specular Color", Color) = (1,1,1,1)
        // AreaLightColor("Area Light Color", Color) = (1.0, 1.0, 1.0, 1.0)
        // AreaLightIntensity("Area Light Intensity", Float) = 1.0

        MainTex ("Albedo (RGB)", 2D) = "white" {}
        InverseMTex ("Special", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // #pragma surface surf Standard fullforwardshadows
        #pragma surface surf AreaLight

        #include "UnityPBSLighting.cginc"

        const float PI = 3.14159;

        fixed4 DiffuseColor;
        fixed4 SpecularColor;
        fixed4 AreaLightColor;
        float AreaLightIntensity;
        float4 AreaLightPolygon_World[4];

        sampler2D MainTex;
        sampler2D InverseMTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
        };

        
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

            float irradiance = 1/2*PI * sum;

            float3 result = float3(irradiance, irradiance, irradiance);

            return result;

        }
        
        fixed4 LightingAreaLight(SurfaceOutputStandard s, 
                        float3 lightDir, 
                        half3 viewDir)
        {
            return fixed4(s.Albedo, 1.0);            
        }

        // Area Light lighting function
        // fixed4 LightingAreaLight(SurfaceOutputStandard s, 
        //                         float3 lightDir, 
        //                         float3 viewDir)
        // {
        //     float theta;
        //     float2 inverseM_UV;   

        //     s.Normal = normalize(s.Normal);

        //     theta = acos(dot(s.Normal, viewDir)); // might be -viewDir
        //     inverseM_UV = float2(s.Smoothness, theta/(0.5*PI));

        //     float4 inverseM_Sample = tex2D(InverseMTex, inverseM_UV);

        //     float3x3 inverseM = float3x3( float3(                1,                 0, inverseM_Sample.y),
        //                                   float3(                0, inverseM_Sample.z,                 0),
        //                                   float3(inverseM_Sample.w,                 0, inverseM_Sample.x));

        //     // Calculate irradiance of Area Light by evaluating LTC
        //     float3 irradiance = CalculateIrradiance(s.Normal, viewDir, inverseM);
        //     irradiance *= inverseM_Sample.w;


        //     float3x3 identityM = float3x3 (1,0,0,
        //                                    0,1,0,
        //                                    0,0,1);

        //     float3 radiance = CalculateIrradiance(s.Normal, viewDir, identityM);

        //     float3 result = (irradiance * SpecularColor + radiance * DiffuseColor) * AreaLightColor;

        //     fixed4 result_fixed4 = fixed4(result.r, result.g, result.b, 1.0);

        //     return result_fixed4;
        // }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (MainTex, IN.uv_MainTex);
            o.Smoothness = 0.5;
            // o.Albedo = c.rgb;
            o.Albedo = IN.viewDir;
        }
        ENDCG
    }
    // FallBack "Diffuse"
    FallBack Off
}
