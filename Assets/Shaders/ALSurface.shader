Shader "AreaLight/Test"
{
    Properties
    {
        // AreaLightColor("Area Light Color", Color) = (1.0, 1.0, 1.0, 1.0)
        // AreaLightIntensity("Area Light Intensity", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        #pragma surface surf Lambert
        
        struct Input
        {
            float3 testColor;
        };

        float4 AreaLightColor;
        float AreaLightIntensity;
        
        void surf(Input IN, inout SurfaceOutput o)
        {
            float3 result = (AreaLightColor * AreaLightIntensity).rgb;
            o.Albedo = result;
        }

        ENDCG
        
    }
}
