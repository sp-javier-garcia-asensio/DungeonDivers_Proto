// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "SocialPoint/Particles/Additive" {
	Properties {
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
		_MainTex ("Particle Texture", 2D) = "white" {}
	}
	SubShader {
		LOD 200
		Tags { 
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			}
//			AlphaTest Greater .01
//			ColorMask RGB
			Cull Off
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			Blend SrcAlpha One
	
		Pass {
		
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_particles
			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			fixed4 _TintColor;
			fixed4 _Color;
			
			struct appdata_t {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;

			};
			
			float4 _MainTex_ST;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.color = v.color;
				o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 texCol = tex2D(_MainTex, i.texcoord);
				fixed4 col = i.color * texCol * _TintColor;

				float lum = Luminance(col.rgb);
				col.a = min(lum, col.a); 
				return col;
			}
			ENDCG 
		}
	}	
}
