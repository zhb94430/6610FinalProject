// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Test"
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

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;
                
                return o;
            }

            sampler2D _MainTex;

            // fixed4 is a low percision vec4 float?
            // SV_Target is a semantic signifier
            // See https://docs.unity3d.com/Manual/SL-ShaderSemantics.html
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 color = tex2D(_MainTex, i.uv);

                return color;
            }
            ENDCG
        }
    }
}
