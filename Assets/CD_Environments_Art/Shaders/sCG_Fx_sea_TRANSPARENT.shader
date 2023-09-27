// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_Fx_sea_TRANSPARENT" {
	Properties {
		_DF ("Diffuse map", 2D) = "white" {}
		_NM ("Normal map", 2D) = "white" {}
		_NDIS ("NDIS map", 2D) = "white" {}
		_CA ("Caustics map", 2D) = "white" {}
		
		_minAlpha ("Minimum Alpha", Float) = 0.1
		_Overbright ("Overbright", Float) = 1
		_uvMultip ("UV multipliers", Vector) = (1,1,1,1)
		_ampX ("Amplitude X", Float) = 1
		_ampY ("Amplitude Y", Float) = 1
		_ReflectionAmount ("ReflectionAmount", Float) = 1.0 
		_ReflectionBend ("ReflectionBend (0.01 to 1.0)", Float) = 0.0
		_DistorsionAmount ("DistorsionAmount", Float) = 0.1
		_CausticsAmount ("CausticsAmount", Float) = 1
		_SSSColor ("Scattering Color", Color) = (1,1,1,1)
	}
	
	SubShader {
		
		// INI TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
		Tags { 	
			//- HELP: http://docs.unity3d.com/Manual/SL-SubshaderTags.html
			
			//"Queue"="Background " 	// this render queue is rendered before any others. It is used for skyboxes and the like.
			//"Queue"="Geometry" 		// (default) - this is used for most objects. Opaque geometry uses this queue.
			//"Queue"="AlphaTest" 		// alpha tested geometry uses this queue.
			"Queue"="Transparent-10" 	// alpha blend pixels here!
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
		#pragma multi_compile_fog

		#include "UnityCG.cginc"

		//user defined variables
		uniform half4 _UVscale;
		uniform half4 _uvMultip;

		uniform half _ampX;
		uniform half _ampY;

		uniform half _ReflectionBend;
		
		uniform sampler2D 	_DF;
		uniform sampler2D 	_NM;
		uniform sampler2D 	_NDIS;
		uniform sampler2D 	_CA;

		uniform fixed  	_ReflectionAmount;
		uniform fixed	_DistorsionAmount;
		uniform fixed	_CausticsAmount;
		uniform fixed4	_SSSColor;
		uniform fixed	_minAlpha;

		//base input structs
		struct vertexInput {
			float4 vertex : POSITION;
			float2 uv0 : TEXCOORD0;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
		};

		struct vertexOutput {
			float4 pos : SV_POSITION;
			float2 uv0 : TEXCOORD0;
			float4 uvNM_A : TEXCOORD1;
			float4 uvNM_B : TEXCOORD2;
			float2 uvNdis : TEXCOORD3;
			float3 vDir : TEXCOORD4;
			UNITY_FOG_COORDS(5)				
		};

		//vertex function
		vertexOutput vert(vertexInput v)
		{
			vertexOutput o;

			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv0 = v.uv0.xy;

			//float t = fmod(_Time.x, 30.0); //Time (t/20, t, t*2, t*3), use to animate things inside the shaders.
			float t1 = _SinTime.x; //Sine of time: (t/8, t/4, t/2, t).
			float t2 = _CosTime.x; //Cosine of time: (t/8, t/4, t/2, t).

			o.uvNM_A.rg = (v.uv0.xy * _uvMultip.x) + float2(_ampX * t1, _ampY * t2);
			o.uvNM_B.rg = (v.uv0.xy * _uvMultip.x * 0.842) + float2(-_ampX * t1, -_ampY * t2);

			o.uvNM_A.ba = (v.uv0.xy * _uvMultip.y * 0.842) + float2(-_ampX * t1, -_ampY * t2);
			o.uvNM_B.ba = (v.uv0.xy * _uvMultip.y) + float2(_ampX * t1, _ampY * t2);

			float3 vView = ObjSpaceViewDir(v.vertex);
			float3 NN = v.normal;
			float3 TT = v.tangent.xyz;
			float3 BB = cross(NN.xyz, TT.xyz) * v.tangent.w;

			o.vDir.x = dot(TT, vView);
			o.vDir.y = dot(BB, vView);
			o.vDir.z = dot(NN, vView);
			o.vDir = normalize(o.vDir);

			float3 NewNorm = normalize(v.normal + vView * _ReflectionBend);
			float3 VSN = mul(UNITY_MATRIX_IT_MV, float4(NewNorm, 0.0)).xyz;
			VSN = normalize(VSN) * 0.5 + 0.5;
			VSN.xy = 1.0 - VSN.xy; //unity texture re-orientation

			o.uvNdis = VSN.xy;

			UNITY_TRANSFER_FOG(o, o.pos);			

			return o;
		}

		//fragment function
		fixed4 frag(vertexOutput i) : COLOR
		{
			//Texture Maps
			fixed4 DF = tex2D(_DF, i.uv0);
			fixed4 NM1 = tex2D(_NM, i.uvNM_A.xy);
			fixed4 NM2 = tex2D(_NM, i.uvNM_B.xy);
			fixed4 NM = NM1 + NM2 * 0.5;
			NM = NM * 2.0 - 1.0;
			NM.g *= -1.0;

			float3 viewDir = normalize(i.vDir);

			half NdotV = max(0.0, dot(viewDir, normalize(NM.rgb)));
			NdotV = NdotV * NdotV;
			NdotV = 1.0 - NdotV;
			NdotV = min(1.0, NdotV + (1.0 - DF.a));
			NdotV = (NdotV * 0.5) + 0.5;
			//NdotV = smoothstep(0.5,1.0,NdotV);

			fixed4 CA1 = tex2D(_CA, i.uvNM_A.zw);
			fixed4 CA2 = tex2D(_CA, i.uvNM_B.zw);
			fixed4 CA = CA1 + CA2 * 0.5;



			float2 refUV = i.uvNdis + (NM.rg * _DistorsionAmount);
			//refUV = normalize(refUV);

			fixed4 NDIS = tex2D(_NDIS, refUV);
			//fixed NDIS_hi = smoothstep(0.75, 1.0, NDIS.r);
			NDIS = NDIS * _ReflectionAmount * DF.a;

			fixed4 Caustics = CA * (1.0 - DF.a) * _CausticsAmount;

			fixed alpha = min(DF.a + _minAlpha, 1.0);
			fixed4 Complete = fixed4(DF.rgb + NDIS.rgb + Caustics.rgb, alpha);
			
			UNITY_APPLY_FOG(i.fogCoord, Complete);

			return Complete;
		}

		ENDCG
      }
	} 
}
