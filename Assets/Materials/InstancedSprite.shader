// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Sprites/InstancedSprite"
{
    Properties
    {
//        _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _Textures("Textures", 2DArray) = "" {}
        [HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
        [HideInInspector] _Flip ("Flip", Vector) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
        CGPROGRAM
            #pragma vertex SpriteVert
            #pragma fragment SpriteFrag
            #pragma require 2darray
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            UNITY_DECLARE_TEX2DARRAY(_Textures);
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float, _TextureIndex)
            UNITY_DEFINE_INSTANCED_PROP(half4, _Pivot)
            UNITY_DEFINE_INSTANCED_PROP(half4, _NewUV)
            UNITY_INSTANCING_BUFFER_END(Props)

            fixed4 _RendererColor;
            fixed2 _Flip;
            float _EnableExternalAlpha;

            fixed4 _Color;

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                // UNITY_VERTEX_OUTPUT_STEREO
            };

            inline float4 UnityFlipSprite(in float3 pos, in fixed2 flip)
            {
                return float4(pos.xy * flip, pos.z, 1.0);
            }

            v2f SpriteVert(appdata_t IN)
            {
                v2f OUT;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                UNITY_SETUP_INSTANCE_ID (IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

                // vertices transform matrix
                half4 pivot = UNITY_ACCESS_INSTANCED_PROP(Props, _Pivot);
                half4x4 m;
                m._11 = pivot.x; m._12 = 0; m._13 = 0; m._14 = pivot.z;
                m._21 = 0; m._22 = pivot.y; m._23 = 0; m._24 = pivot.w;
                m._31 = 0; m._32 = 0; m._33 = 1; m._34 = 0;
                m._41 = 0; m._42 = 0; m._43 = 0; m._44 = 1;

                OUT.vertex = UnityFlipSprite(IN.vertex, _Flip);

                // uv coordinate transform matrix
                half3x3 uvm;
                half4 newUV = UNITY_ACCESS_INSTANCED_PROP(Props, _NewUV);
                uvm._11 = newUV.x; uvm._12 = 0; uvm._13 = newUV.z;
                uvm._21 = 0; uvm._22 = newUV.y; uvm._23 = newUV.w;
                uvm._31 = 0; uvm._32 = 0; uvm._33 = 1;

                // sample quad's original uv
                half3 uv = half3(IN.texcoord.x, IN.texcoord.y, 1);

                // apply uv transform
                uv = mul(uvm, uv);

                // transform quad's original mesh to sprite's mesh
                OUT.vertex = mul(m, OUT.vertex);

                OUT.vertex = UnityObjectToClipPos(OUT.vertex);
                // OUT.texcoord = IN.texcoord;
                OUT.texcoord.x = uv.x;
                OUT.texcoord.y = uv.y;
                // OUT.color = IN.color * _Color * _RendererColor;

                return OUT;
            }

            sampler2D _MainTex;
            sampler2D _AlphaTex;

            fixed4 SpriteFrag(v2f IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                // fixed4 c = tex2D (_MainTex, IN.texcoord);
                // c.rgb *= c.a;

                // Now we sample texture from Texture2DArray
                fixed4 c = UNITY_SAMPLE_TEX2DARRAY(_Textures, float3(IN.texcoord, UNITY_ACCESS_INSTANCED_PROP(Props, _TextureIndex)));
                return c;
            }

        ENDCG
        }
    }
}
