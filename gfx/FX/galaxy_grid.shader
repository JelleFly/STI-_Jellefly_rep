Includes = {
	"terra_incognita.fxh"
}

PixelShader =
{
	Samplers = 
	{
		GridTexture = 
		{
			Index = 0;
			MagFilter = "Linear";
			MinFilter = "Linear";
			AddressU = "Wrap";
			AddressV = "Wrap";
		}
		FadeTexture = 
		{
			Index = 1;
			MagFilter = "Linear";
			MinFilter = "Linear";
			AddressU = "Wrap";
			AddressV = "Wrap";
		}
		TerraIncognitaTexture = 
		{
			Index = 2;
			MagFilter = "Linear";
			MinFilter = "Linear";
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
	}
}

VertexStruct VS_INPUT
{
    float2 vPosition  		: POSITION;
	float2 vUV				: TEXCOORD0;
};

VertexStruct VS_OUTPUT
{
    float4 vPosition 	: PDX_POSITION;
	float2 vUV			: TEXCOORD0;
	float4 vPos			: TEXCOORD1;
};

ConstantBuffer( Common, 0, 0 )
{
	float4x4 	ViewProjectionMatrix;
};


VertexShader =
{
	MainCode VertexShader
		ConstantBuffers = { Common }
	[[
		VS_OUTPUT main(const VS_INPUT v )
		{
			VS_OUTPUT Out;
			float4 vPos = float4( v.vPosition.x, -1.5f, v.vPosition.y, 1.0f );	
			vPos.xz *= 4.5f; //Increase size slightly
			
			Out.vPos = vPos;
			Out.vPosition  	= mul( ViewProjectionMatrix, vPos );
			Out.vUV			= v.vUV;
			return Out;
		}
		
	]]
}

PixelShader =
{
	MainCode PixelShader
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{

			float4 vColor = tex2D( GridTexture, v.vUV * 3.5f);
			float4 vGridColor = float4(vec3(vColor.r), 1.0f);

			float4 nebulaTint = float4(0.05f, 0.06f, 0.11f, 1.0f);

			vColor = tex2D( GridTexture, v.vUV * 15.5f);
			float4 vNebulaLargeColor = vec4(vColor.b) * nebulaTint * 5;
			
			vColor = tex2D( GridTexture, v.vUV * 45.5f);
			float4 vNebulaSmallColor = vec4(vColor.g) * nebulaTint * 0.58;



			float4 vFade = tex2D( FadeTexture, v.vUV );

			vGridColor.rgb = lerp( vec3(0.0f), vGridColor.rgb * 0.01f , vFade.a);
			
			vGridColor = ApplyTerraIncognita( vGridColor, v.vPos.xz, 3.95f, TerraIncognitaTexture );
			float vTIMask = saturate(1 - GetTerraIncognitaMask(v.vPos.xz, TerraIncognitaTexture));
			vColor = 2.2f * vGridColor * vTIMask;
			
			// float vTINebulaMask = saturate(pow(vTIMask, 0.75f));
			float vTINebulaMask = smoothstep(0.00f, 0.9f, vTIMask);
			vTINebulaMask = pow(vTINebulaMask, 0.66f);

			float vTINebulaMask2 = pow(smoothstep(0.99f, 0.0f, vTIMask), 7.5);

			float vTINebulaMaskResult = vTINebulaMask * vTINebulaMask2;
			float4 vNebulaColor = pow(lerp(vNebulaSmallColor, vNebulaLargeColor, 0.1f) * 25, 1.5);

			vColor = lerp(vColor, vNebulaColor, vTINebulaMaskResult);
			
			return vColor;
		}
		
	]]
}


DepthStencilState DepthStencilState
{
	DepthEnable = no
}

BlendState BlendState
{
	BlendEnable = yes
	AlphaTest = no
	SourceBlend = "ONE"
	DestBlend = "ONE"
}

RasterizerState RasterizerState
{
	FillMode = "FILL_SOLID";
	CullMode = "CULL_BACK";
	FrontCCW = no
}


Effect GalaxyGrid
{
	VertexShader = "VertexShader";
	PixelShader = "PixelShader";
}
