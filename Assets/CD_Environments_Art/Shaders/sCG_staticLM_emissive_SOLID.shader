// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_staticLM_emissive_SOLID" {
	Properties {
		_Overbright ("Overbright", Float) = 1.0 
		_Emissive ("EmissiveAmount", Float) = 1.0 
		_EmiCol("EmissiveColor", Color) = (1,1,1,1)
		_DF ("DiffuseMap (ch1)", 2D) = "white" {}
		_MK ("MaskMap (ch1)", 2D) = "white" {} 
		_LM ("LightMap (ch2)", 2D) = "white" {} 
	}
	
	SubShader {
		
		// INI TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
		Tags { 	
			//- HELP: http://docs.unity3d.com/Manual/SL-SubshaderTags.html
			
			//"Queue"="Background " 	// this render queue is rendered before any others. It is used for skyboxes and the like.
			"Queue"="Geometry" 		// (default) - this is used for most objects. Opaque geometry uses this queue.
			//"Queue"="AlphaTest" 		// alpha tested geometry uses this queue.
			//"Queue"="Transparent" 	// alpha blend pixels here!
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
		//Blend OneMinusDstColor One 		// Soft Additive (screen)
		//Blend DstColor Zero 				// Multiplicative
		
		Fog {Mode Global} // MODE: Off | Global | Linear | Exp | Exp
		
		//- HELP: http://docs.unity3d.com/Manual/SL-Pass.html
		
	    //Lighting OFF 	//Turn vertex lighting on or off
	    //ZWrite OFF	//Set depth writing mode
	    //Cull OFF 		//Back | Front | Off = two sided
		//ZTest Always  //Always = paint always front (Less | Greater | LEqual | GEqual | Equal | NotEqual | Always)
		//AlphaTest 	//(Less | Greater | LEqual | GEqual | Equal | NotEqual | Always) CutoffValue
		
		// END TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
		
		
		Pass {
		
		CGPROGRAM
		#pragma vertex vert 
		#pragma fragment frag
		#pragma multi_compile_fog
		#include "UnityCG.cginc"

		//user defined variables
		uniform sampler2D 	_DF;
		uniform sampler2D	_MK;
		uniform sampler2D	_LM;
		uniform half		_Overbright;
		uniform fixed		_Emissive;
		uniform fixed4		_EmiCol;

		//base input structs
		struct vertexInput {
			float4 vertex : POSITION;
			half2 uv0 : TEXCOORD0;
			half2 uv1 : TEXCOORD1;			
			fixed4 color : COLOR;
		};

		struct vertexOutput {
			float4 pos : SV_POSITION;
			half2 uv0 : TEXCOORD0;
			half2 uv1 : TEXCOORD1;
			UNITY_FOG_COORDS(2)
		};

		//vertex function
		vertexOutput vert(vertexInput v)
		{
			vertexOutput o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv0 = v.uv0.xy;
			o.uv1 = v.uv1.xy;
			UNITY_TRANSFER_FOG(o, o.pos);
			return o;
		}

		//fragment function
		fixed4 frag(vertexOutput i) : COLOR
		{
			fixed4 DF = tex2D(_DF, i.uv0);
			fixed4 MK = tex2D(_MK, i.uv0);
			fixed4 LM = tex2D(_LM, i.uv1);

			fixed4 Complete = fixed4(DF.rgb * (LM.rgb + ((MK.g * _Emissive) * _EmiCol)) * _Overbright, DF.a);
			UNITY_APPLY_FOG(i.fogCoord, Complete);

			return Complete;
		}

		ENDCG
      }
	}
}
