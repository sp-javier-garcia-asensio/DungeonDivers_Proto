// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_staticLM_nm_NDIS_SOLID" {
                
	//editor exposed properties (uniforms)
	Properties {
		_Overbright ("Overbright", Float) = 0.5 
		
		_ReflectionAmount ("ReflectionAmount", Float) = 1.0 
		_ReflectionBend ("ReflectionBend", Float) = 0.0
		_BumpAmount ("BumpAmount", Float) = 0.5 
		
		_DF ("DiffuseMap", 2D) = "white" {} 
		_MK ("MaskMap", 2D) = "white" {}
		_NM ("NormalMap", 2D) = "white" {}
		_NDIS ("NdisMap", 2D) = "white" {}
		_LM ("LightMap (ch2)", 2D) = "white" {}
	}
        
SubShader {
	
	// INI TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
	LOD 600	//iphone 5 and higher
	Tags { 
		//- HELP: http://docs.unity3d.com/Manual/SL-SubshaderTags.html
		
		//"Queue"="Background " 	// this render queue is rendered before any others. It is used for skyboxes and the like.
		"Queue"="Geometry" 		// (default) - this is used for most objects. Opaque geometry uses this queue.
		//"Queue"="AlphaTest" 		// alpha tested geometry uses this queue.
		//"Queue"="Transparent" 	// alpha blend pixels here!
		//"Queue"="Overlay" 		// Anything rendered last should go in overlays i.e. lens flares
		
		
		//- HELP: http://docs.unity3d.com/Manual/SL-PassTags.html
		
		//"LightMode" = "Always" 			// Always rendered; no lighting is applied.
		"LightMode" = "ForwardBase"		// Used in Forward rendering, ambient, main directional light and vertex/SH lights are applied.
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
        
        #include "UnityCG.cginc"
        
        #pragma vertex vert
        #pragma fragment frag
        //#pragma debug
        
        //for shadows...
        #pragma multi_compile_fwdadd_fullshadows
        
        #pragma multi_compile_fog
		
		#include "AutoLight.cginc"
 		//#include "Lighting.cginc"
 
		//global uniforms...
        sampler2D _DF;
		sampler2D _MK;
		sampler2D _NM;
		sampler2D _NDIS;
		sampler2D _LM;
		
		float _Overbright;
		float _ReflectionAmount;
		float _ReflectionBend;
		float _BumpAmount;
		
		float4 _shadowColor;
		
		//vertex attributes...
		struct appdata_fullReal {
		    float4 vertex : POSITION;
		    float4 tangent : TANGENT;
		    float3 normal : NORMAL;
		    float4 texcoord : TEXCOORD0;
		    float4 texcoord1 : TEXCOORD1;
		};
		
		//varyings... (aka from vertex to fragment variables)
        struct v2f { 
            float4 pos : SV_POSITION;
            float2 uv0 : TEXCOORD0;
            float2 uv1 : TEXCOORD1;
            float3 TtoV0 : TEXCOORD2;
            float3 TtoV1 : TEXCOORD3;
            float3 VSN : TEXCOORD4;
            LIGHTING_COORDS(5,6)
            UNITY_FOG_COORDS(7)
        };
		
		//vert function...
        v2f vert (appdata_fullReal v)
        {
            v2f OUT;
            
            float4 vPos = UnityObjectToClipPos (v.vertex);
            
            OUT.pos = vPos;
			
            OUT.uv0 = v.texcoord.xy;
            OUT.uv1 = v.texcoord1.xy;
            
            float3 binormal = cross( v.normal.xyz, v.tangent.xyz );

			float3x3 rotation = float3x3(
				v.tangent.xyz, //primera column
				binormal.xyz, //segunda column
				v.normal.xyz  //tercera column
				);

			OUT.TtoV0 = mul(rotation, (UNITY_MATRIX_MV[0]).xyz); //firt ROW
			OUT.TtoV1 = mul(rotation, (UNITY_MATRIX_MV[1]).xyz); //second ROW
            
            //--- NDIS calculation
            float3 F 	= normalize(vPos.xyz);
            F.z = 0.0;
            OUT.VSN = (F * -_ReflectionBend) * 0.5 + 0.5;
            
            TRANSFER_VERTEX_TO_FRAGMENT(OUT);
            UNITY_TRANSFER_FOG(OUT, OUT.pos);
             
            return OUT;
        };
		
		//fragment function...
        half4 frag (v2f IN) : COLOR
        {
            //textures...
            half4 DF = tex2D (_DF, IN.uv0);
            half4 NM = tex2D (_NM, IN.uv0) * 2.0 - 1.0;
            half4 MK = tex2D (_MK, IN.uv0);
            half4 LM = tex2D (_LM, IN.uv1);			

  			LM = min(LM + half4(MK.g ,MK.g, MK.g, 0.0), half4(1.0,1.0,1.0,1.0));
  						
  			//shadowmap...
            float atten = LIGHT_ATTENUATION(IN);
            float4 shadow = lerp(_shadowColor ,half4(1.0,1.0,1.0,1.0), atten);
            
            //ndis...
            //NM = lerp(half4(0.0,0.0,1.0,1.0), NM, _BumpAmount);
            
            float2 vn = float2(0.0,0.0);
            vn.x = dot(IN.TtoV0, NM.rgb);
            vn.y = dot(IN.TtoV1, NM.rgb);
			vn *= _BumpAmount;
            vn = vn + IN.VSN.xy;
            
			float4 NDIS = tex2D(_NDIS, vn);
			NDIS *= MK.r * _ReflectionAmount;
			
			//result...
			half3 Complete = DF.rgb + NDIS.rgb;
			Complete = Complete * LM.rgb * shadow.rgb * _Overbright;
			UNITY_APPLY_FOG(IN.fogCoord, Complete);
			
			float alpha = DF.a;
         	
            return half4(Complete.rgb, alpha);
        };
        
        ENDCG
	}
}


//================================================================================================================================================================
//----------------------------------------------------------------------------------------------------------------------------------------------------------------
//   LOW END DEVICE VERSION:
//----------------------------------------------------------------------------------------------------------------------------------------------------------------
//================================================================================================================================================================


SubShader {
	
	// INI TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
	
	LOD 400	//iphone 4, iphone 4s, and android
	
	Tags 
	{ 
		"Queue"="Geometry" 		// (default) - this is used for most objects. Opaque geometry uses this queue.
		"LightMode" = "ForwardBase"		// Used in Forward rendering, ambient, main directional light and vertex/SH lights are applied.
	}
	
	Fog {Mode Global} // MODE: Off | Global | Linear | Exp | Exp
	
	// END TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
				
	Pass {
        
        CGPROGRAM
        
        #include "UnityCG.cginc"	
        
        #pragma vertex vert
        #pragma fragment frag
        //#pragma debug
        
        //for shadows...
       // #pragma multi_compile_fwdadd_fullshadows
		
		//#include "AutoLight.cginc"
 		//#include "Lighting.cginc"
 
		//global uniforms...
        sampler2D _DF;
		sampler2D _MK;
		sampler2D _LM;
		
		float _Overbright;
		float _BumpAmount;
		
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
        };
		
		//vert function...
        v2f vert (appdata_fullReal v)
        {
            v2f OUT;
            
            float4 vPos = UnityObjectToClipPos (v.vertex);
            
            OUT.pos = vPos;
			
            OUT.uv0 = v.texcoord.xy;
            OUT.uv1 = v.texcoord1.xy;
            
            return OUT;
        };
		
		//fragment function...
        half4 frag (v2f IN) : COLOR
        {
            //textures...
            half4 DF = tex2D (_DF, IN.uv0);
            half4 MK = tex2D (_MK, IN.uv0);
            half4 LM = tex2D (_LM, IN.uv1);			

  			LM = min(LM + half4(MK.g ,MK.g, MK.g, 0.0), half4(1.0,1.0,1.0,1.0));
			
			//result...
			half3 Complete = DF.rgb * LM.rgb * _Overbright;
			
			float alpha = DF.a;
            
            return float4(Complete.rgb, alpha);
            //return float4(1.0,0.5,0.0, alpha);
            
            //return shadow;
        };
        
        ENDCG
	}
}
               
	// if SHADER FAILS... 
	FallBack "Diffuse"
}
