// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_Fx_seaShore_SCREEN" {
	Properties {
		_Color ("Tint", Color) = (1,1,1,1)
		_Alpha ("Alpha", Float) = 1
		_DF ("Diffuse map", 2D) = "white" {} 
		_SpeedX ("Speed X", Float) = 0
		_SpeedY ("Speed Y", Float) = 1
		_ScaleX ("Scale X", Float) = 1
		_ScaleY ("Scale Y", Float) = 1
	}
	
	SubShader {
		
		// INI TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
		
		Tags { 	
			//- HELP: http://docs.unity3d.com/Manual/SL-SubshaderTags.html
			
			//"Queue"="Background " 	// this render queue is rendered before any others. It is used for skyboxes and the like.
			//"Queue"="Geometry" 		// (default) - this is used for most objects. Opaque geometry uses this queue.
			//"Queue"="AlphaTest" 		// alpha tested geometry uses this queue.
			"Queue"="Transparent" 	// alpha blend pixels here!
			//"Queue"="Overlay" 		// Anything rendered last should go in overlays i.e. lens flares
			
			
			//- HELP: http://docs.unity3d.com/Manual/SL-PassTags.html
			
			"LightMode" = "Always" 			// Always rendered; no lighting is applied.
			//"LightMode" = "ForwardBase"		// Used in Forward rendering, ambient, main directional light and vertex/SH lights are applied.
			//"LightMode" = "ForwardAdd"		// Used in Forward rendering; additive per-pixel lights are applied, one pass per light.
			//"LightMode" = "Pixel"				// ??
			//"LightMode" = "PrepassBase"		// deferred only...
			//"LightMode" = "PrepassFinal"		// deferred only...
			//"LightMode" = "Vertex"			// Used in Vertex Lit rendering when object is not lightmapped; all vertex lights are applied.
			//"LightMode" = "VertexLMRGBM"		// VertexLMRGBM: Used in Vertex Lit rendering when object is lightmapped; on platforms where lightmap is RGBM encoded.
			//"LightMode" = "VertexLM"			// Used in Vertex Lit rendering when object is lightmapped; on platforms where lightmap is double-LDR encoded (generally mobile platforms and old dekstop GPUs).
			//"LightMode" = "ShadowCaster"		// Renders object as shadow caster.
			//"LightMode" = "ShadowCollector"	// Gathers object’s shadows into screen-space buffer for Forward rendering path.
			
			
			//"IgnoreProjector"="True" 
		}
		
		//- HELP: http://docs.unity3d.com/Manual/SL-Blend.html
		
		//Blend SrcAlpha OneMinusSrcAlpha 	// Alpha blending
		//Blend One One 					// Additive
		Blend OneMinusDstColor One 		// Soft Additive (screen)
		//Blend DstColor Zero 				// Multiplicative
		
		Fog {Mode Off} // MODE: Off | Global | Linear | Exp | Exp
		
		//- HELP: http://docs.unity3d.com/Manual/SL-Pass.html
		
	    Lighting OFF 	//Turn vertex lighting on or off
	    ZWrite OFF	//Set depth writing mode
	    Cull OFF 		//Back | Front | Off = two sided
		//ZTest Always  //Always = paint always front (Less | Greater | LEqual | GEqual | Equal | NotEqual | Always)
		//AlphaTest 	//(Less | Greater | LEqual | GEqual | Equal | NotEqual | Always) CutoffValue
		
		// END TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
		
		Pass {
		
		CGPROGRAM
		#pragma vertex vert 
		#pragma fragment frag

		#include "UnityCG.cginc"

		//user defined variables
		uniform sampler2D _DF;
		uniform half _SpeedX;
		uniform half _SpeedY;
		uniform half _ScaleX;
		uniform half _ScaleY;
		uniform half _Alpha;
		uniform fixed4 _Color;

		//base input structs
		struct vertexInput {
			float4 vertex : POSITION;
			half2 uv0 : TEXCOORD0;
			fixed4 color : COLOR;
		};

		struct vertexOutput {
			float4 pos : SV_POSITION;
			float2 uv0_A : TEXCOORD0;
			float2 uv0_B : TEXCOORD1;
			float mixVal : TEXCOORD2;
			fixed4 VC : COLOR;
		};

		//vertex function
		vertexOutput vert(vertexInput v)
		{
			vertexOutput o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.VC = v.color;

			//float t = fmod(_Time.x, 30.0); //Time (t/20, t, t*2, t*3), use to animate things inside the shaders.
			float t1 = _SinTime.x; //Sine of time: (t/8, t/4, t/2, t).
			float t2 = _CosTime.x; //Cosine of time: (t/8, t/4, t/2, t).

			o.mixVal = (_SinTime.y + 1.0) * 0.5;

			half2 speed1 = half2(t1*_SpeedX, t1*_SpeedY);
			half2 speed2 = half2(t2*_SpeedX, t2*_SpeedY);
			half2 scale = half2(_ScaleX, _ScaleY);

			o.uv0_A = v.uv0.xy * scale + speed1;
			o.uv0_B = (v.uv0.xy * scale + speed2) * 0.85;

			return o;
		}

		//fragment function
		fixed4 frag(vertexOutput i) : COLOR
		{
			fixed4 DF1 = tex2D(_DF, i.uv0_A);
			fixed4 DF2 = tex2D(_DF, i.uv0_B);
			
			fixed4 DF = lerp(DF2, DF1, i.mixVal);
			fixed3 Complete = _Color.rgb * DF.r * i.VC.r * _Alpha;

			return fixed4(Complete, 1.0);
		}

		ENDCG
      }
	} 
}
