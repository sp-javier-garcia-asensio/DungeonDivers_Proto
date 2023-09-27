// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_staticVC_NDIS_SOLID" {
	Properties {
		_Overbright ("Overbright", Float) = 0.5 
		_ReflectionAmount ("ReflectionAmount", Float) = 1.0 
		_ReflectionBend ("ReflectionBend", Float) = 0.0 
	    _Alpha ("Alpha", Range (0.0, 1.0)) = 1.0
		_DF ("DiffuseMap", 2D) = "white" {} 
		_MK ("MaskMap", 2D) = "white" {}
		_NDIS ("NdisMap", 2D) = "white" {} 
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
		
		Blend SrcAlpha OneMinusSrcAlpha 	// Alpha blending
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
		#include "UnityCG.cginc"

		//user defined variables
		uniform half    _ReflectionBend;
		uniform sampler2D   _DF;
		uniform sampler2D   _MK;
		uniform sampler2D   _NDIS;
		uniform half    _Overbright;
		uniform fixed   _ReflectionAmount;
		uniform fixed   _Alpha;

		//base input structs
		struct vertexInput {
			float4 vertex : POSITION;
			float4 normal : NORMAL;
			half2 uv0 : TEXCOORD0;			
			fixed4 color : COLOR;
		};

		struct vertexOutput {
			float4 pos : SV_POSITION;
			half2 uv0 : TEXCOORD0;
			half2 uvNdis : TEXCOORD1;
			fixed4 VC : COLOR;
		};

		//vertex function
		vertexOutput vert(vertexInput v)
		{
			vertexOutput o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv0 = v.uv0.xy;
			o.VC = v.color;

			//--- NDIS calculation
			float3 F = normalize(o.pos).xyz;
			F = F * 2.0;
			F.z = 0.0;

			half3 VSN = mul(UNITY_MATRIX_IT_MV, half4(v.normal.xyz, 0.0)).xyz;

			VSN = VSN + (F * _ReflectionBend);
			VSN = normalize(VSN) * 0.5 + 0.5;

			o.uvNdis = VSN.xy;

			return o;
		}

		//fragment function
		fixed4 frag(vertexOutput i) : COLOR
		{
			fixed4 DF = tex2D(_DF, i.uv0);
			fixed4 MK = tex2D(_MK, i.uv0);
			fixed4 NDIS = tex2D(_NDIS, i.uvNdis);
			NDIS *= MK.r * _ReflectionAmount;

			fixed3 Complete = DF.rgb * i.VC.rgb * _Overbright + NDIS.rgb;

			fixed alpha = DF.a * i.VC.a * _Alpha;

			return fixed4(Complete.rgb,alpha);
		}

		ENDCG
      }
	} 
}
