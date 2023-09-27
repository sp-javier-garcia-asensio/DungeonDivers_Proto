Shader "socialPointCG/sCG_staticBlendLM" 
{
	Properties {		
		_UVMultiA("A UV tiling (ch 1)", Float) = 1.0
		[NoScaleOffset] _MainTex ("Diffuse A (ch1)", 2D) = "white" {}		
		[TextureToggle(USE_B)] [NoScaleOffset] _DiffuseB("Diffuse B (ch1) (VC red)", 2D) = "white" {}
			[DependsOnToggle(USE_B)] _UVMultiB("    B UV tiling (ch 1)", Float) = 1.0
		[TextureToggle(USE_C)] [NoScaleOffset] _DiffuseC("Diffuse C (ch3) (VC green)", 2D) = "white" {}
		[TextureToggle(USE_MK)] [NoScaleOffset] _MK("MaskMap (same UV as A)", 2D) = "red" {}
			[DependsOnToggle(USE_MK)] _MixMaskMiddleValue("    Mix mask middle value (blue channel)", Range(0.0, 1.0)) = 0.5
			[DependsOnToggle(USE_MK)] _MixMaskEdgeThreshold("    Mix mask edge threshold", Range(0.0, 1.0)) = 0.1			
		[TextureToggle(USE_LM)] [NoScaleOffset] _LM ("LightMap (ch2)", 2D) = "white" {}		

		_Color("Tint color", Color) = (1,1,1,1)
		_Overbright("Overbright", Float) = 1.0
		[Toggle(USE_FOG)] _UseFog("Use Fog", Float) = 1

		// -- Common Social Point material render state settings -- //		
		[Space]
		[Header(Render State Settings)]		
		[Toggle(ADVANCED_RENDER_STATE)] _AdvancedRenderState("Show advanced options", Float) = 0.0

		// Blend mode values
		[KeywordEnum(Solid, Transparent, Additive, Screen, Multiply, Transparent Double Sided)] _RenderStateBasicTypes("Blend mode", Float) = 0
		[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Blend source", Float) = 1.0
		[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Blend destination", Float) = 0.0
		[Toggle(ALPHA_MULTIPLIES_RGB)] _AlphaMultipliesRGB("Use alpha as RGB factor", Float) = 0

		[Enum(Background,1000, Geometry,2000, AlphaTest,2450, Transparent,3000, Overlay,4000)] _RenderQueueEnum("Render queue", Int) = 2000
		_RenderQueueOffset("Render queue offset", Int) = 0
		
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull mode", Int) = 2

		[Enum(UnityEngine.Rendering.CompareFunction)] _DepthTest("Depth test (default LessEqual)", Int) = 4
		[Toggle] _DepthWrite("Depth write", Float) = 1
	}

	CustomEditor "SPCustomMaterialEditor"

	SubShader {
		
		// INI TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
		Tags { 				
			"LightMode" = "ForwardBase"			// Used in Forward rendering, ambient, main directional light and vertex/SH lights are applied.
			"ShadowSupport" = "True"
			"IgnoreProjector" = "True" 
		}
		
		Blend [_SrcBlend] [_DstBlend]
		
		Fog {Mode Global} // MODE: Off | Global | Linear | Exp | Exp
		
		Cull [_CullMode]
		ZTest [_DepthTest]
		ZWrite[_DepthWrite]
		
		// END TAGS & PROPERTIES ------------------------------------------------------------------------------------------------------------------------------------
		
		
		Pass {
		
		CGPROGRAM
		#pragma vertex vert 
		#pragma fragment frag
		#pragma multi_compile_fog
		#pragma multi_compile_fwdbase
		#pragma skip_variants SPOT POINT_COOKIE DIRECTIONAL_COOKIE

		#pragma shader_feature USE_B
		#pragma shader_feature USE_C
		#pragma shader_feature USE_LM
		#pragma shader_feature USE_MK
		#pragma shader_feature USE_FOG
		#pragma shader_feature ALPHA_MULTIPLIES_RGB

		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
		
		//user defined variables
		uniform sampler2D _MainTex;
		uniform sampler2D _DiffuseB;
		uniform sampler2D _DiffuseC;
		#if USE_MK
			uniform sampler2D _MK;
		#endif
		#if USE_LM
			uniform sampler2D _LM;
		#endif		
		uniform half _UVMultiA;
		uniform half _UVMultiB;
		uniform fixed _MixMaskMiddleValue;
		uniform fixed _MixMaskEdgeThreshold;
		uniform fixed4 _Color;
		uniform half _Overbright;
		

		//base input structs
		struct vertexInput {
			float4 vertex : POSITION;
			half2 uv0 : TEXCOORD0;
			half2 uv1 : TEXCOORD1;
			half2 uv2 : TEXCOORD2;
			fixed4 color : COLOR;
		};

		struct vertexOutput {
			float4 pos : SV_POSITION;
			half2 uvA : TEXCOORD0;
			half2 uvB : TEXCOORD1;
			half2 uv1 : TEXCOORD2; 
			half2 uv2 : TEXCOORD3;
			#if USE_MK
				fixed2 mixMaskRange : TEXCOORD4;
			#endif
			#if USE_FOG
				UNITY_FOG_COORDS(5)
			#endif
			LIGHTING_COORDS(6, 7)
			fixed4 VC : COLOR;
		};

		//vertex function
		vertexOutput vert(vertexInput v)
		{
			vertexOutput o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uvA = v.uv0.xy * _UVMultiA;
			o.uvB = v.uv0.xy * _UVMultiB;
			#if !USE_LM && LIGHTMAP_ON			
				o.uv1 = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			#else
				o.uv1 = v.uv1.xy; 
			#endif
			o.uv2 = v.uv2.xy;
			
			o.VC = v.color;

			#if USE_MK
				o.mixMaskRange.x = max(_MixMaskMiddleValue - (_MixMaskEdgeThreshold * 0.5), 0.0);
				o.mixMaskRange.y = min(_MixMaskMiddleValue + (_MixMaskEdgeThreshold * 0.5), 1.0);
			#endif

			#if USE_FOG
				UNITY_TRANSFER_FOG(o, o.pos);
			#endif

			TRANSFER_VERTEX_TO_FRAGMENT(o);

			return o;
		}

		//fragment function
		fixed4 frag(vertexOutput i) : COLOR
		{
			fixed4 A = tex2D(_MainTex, i.uvA);
			fixed4 B = tex2D(_DiffuseB, i.uvB);
			fixed4 C = tex2D(_DiffuseC, i.uv2);
			#if USE_MK
				fixed4 MK = tex2D(_MK, i.uvA);
			#endif
			fixed4 LM = 1;
			#if USE_LM
				LM = tex2D(_LM, i.uv1);
			#else
				#if LIGHTMAP_ON
					LM = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1);
					LM.rgb = DecodeLightmap(LM);
				#endif				
			#endif

			// ---- Diffuse mix ----
			fixed3 mixedDiffuse = A;
			#if USE_B
				#if USE_MK
					fixed maskR = (1 - MK.b) * i.VC.r + i.VC.r;
					maskR = smoothstep(i.mixMaskRange.x, i.mixMaskRange.y, maskR);
					mixedDiffuse = lerp(A.rgb, B.rgb, maskR);
				#else 
					mixedDiffuse = lerp(A.rgb, B.rgb, i.VC.r);
				#endif
			#endif
			#if USE_C
				#if USE_MK
					fixed maskG = (1 - MK.b) * i.VC.g + i.VC.g;
					maskG = smoothstep(i.mixMaskRange.x, i.mixMaskRange.y, maskG);
					mixedDiffuse = lerp(mixedDiffuse, C, maskG);
				#else 
					mixedDiffuse = lerp(mixedDiffuse, C, i.VC.g);
				#endif
			#endif
			
			// ---- Shadowmap ----
			fixed atten = SHADOW_ATTENUATION(i);
			fixed3 shadow = lerp(UNITY_LIGHTMODEL_AMBIENT.rgb, fixed3(1.0, 1.0, 1.0), atten);
			
			fixed4 Complete = fixed4(mixedDiffuse.rgb * _Color.rgb * shadow.rgb * LM.rgb * _Overbright, A.a * _Color.a);
			
			#if USE_FOG
				UNITY_APPLY_FOG(i.fogCoord, Complete);
			#endif

			#if ALPHA_MULTIPLIES_RGB
				Complete.rgb *= Complete.a;
			#endif

			return Complete;
		}

		ENDCG
      }
	}
	

	Fallback "VertexLit"
}

