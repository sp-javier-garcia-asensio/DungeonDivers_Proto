// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_staticVC_vertexAnim_SOLID" {
	Properties {
		_Overbright ("Overbright", Float) = 2
		_DF ("Diffuse map", 2D) = "white" {} 
		_AnimDistortionAmount("Distortion amount (W multiplies XYZ)", Vector) = (1, 1, 0.33, 0.1)
		_AnimSpatialFrequency("Spatial frequency", Float) = 1.0
		_AnimSpeed("Animation Speed", Float) = 50
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
		
	    Lighting OFF 	//Turn vertex lighting on or off
	    ZWrite ON	//Set depth writing mode
	    Cull Back 		//Back | Front | Off = two sided
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
		uniform sampler2D _DF;
		uniform half _Overbright;
		uniform float4 _AnimDistortionAmount;
		uniform float _AnimSpatialFrequency;
		uniform float _AnimSpeed;

		//base input structs
		struct vertexInput {
			float4 vertex : POSITION;
			half2 uv0 : TEXCOORD0;
			fixed4 color : COLOR;
		};

		struct vertexOutput {
			float4 pos : SV_POSITION;
			half2 uv0 : TEXCOORD0;
			UNITY_FOG_COORDS(1)				
			fixed4 VC : COLOR;
		};

		//vertex function
		vertexOutput vert(vertexInput v)
		{
			vertexOutput o;

			float3 displaceAmount = v.color.a * _AnimDistortionAmount.w * _AnimDistortionAmount.xyz;			
			float3 displaceOverTime;
			displaceOverTime.x = ( sin(_Time.x * 0.91 * _AnimSpeed) + 0.5 * sin(_Time.x * 1.23 * _AnimSpeed) );
			displaceOverTime.y = ( sin(_Time.x * 1.03 * _AnimSpeed) - 0.4 * sin(_Time.x * 0.83 * _AnimSpeed) );
			displaceOverTime.z = ( sin(_Time.x * 0.87 * _AnimSpeed) + 0.37 * sin(_Time.x * 1.13 * _AnimSpeed) );
			float3 displaceOverSpace = sin(fmod(_Time.x, 37.0) * _AnimSpeed + v.vertex.xyz * _AnimSpatialFrequency);
			float3 vPos = v.vertex.xyz + displaceAmount * displaceOverTime * displaceOverSpace;

			o.pos = UnityObjectToClipPos(float4(vPos, 1.0));

			o.uv0 = v.uv0.xy;
			o.VC = v.color;

			UNITY_TRANSFER_FOG(o, o.pos);			
			return o;
		}

		//fragment function
		fixed4 frag(vertexOutput i) : COLOR
		{
			fixed4 DF = tex2D(_DF, i.uv0);

			fixed4 Complete = fixed4( DF.rgb * i.VC.rgb * _Overbright, 1 );

			UNITY_APPLY_FOG(i.fogCoord, Complete);

			return Complete;
		}
 		
		ENDCG
      }
	} 
}
