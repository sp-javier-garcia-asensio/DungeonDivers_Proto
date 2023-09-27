// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_staticLM_blendByDepth_SOLID" {
	Properties{
		_Overbright("Overbright", Float) = 1.0

		_DF_A("Diffuse A", 2D) = "white" {}
		_DF_B("Diffuse B", 2D) = "white" {}
		_MK("Mask (usually from A)", 2D) = "white" {}

		_BlendPoint("Mix value", Float) = 0.5
		_BlendThresh("Edge blend", Float) = 0.1

		_LM("LightMap (ch2)", 2D) = "white" {}
	}

		SubShader{

		// INI TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
		Tags{
			//- HELP: http://docs.unity3d.com/Manual/SL-SubshaderTags.html

			//"Queue"="Background " 	// this render queue is rendered before any others. It is used for skyboxes and the like.
			"Queue" = "Geometry" 		// (default) - this is used for most objects. Opaque geometry uses this queue.
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

		Fog{ Mode Global } // MODE: Off | Global | Linear | Exp | Exp

		//- HELP: http://docs.unity3d.com/Manual/SL-Pass.html

		//Lighting OFF 	//Turn vertex lighting on or off
		//ZWrite OFF	//Set depth writing mode
		//Cull OFF 		//Back | Front | Off = two sided
		//ZTest Always  //Always = paint always front (Less | Greater | LEqual | GEqual | Equal | NotEqual | Always)
		//AlphaTest 	//(Less | Greater | LEqual | GEqual | Equal | NotEqual | Always) CutoffValue

		// END TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------


		Pass{

			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag
			#pragma multi_compile_fog
            #pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

			//user defined variables
			uniform sampler2D 	_DF_A;
			uniform sampler2D 	_DF_B;
			uniform float4 _DF_A_ST;
			uniform float4 _DF_B_ST;
			uniform sampler2D 	_MK;
			uniform sampler2D	_LM;
			uniform half 		_BlendPoint;
			uniform half 		_BlendThresh;
			uniform half 		_Overbright;

			//base input structs
			struct vertexInput {
				float4 vertex : POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				fixed4 color : COLOR;
			};

			struct vertexOutput {
				float4 pos : SV_POSITION;
				half2 uv0 : TEXCOORD0;
				half2 uvA : TEXCOORD1;
				half2 uvB : TEXCOORD2;
				half2 uv1 : TEXCOORD3;
				fixed2 blendRange : TEXCOORD4;
				UNITY_FOG_COORDS(5)
                LIGHTING_COORDS(6,7)
				fixed4 VC : COLOR;
			};

			//vertex function
			vertexOutput vert(vertexInput v)
			{
				vertexOutput OUT;

				float4 vPos = UnityObjectToClipPos(v.vertex);

				OUT.pos = vPos;

				OUT.uvA = TRANSFORM_TEX (v.uv0, _DF_A);
				OUT.uvB = TRANSFORM_TEX (v.uv0, _DF_B);

				OUT.uv0 = v.uv0.xy;
				OUT.uv1 = v.uv1.xy;
				OUT.VC = v.color;

				OUT.blendRange.x = max(_BlendPoint - (_BlendThresh*0.5), 0.0);
				OUT.blendRange.y = min(_BlendPoint + (_BlendThresh*0.5), 1.0);

				UNITY_TRANSFER_FOG(OUT, OUT.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(OUT);
				return OUT; 
			}

			//fragment function
			fixed4 frag(vertexOutput i) : COLOR
			{
				fixed4 DF_A = tex2D(_DF_A, i.uvA);
				fixed4 DF_B = tex2D(_DF_B, i.uvB);
				fixed4 MK = tex2D(_MK, i.uv0);
				fixed4 LM = tex2D(_LM, i.uv1);

				fixed mask = MK.b * i.VC.r + i.VC.r;
				mask = smoothstep(i.blendRange.x, i.blendRange.y, mask);

				fixed3 Complete = lerp(DF_B.rgb, DF_A.rgb, mask) * LM.rgb * _Overbright;

                half shadowFactor = LIGHT_ATTENUATION(i);
                Complete = lerp(UNITY_LIGHTMODEL_AMBIENT, Complete, smoothstep(0.0, 1.0, shadowFactor + (1.-UNITY_LIGHTMODEL_AMBIENT.a)));

				UNITY_APPLY_FOG(i.fogCoord, Complete);

				return fixed4(Complete,1.0);
			}
			ENDCG
		}
	}
}
