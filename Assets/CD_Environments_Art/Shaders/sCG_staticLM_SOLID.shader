// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_staticLM_SOLID" {
                
	//editor exposed properties (uniforms)
	Properties {
		_Overbright ("Overbright", Float) = 0.5 		
		_DF ("DiffuseMap", 2D) = "white" {} 
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
		
//			"LightMode" = "Always" 			// Always rendered; no lighting is applied.
			"LightMode" = "ForwardBase"		// Used in Forward rendering, ambient, main directional light and vertex/SH lights are applied.
//			"LightMode" = "ForwardAdd"		// Used in Forward rendering; additive per-pixel lights are applied, one pass per light.
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
		//ZWrite OFF	//Set depth writing mode
		//Cull OFF 		//Back | Front | Off = two sided
		//ZTest Always  //Always = paint always front (Less | Greater | LEqual | GEqual | Equal | NotEqual | Always)
		//AlphaTest 	//(Less | Greater | LEqual | GEqual | Equal | NotEqual | Always) CutoffValue
	
		// END TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
				
		Pass {

			CGPROGRAM
        
			#include "UnityCG.cginc"	
        
			#pragma vertex vert
			#pragma fragment frag
        
			#pragma multi_compile_fog
            #pragma multi_compile_fwdbase

			//#pragma debug
        		
			#include "AutoLight.cginc"
 			#include "Lighting.cginc"
 
			//global uniforms...
			sampler2D _DF;
			sampler2D _LM;
		
			float _Overbright;

			//vertex attributes...
			struct appdata_fullReal {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
			};
		
			//varyings... (aka from vertex to fragment variables)
			struct v2f { 
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;                        
                UNITY_FOG_COORDS(2)
                LIGHTING_COORDS(3,4)
			};
		
			//vert function...
			v2f vert (appdata_fullReal v)
			{
				v2f OUT;
            
				float4 vPos = UnityObjectToClipPos (v.vertex);
            
				OUT.pos = vPos;
			
				OUT.uv0 = v.texcoord.xy;
				OUT.uv1 = v.texcoord1.xy;
            
				UNITY_TRANSFER_FOG(OUT, OUT.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(OUT);
				return OUT;
			};
		
			//fragment function...
			half4 frag (v2f IN) : COLOR
			{
				//textures...
				half4 DF = tex2D (_DF, IN.uv0);
				half4 LM = tex2D (_LM, IN.uv1);			
    
				half3 Complete = DF.rgb * LM.rgb * _Overbright;

                half shadowFactor = LIGHT_ATTENUATION(IN);
                Complete = lerp(UNITY_LIGHTMODEL_AMBIENT, Complete, smoothstep(0.0, 1.0, shadowFactor + (1.-UNITY_LIGHTMODEL_AMBIENT.a)));
			
				UNITY_APPLY_FOG(IN.fogCoord, Complete);
            
				return float4(Complete.rgb, DF.a);
			};
        
			ENDCG
		}
	}

}
