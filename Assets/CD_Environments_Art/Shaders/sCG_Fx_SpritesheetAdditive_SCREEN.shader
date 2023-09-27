// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "socialPointCG/sCG_Fx_SpritesheetAdditive_SCREEN" {
	Properties {
	_MainTex ("Diffuse map", 2D) = "white" {} 
	[Header(X Columns Y Rows Z Frame W Frame Second)]
	_SpriteData("Spritesheet values",vector) = (0,0,0,0)

	}
	
	SubShader {
		
		
		Tags { 	"Queue"="Transparent" 	"RenderType" = "Transparent"	"LightMode" = "Always" 	}
		
		Blend One One 					
		
		Fog {Mode Off} 
						
	    Lighting OFF   ZWrite OFF	   Cull OFF 		
		
		
		Pass {
		
		CGPROGRAM
		#pragma vertex vert 
		#pragma fragment frag
		#include "UnityCG.cginc"

		
		uniform sampler2D _MainTex;
		uniform float4 _SpriteData;

		
		struct vertexInput {
			float4 vertex : POSITION;
			half2 uv0 : TEXCOORD0;
			fixed4 color : COLOR;
		};

		struct vertexOutput {
			float4 pos : SV_POSITION;
			half2 uv0 : TEXCOORD0;
			fixed4 VC : COLOR;
		};

		
		vertexOutput vert(vertexInput v)
		{
			vertexOutput o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			
			half uValue = v.uv0.x;
			half vValue = v.uv0.y;

			//Calculating Size of Spritesheet
			half CellPixelWidth = 1 / _SpriteData.x;
			half CellPixelHeight = 1 / _SpriteData.y;

			//Current Frame position depending on time and frame postion value
			int FPS = _SpriteData.w;
			int CellPos = ((FPS * _Time.y) + _SpriteData.z) % (_SpriteData.x * _SpriteData.y);


			//Calculating vertical and horizontal positions
			half uIndex = (_SpriteData.y - 1) - int(CellPos / _SpriteData.x);
			half vIndex = ((CellPos / _SpriteData.x) - uIndex) / CellPixelWidth;


			//+ modifies offset, * modifies tiling
			uValue += vIndex;
			uValue *= CellPixelWidth;

			vValue += uIndex;
			vValue *= CellPixelHeight;


			o.uv0 = half2(uValue, vValue);
			
			o.VC = v.color;
			return o;
		}

		
		fixed4 frag(vertexOutput i) : COLOR
		{

			
			
			fixed4 Complete = tex2D(_MainTex, i.uv0);

			fixed inverseVertexColorAlpha = (1.0 - i.VC.a);

			fixed3 CombineColor = fixed3(i.VC.r - inverseVertexColorAlpha, i.VC.g - inverseVertexColorAlpha, i.VC.b - inverseVertexColorAlpha);

			return fixed4(Complete.rgb * CombineColor, Complete.a);
		}

		ENDCG
      }
	} 
}
