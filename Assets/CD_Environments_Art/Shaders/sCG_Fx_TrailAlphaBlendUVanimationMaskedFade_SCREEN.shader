// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_Fx_TrailAlphaBlendUVanimationMaskedFade_SCREEN" {
	Properties {
		_OB("Overbright", Float) = 0
		_DF ("Diffuse map", 2D) = "white" {} 
	
		_Mask ("Mask", 2D) = "white" {}
		_UVspeed ("UV Speed (xy) Size (zw)", Vector) = (1,1,0,0)
		_Fade ("Fade", Range (1,0)) = 1
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
			"RenderType" = "Transparent"
			
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
		
		Fog {Mode Off} // MODE: Off | Global | Linear | Exp | Exp
		
		//- HELP: http://docs.unity3d.com/Manual/SL-Pass.html
		
	    Lighting OFF 	//Turn vertex lighting on or off
	    ZWrite OFF	//Set depth writing mode
	    Cull OFF 		//Back | Front | Off = two sided
		//ZTest Always  //Always = paint always front (Less | Greater | LEqual | GEqual | Equal | NotEqual | Always)
		//AlphaTest 	//(Less | Greater | LEqual | GEqual | Equal | NotEqual | Always) CutoffValue
		
		//ZTest Always
		// END TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
		
		Pass {
		
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag
			#include "UnityCG.cginc"

			//user defined variables
			uniform sampler2D _DF , _Mask;
			uniform half4 _UVspeed;
			uniform half _Fade, _OB;

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
				fixed4 VC : COLOR;
			};

			//vertex function
			vertexOutput vert(vertexInput v)
			{
				vertexOutput o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				float t = fmod(_Time.x, 10.0) * 0.3;
				o.uv0 = v.uv0.xy * _UVspeed.zw + (t * _UVspeed.xy);
				o.uv1 = v.uv1;
				o.VC = v.color;

				return o;
			}

			//fragment function
			fixed4 frag(vertexOutput i) : COLOR
			{
				fixed4 DF = tex2D(_DF, i.uv0);
				fixed4 Mask = tex2D(_Mask, i.uv1);


				//return Mask;
				//return fixed4 ((DF.rgb + Mask.g)* i.VC.rgb ,( DF.a + Mask.b) * i.VC.a * _Fade * Mask.r );
				return fixed4(DF.rgb * i.VC.rgb  , DF.a  * i.VC.a * _Fade * Mask.r);
			}
		ENDCG
      }
	} 
}
 