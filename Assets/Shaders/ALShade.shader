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

            struct appdata
            {
                float4 vertex : POSITION; // gl_position
                float2 uv : TEXCOORD0; // UV
            };

            // Struct for area light
            struct AreaLight
            {
                float3 Polygon[4];
                float radiance;
            };

            uniform AreaLight areaLight1;

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
            
            // SV_Target is a semantic signifier
            // See https://docs.unity3d.com/Manual/SL-ShaderSemantics.html
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 color = tex2D(_MainTex, i.uv);

                // Calculate irradiance of Area Light
                
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

                return color;
            }
            ENDCG
        }
    }
}
