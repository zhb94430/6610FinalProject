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
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        fixed4 DiffuseColor;
        fixed4 SpecularColor;
        fixed4 AreaLightColor;
        float AreaLightIntensity;
        float3 AreaLightPolygon_World[4];

        sampler2D MainTex;
        sampler2D InverseMTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
