// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "socialPointCG/sCG_FX_Texture2ScrollUVAnimationAlphaBlend_SCREEN" {
Properties {
	_MainTex ("Main Texture (RGB)", 2D) = "white" {}
	[Header(Scroll 1st layer)]
	_ScrollMain("X/Y Speed Z/W Tiling",Vector) = (0,0,1,1)
	[Header(Scroll 2nd layer)]
	_ScrollSec("X/Y Speed Z/W Tiling",Vector) = (0,0,1,1)
	_Color("Color", Color) = (1,1,1,1)
	_MMultiplier ("Layer Multiplier", Float) = 2.0
}

	
SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	
	Blend SrcAlpha OneMinusSrcAlpha
	Cull Back Lighting Off ZWrite Off Fog{ Mode Off }
	
	
	
	
	
	Pass{

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	sampler2D _DetailTex;

	fixed4 _MainTex_ST, _ScrollMain, _ScrollSec, _Color;
	fixed _MMultiplier;
		
	
	

	struct vertexInput {
		float4 vertex : POSITION;
		float4 uv0 : TEXCOORD0;
		fixed4 color : COLOR;
	};

	struct vertexOutput {
		float4 pos : SV_POSITION;
		float4 uv0 : TEXCOORD0;
		fixed4 color : COLOR;
	};

	
	vertexOutput vert(vertexInput v)
	{
		vertexOutput o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv0.xy = TRANSFORM_TEX(v.uv0.xy,_MainTex)*_ScrollMain.zw + frac(float2(_ScrollMain.x, _ScrollMain.y) * _Time);
		o.uv0.zw = TRANSFORM_TEX(v.uv0.xy, _MainTex)*_ScrollSec.zw + frac(float2(_ScrollSec.x, _ScrollSec.y) * _Time);

		
		o.color = _MMultiplier * _Color * v.color;
		return o;
	}
	
	
		
			
		fixed4 frag (vertexOutput i) : COLOR
		{
			fixed4 o;
			fixed4 tex = tex2D (_MainTex, i.uv0.xy);
			fixed4 tex2 = tex2D (_MainTex, i.uv0.zw);
			
			o = tex * tex2 * i.color;
						
			return o;
		}
		ENDCG 
	}	
}
}
